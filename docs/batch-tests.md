# 批量测试：Terminal-Bench 2.0 全量任务

目的：用同一套脚本、同一个模板，一次性跑完 Terminal-Bench 2.0 的全部 89 个任务，验证设计在两种模式下是否稳定。任务文件原样使用，不按任务调整任何参数。

- 任务：Terminal-Bench 2.0，89 个 Harbor 任务
- Agent：Claude Code（示例）+ Bedrock Claude Sonnet
- microVM：us-east-2，arm64 镜像由各任务的 `environment/` 原样构建
- Instances：us-east-1，capacity provider 为 c7i.xlarge（4 vCPU / 8 GiB），`rootVolume.freeSpaceGiB = 20`，`idleInstanceTimeout = 28800`；镜像为任务 `docker_image` 加通用模板
- 并发：每种模式同时 10 个 trial（`batch.py --jobs 10`）

## 1. 测试流程

```bash
# 1) 构建：同一个循环处理所有任务，构建失败的记录后跳过
scripts/build_all.sh microvm   <registry-us-east-2> tasks/*     # 在 arm64 机器上
scripts/build_all.sh instances <registry-us-east-1> tasks/*     # 在 x86_64 机器上

# 2) 运行：提交全部任务，最多 10 个同时在跑，结果从 S3 汇总
python runner/batch.py --mode microvm   --image '<registry>/bench/{task}:arm64'     --jobs 10 --out out-microvm   tasks/*
python runner/batch.py --config config.instances.json --mode instances \
                       --image '<registry>/bench/{task}:instances' --jobs 10 --out out-instances tasks/*
```

`batch.py` 只调用 `bench.py submit` 和读取 S3 结果。每个任务最后会是以下状态之一，然后整批继续：

| 状态 | 含义 |
|---|---|
| `done` | `summary.json` 已写出，reward 为 1 或 0 |
| `submit-failed` | 提交阶段失败：镜像不存在、镜像超过 `max_image_mb`、安装 agent 失败、API 报错 |
| `lost` | `status.json` 的心跳（每 300 s 一次）超过 900 s 没有更新 |

分类脚本扫描非 reward 1 的 trial 日志，按错误特征分类：端口占用、只读文件系统、磁盘满、缺少 capability、OOM、架构不符等。

## 2. 每一步的结果

### 2.1 构建

| | microVM（arm64） | Instances（原镜像 + 模板） |
|---|---|---|
| 成功 | 87 / 89 | 87 / 89 |
| 失败 | `qemu-alpine-ssh`、`qemu-startup`：Dockerfile 里的 Debian 软件源已失效，任务本身构建不出来 | 同左两个任务：模板层的 apt 装包同样访问失效的软件源 |
| 压缩后大小 | 中位数 146 MB；超过 3 GB 的 2 个（`mteb-*`，约 7 GB） | 中位数 155 MB；超过 2 GB 的 4 个，全部也超过 3 GB（`mteb-*` 约 8.8 GB，`hf-model-inference`、`pytorch-model-recovery` 约 6.1 GB） |

### 2.2 第一轮运行：暴露的问题

第一轮在初版代码上运行。microVM 54 / 87 得 reward 1。Instances 跑到 84 / 87 时停止，47 个得 reward 1，另有 10 个以上 lost。逐个排查后，**全部按通用方式修复**，没有按任务打补丁：

| 现象 | 根因 | 修复 |
|---|---|---|
| Instances 约 15 分钟后大量 lost | capacity provider 的 `idleInstanceTimeout = 900` 按"实例上没有调用"计时。trial 期间客户端不发调用，实例被 Auto Scaling 回收（CloudTrail 中有 `TerminateInstances`） | 改用 `idleInstanceTimeout = 28800` 的 capacity provider；`bench.py` 在该值小于 trial 超时时拒绝提交 |
| 部分镜像安装 agent 时退出码 127，无输出 | 镜像带有 Debian 的 `nodejs`，但没有 `npm` | `install.sh` 总是使用自己的 Node（`/opt/bench-node`），不使用镜像里的 |
| microVM 镜像里没有 curl、wget、python3，无法下载 Node | 最小镜像 | microVM 构建也套用模板的 `tools` 阶段（静态 busybox，可选 curl），不改 ENTRYPOINT |
| microVM 磁盘写满后 `summary.json` 写不出 | 写满后根文件系统变为**只读**（EROFS），而不只是 `Input/output error` | `trial.sh` 改为把状态和摘要写到 `/dev/shm` 再上传 |
| Instances 判分脚本 `apt-get install` 失败 | 没有 capability 时 dpkg 无法解包（见 [limitations.md](limitations.md)） | `build_all.sh` 从 `tests/test.sh` 中提取 `apt-get install` 的包名，构建时预装；模板再加一条 apt pin，防止判分时升级已装的包 |
| trial 死掉后客户端一直等 | 没有存活信号 | `trial.sh` 每 300 s 写一次心跳，`batch.py` 超过 900 s 无心跳即判为 lost |
| 10 个并发提交时报 `ThrottlingException`（`ListAgentRuntimes`） | 控制面 list API 按账户限流 | 控制面客户端改用 adaptive 重试（最多 12 次） |

