# 测试计划与结果

## 方法

- 任务：[Terminal-Bench 2.0](https://github.com/laude-institute/terminal-bench-2)（Harbor 格式）中的三个任务，文件原样复制到 `tasks/`。
- 判分：**任务自带的 `tests/test.sh` 是唯一裁判**，它写出的 `/logs/verifier/reward.txt` 即结果（1 = 通过）。判定逻辑不做修改。
- 流程：每个 trial 由 `bench.py submit` 发起，客户端随即退出；agent、判分、上传、释放都在 AgentCore 会话内由 `trial.sh` 完成；结果用 `bench.py results` 从 S3 读取。
- 两种模式使用同一套配置：

| 项 | 值 |
|---|---|
| Agent（示例，可替换） | Claude Code，会话内 npm 安装 |
| 模型 | Claude Sonnet，Bedrock 跨区域推理配置 `us.anthropic.claude-sonnet-5` |
| 调用方式 | `claude -p "<instruction.md>" --permission-mode bypassPermissions`，root + `IS_SANDBOX=1` |
| 凭证 | AgentCore 执行角色（IMDSv2），不注入任何密钥 |

| 任务 | 检验点 | 原始镜像 |
|---|---|---|
| `fix-git` | 在 git 仓库里找回丢失的提交并合并 | `alexgshaw/fix-git:20251031` |
| `log-summary-date-ranges` | 按日期区间统计日志并输出 CSV | `alexgshaw/log-summary-date-ranges:20251031` |
| `openssl-selfsigned-cert` | 生成自签名证书并写 Python 校验脚本 | `alexgshaw/openssl-selfsigned-cert:20251031` |

## 结果

### microVM 模式（us-east-2，`environment/` 原样构建 arm64）

| 任务 | reward | agent | 判分 | trial 总时长 |
|---|---|---|---|---|
| fix-git | **1** | 38 s | 4 s | 44 s |
| log-summary-date-ranges | **1** | 23 s | 5 s | 28 s |
| openssl-selfsigned-cert | **1** | 39 s | 5 s | 46 s |

### Runtime Instances 模式（us-east-1，原始 amd64 镜像 + `adapter/`，c7i.xlarge）

| 任务 | reward | agent | 判分 | trial 总时长 |
|---|---|---|---|---|
| fix-git | **1** | 54 s | 3 s | 59 s |
| log-summary-date-ranges | **1** | 26 s | 3 s | 31 s |
| openssl-selfsigned-cert | 0 | 40 s | 3 s | 43 s |

`openssl-selfsigned-cert` 在 Instances 模式下跑了两次，都是 6 个用例通过 5 个。失败的用例用 `python /app/check_cert.py` 运行 agent 写的校验脚本；两次 agent 都选择了 `cryptography` 库，而判分时的 Python 环境（`uvx` 创建的临时环境）里没有这个包。microVM 模式那次通过了该用例（agent 的总结未提到 `cryptography`，推测用了标准库）。失败原因在 agent 选择的解法与判分环境不匹配，没有出现运行环境错误。

trial 总时长不含沙箱准备和 agent 安装（在 submit 阶段完成，耗时记录在 `submitted.json` 的 `timings_s`）。

### 回归（复用已有沙箱）

代码最终版本上再跑一轮，确认复用路径：

| 任务 | 模式 | 沙箱复用 | 准备沙箱 | 安装 agent | reward | trial 总时长 |
|---|---|---|---|---|---|---|
| fix-git | microVM | 是 | 0.9 s | 11.8 s | **1** | 37 s |
| log-summary-date-ranges | Instances | 是 | 1.6 s | 49.4 s | **1** | 25 s |

### 共同检查

| # | 检查项 | 结果 |
|---|---|---|
| C1 | submit 返回后客户端不再与沙箱交互 | 通过：所有 trial 在客户端退出后独立完成 |
| C2 | 结果目录完整 | 通过：每个 trial 都有 `summary.json`、`reward.txt`、`ctrf.json`、`agent.log`、`verifier.log` |
| C3 | 沙箱自行释放 | 通过：`trial.sh` 结束时调用 `StopRuntimeSession`，未出现 `stop-error.log` |
| C4 | 同镜像复用沙箱 | 通过：再次提交同一镜像时直接复用已有 Harness / Agent Runtime，`submitted.json` 中 `sandbox_reused: true`，准备沙箱耗时 microVM 0.9 s、Instances 1.6 s |
| C5 | 空闲超时行为 | 实测：空闲超时 60 s 时后台进程被回收；900 s 时正常完成（见 [limitations](limitations.md#会话与空闲超时)） |

## 复现

```bash
scripts/build_microvm.sh tasks/fix-git <ecr-us-east-2>/bench/fix-git
python runner/bench.py submit --mode microvm --task tasks/fix-git --image <ecr-us-east-2>/bench/fix-git:arm64

scripts/build_instances.sh alexgshaw/fix-git:20251031 <ecr-us-east-1>/bench/fix-git
python runner/bench.py --config config.instances.json submit --mode instances \
    --task tasks/fix-git --image <ecr-us-east-1>/bench/fix-git:instances

python runner/bench.py results <run-id> --wait 1800
```

## 镜像大小与存储

单独记录在 [size-and-storage-tests.md](size-and-storage-tests.md)：镜像大小上限、解压后大小、可写空间、磁盘写满、拆分构建的实测过程和结果。

## 全量批量测试

Terminal-Bench 2.0 的全部 89 个任务，用同一套脚本批量运行（`scripts/build_all.sh` + `runner/batch.py`），不按任务调整参数：

| | microVM | Instances |
|---|---|---|
| 可运行 / 总数 | 87 / 89 | 89 / 89（构建失败 2 个，另计） |
| reward 1 | 49 | 52 |
| 环境导致失败 | 10（端口占用、只读 rootfs、镜像过大、lost） | 11（capability、镜像过大、lost、无镜像） |
| 未自行释放的沙箱 | 0 | 0 |

测试流程、每一步的结果和问题分类见 [batch-tests.md](batch-tests.md)。
