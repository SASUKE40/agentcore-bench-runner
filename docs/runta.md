# 在 Runta 上运行

除了 Amazon Bedrock AgentCore，同一套 Harbor 任务也可以跑在 [Runta](https://runta.com) 的云沙箱上。任务格式、两个 agent 脚本的约定、`summary.json` 的字段都不变，变的只有沙箱：

| | AgentCore（`runner/bench.py`） | Runta（`runner/runta_bench.py`） |
|---|---|---|
| 沙箱 | Harness / Agent Runtime | Runtime |
| 镜像 | 自建并推送到 ECR | `runta image build` 生成私有 Runtime Image |
| 模型凭证 | 执行角色 + Bedrock（IMDSv2） | Runta 托管 model provider，出口代理注入 |
| 示例 agent | Claude Code | Codex CLI |
| 结果回传 | 沙箱内上传 S3 | 客户端 `runta cp` 拉取 |
| 释放沙箱 | 沙箱自己调 `StopRuntimeSession` | 客户端 `runta rm` |

## 控制流的差异

AgentCore 那一侧，客户端 submit 之后就退出，trial 在会话内自治（见 [README 架构](../README.md#架构)），因为会话有 8 小时上限、而且控制面调用有限流。

Runta 这边 `runta exec` 很便宜、Runtime 也没有会话寿命上限，所以客户端直接编排整个 trial：准备任务 → 后台起 `runner/runta/trial.sh` → 轮询 `summary.json` → 拉结果 → 删 Runtime。沙箱内的分段顺序没变，仍然是 agent 前台跑完才取测试、才判分，`summary.json` 最后写入作为完成标记。

## 前置条件

只要本机有 `runta` CLI 并且登录过，不需要 AWS 凭证、不需要 Docker、不需要 `config.json`。

```bash
brew install runta-dev/tap/runta     # 或 npm install -g @runta/runta-cli
runta login
runta model-provider ls              # 至少要有一个可用的 model provider
```

## 用法

```bash
# 1. 构建镜像（每个任务一次，约 4 分钟，之后所有 trial 复用）
python runner/runta_bench.py build tasks/fix-git

# 2. 跑评测（构建、创建沙箱、判分、拉结果、删沙箱，一条命令做完）
python runner/runta_bench.py run tasks/fix-git

# 批量：三个任务并行，结果写到 out-runta/
python runner/runta_bench.py run tasks/* --jobs 3 --out out-runta

# 换模型 / 换 provider（默认用 provider 自己的 default_model）
python runner/runta_bench.py run tasks/fix-git --provider XAI
python runner/runta_bench.py run tasks/fix-git --model gpt-5.3-codex

# 删掉本工具创建的 Runtime（加 --images 连镜像一起删）
python runner/runta_bench.py cleanup
```

结果目录 `out-runta/<task>/<run-id>/` 的内容与 AgentCore 模式的 S3 布局一致：`agent.log`、`verifier.log`、`reward.txt`、`ctrf.json`、`trial.log`、`summary.json`，另外保留了这次 trial 实际使用的 `env` 与三个脚本，便于复现。

`out-runta/` 下另有两个整批级别的文件：

| 文件 | 内容 |
|---|---|
| `results.jsonl` | 每个任务一行 `summary.json`（每次 `run` 覆盖写） |
| `job.log` | 客户端侧的作业日志：镜像复用、冷启动、各阶段、耗时、汇总表，带时间戳（追加写，保留历史） |

沙箱内的 `agent.log` / `verifier.log` / `trial.log` 记的是 trial 自己；`job.log` 记的是客户端做了什么，`--jobs` 并行时多个任务的行会交错，各行都带 `[task]` 前缀。

## 模型凭证不进沙箱

沙箱里只有一个占位符 `runta-secret-stub`，真正的 key 由 Runta 的出口代理在请求离开沙箱时替换：

```bash
runta secret rule set <runtime> --secret <provider-secret-id> \
    --host api.openai.com --path '*' --header Authorization --template 'Bearer ${secret}'
```

`runta_bench.py` 会从 `runta model-provider ls` 里取 `secret_id`、`base_url`、`header_name`、`value_template` 自动建这条规则，所以 agent 进程、agent 写的代码、以及 `agent.log` 里都不会出现真实凭证。`runner/runta/agent.sh` 据此给 Codex 写一份 `~/.codex/config.toml`，`base_url` 和 `wire_api` 都来自 provider（`openai_responses` → `responses`，`openai_chat` → `chat`）。

## 镜像：`runta image build` 不上传 build context

`runta image build` 只把 Dockerfile 本身发给构建器，不打包它所在的目录。所以任务的 `environment/Dockerfile` 里只要有 `COPY` 或 `ADD`，直接构建就会失败（`build_executor_failed`）。

因此默认不用 `environment/Dockerfile`，而是用 `task.toml` 里 `[environment].docker_image` 的已发布镜像，生成一行 `FROM <docker_image>` 来构建 —— 和 AgentCore 的 Runtime Instances 模式（`scripts/build_instances.sh`）取同一个镜像，环境是一致的。

`--from-dockerfile` 可以强制走 `environment/Dockerfile`；这条路只适用于没有 `COPY` / `ADD` 的任务，否则 `runta_bench.py` 会先报错而不是等构建失败。

## 实测

三个示例任务，agent 为 Codex CLI + `gpt-5.5`（OpenAI API provider），`--jobs 3`：

| 任务 | reward | 测试 | 冷启动 | agent | verifier |
|---|---|---|---|---|---|
| fix-git | 1 | 2/2 | 37 s | 48 s | 6 s |
| log-summary-date-ranges | 1 | 2/2 | 39 s | 19 s | 6 s |
| openssl-selfsigned-cert | 1 | 6/6 | 17 s | 19 s | 6 s |

- 镜像构建（每个任务一次）约 240–265 s。
- Runtime 冷启动 17–39 s，装 Node + Codex CLI 8–9 s。
- 三个任务并行，整批 126 s。

两点和 AgentCore 不同、值得记一下：

- **沙箱内是 root 且有完整权限**，任务自带的 `tests/test.sh` 里那种 `apt-get install -y curl` 可以直接跑通；Runtime Instances 模式下容器没有 Linux capabilities，才需要 `runner/install.sh` 里给 apt 打补丁。
- **出口默认全开**（`denylist` 且无条目），所以 `test.sh` 下载 uv、agent 装包都不用额外配置。要收紧用 `runta egress set <runtime> --mode allowlist --allow ...`。

## 更换 agent

和 AgentCore 一侧完全相同的两个脚本约定，只是放在 `runner/runta/`：

| 文件 | 约定 |
|---|---|
| `runner/runta/install.sh` | 在沙箱内安装 agent，成功时退出码为 0 |
| `runner/runta/agent.sh` | 读取 `/bench/instruction.md`，**前台**运行 agent，返回 agent 的退出码 |

`runner/runta/trial.sh` 与 agent 无关。模型、provider base URL、工作目录、超时都通过 `/bench/env` 传入。