### 2.3 第二轮运行（修复后的代码，全量）

| 结果 | microVM（87 个可运行） | Instances（89 个） |
|---|---|---|
| **reward 1** | **49** | **52** |
| reward 0：agent 解题失败 | 23 | 20 |
| reward 0：agent 超时 | 5 | 6 |
| 环境问题：端口 8080 已被占用 | 4 | 0 条日志命中；但 8080 同样被占用（见汇总），`nginx-request-logging` reward 0、`configure-git-webserver` 超时 |
| 环境问题：没有 capability | -- | 3（`git-multibranch` 判分装 openssh 时 chgrp 失败；`path-tracing*` 需要 `chroot`） |
| 环境问题：磁盘写满，根文件系统变只读 | 2（`pytorch-model-cli`、`sam-cell-seg`） | 0 |
| 镜像超过上限（提交时拒绝） | 2 | 4 |
| 镜像解压后放不下（静默失败） | 1（`custom-memory-heap-crash`） | 0 |
| lost（原因未查明） | 1（`rstan-to-pystan`） | 2（`compile-compcert`、`pytorch-model-cli`） |
| 构建失败（无镜像） | 另计 2 | 2 |

- 两种模式都得 reward 1 的任务 41 个，至少一种模式得 reward 1 的 60 个。
- **沙箱释放**：两轮所有结果目录中都没有 `stop-error.log`，每个 trial 都由 `trial.sh` 停止了自己的会话。
- **沙箱复用**：microVM 84 个 trial 复用了已有沙箱，准备沙箱中位数 1.5 s；Instances 首次创建中位数 18.5 s。安装 agent 中位数：microVM 12.9 s，Instances 49.7 s。
- **结果波动**：同样的代码，microVM 两轮之间有 24 个任务结果不同，大多是 reward 在 1 和 0 之间变化。单次运行的得分只能作为参考，比较时应多跑几次。

### 2.4 microVM 解压后大小的补充测试

`custom-memory-heap-crash` 的 arm64 镜像压缩后 1.18 GB、解压后 4.14 GB，在 microVM 上连 `df` 都没有输出。为了找到边界，用 ubuntu:24.04 加全零文件构建了三个镜像，在新会话中执行 `df` 和写文件：

| 镜像解压后 | 会话 | 根文件系统可用 |
|---|---|---|
| 3.32 GB | 正常 | 1,996 MiB |
| 4.4 GB | 正常 | 972 MiB |
| 5.47 GB | 能执行命令 | **0 MiB**（100%） |

结论：
- 根文件系统总共约 8,972 MiB，镜像解压后超过约 4.4 GB 时，已经没有空间安装 agent（Node + Claude Code 约 400 MB）。
- `custom-memory-heap-crash`（4.14 GB）在更小的尺寸上就失败了，和纯大小不符。**原因还没有查明**，可能与镜像的层数或文件数有关，这里只记录现象。
- 实际运行时，建议把 microVM 镜像解压后的大小控制在 **4 GB 以内**，超过的改用 Instances。

每个任务的完整记录（reward、分类、耗时、可写空间、错误）：[第一轮 microVM](results/round1-microvm.md) · [第一轮 Instances](results/round1-instances.md) · [第二轮 microVM](results/round2-microvm.md) · [第二轮 Instances](results/round2-instances.md)。

## 3. 汇总

- **设计是稳定的**：89 个任务用同一套脚本和模板跑完，没有为任何任务单独改参数。每个 trial 都自己写出结果并释放沙箱，客户端中途不需要交互。
- **通过率**：microVM 49 / 87，Instances 52 / 89。未通过的大部分是 agent 解题失败或超时，属于模型和 agent 的能力，不是运行环境的问题。
- **环境导致失败的共 12 个 trial（两种模式合计）**，都有明确归类：

| 问题 | 影响的模式 | 处理 |
|---|---|---|
| 端口 8080 被占用 | 两种都有：microVM 是运行时自带的服务（uvicorn），Instances 是运行时要求的健康检查端点（模板的 `entry.sh`） | 需要监听 8080 的任务目前无法原样运行 |
| 缺少 Linux capability（chroot、chgrp、dpkg） | Instances | 需要这些操作的任务改用 microVM |
| 可写空间不够，根文件系统变只读 | microVM | 改用 Instances，调大根卷 |
| 镜像超过上限 | 两种都有 | 拆分构建，见 [large-images.md](large-images.md) |
| 镜像解压后过大 | microVM | 控制在 4 GB 以内，否则改用 Instances |
| lost（原因未查明） | 两种都有，共 3 个 | 由心跳判定并记录；重跑该任务 |

- **两种模式互补**：把每个任务放在适合它的模式上运行，至少一种模式得 reward 1 的任务有 60 个，多于任何单一模式。
