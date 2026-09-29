# 镜像大小与存储测试

- 日期：2026-09-28
- 账号 / 区域：microVM 在 us-east-2，Runtime Instances 在 us-east-1（capacity provider：c7i.xlarge，`rootVolume.freeSpaceGiB` = 20，无额外 EBS 卷）
- 代码：本仓库当前版本（`bench.py` / `trial.sh`），沙箱与会话的创建方式和正式 trial 相同
- 镜像大小一律取 ECR 报告的 `imageSizeInBytes`（压缩后，十进制字节）

## 1. 测试流程

| 编号 | 测什么 | 做法 |
|---|---|---|
| A | 压缩后镜像大小的上限 | 在一个小镜像上叠加随机数据层（不可压缩），得到 1.84 / 2.67 / 2.88 / 3.09 / 3.51 GB 的镜像，逐个创建沙箱并在新会话里执行一条命令 |
| B | 真实的大镜像 | 取 Terminal-Bench-Science 中两个大镜像（`animal-reid` 2.79 GB、`gen-turan-paths` 3.91 GB），套模板后创建 Instances 沙箱 |
| C | 解压后大小 | 叠加一个 7 GiB 全零文件：压缩后只有 0.16 GB，解压后多 7 GiB。两种模式各创建沙箱并执行命令 |
| D | 可写空间和写满时的行为 | 新会话里每次写 1 GiB 直到失败；记录能写多少、写满时报什么错、写满时小文件和命令是否还能用、删除后空间何时回收 |
| E | 完整 trial：任务产出过大 | 合成任务 `big-output-8g`：要求 agent 写一个 8 GiB 的非稀疏文件，判分检查文件大小 |
| F | 完整 trial：任务把磁盘写满 | 合成任务 `disk-full-after-verify`：判分脚本写完 reward 后把磁盘写满，检查结果能否上传、会话能否自行停止 |
| G | 拆分构建（大镜像的解决办法） | 用 `scripts/build_split.sh` 处理 3.91 GB 的 `gen-turan-paths`，在 Instances 上跑完整 trial，核对恢复后的环境 |
| H | 回归 | 修改代码后，`fix-git` 在两种模式各跑一次 |

合成任务 E、F 使用 `fix-git` 的镜像；E、F、G 的任务定义只用于本次测试，不在本仓库的 `tasks/` 中。

## 2. 每一步的结果

### A. 压缩后镜像大小

microVM（Harness）：

| 镜像大小 | CreateHarness | 到 READY | 新会话第一条命令 | 根文件系统剩余可写 |
|---|---|---|---|---|
| 1.84 GB | 接受 | 154 s | 正常，12.8 s | 3,234 MiB |
| 2.67 GB | 接受 | 154 s | 正常，15.2 s | 2,434 MiB |
| 2.88 GB | 接受 | 154 s | 正常，19.8 s | 2,234 MiB |
| 3.09 GB | 接受 | 154 s | **无输出**：HTTP 200，事件流为空，没有退出码，16.6 s 后结束 | - |
| 3.51 GB | 接受 | 154 s | **无输出**，同上；换 3 个新会话重试，结果相同（16.9 / 25.2 / 15.7 s） | - |

- Harness 在创建时不检查镜像大小，超限的镜像也会变成 READY。失败发生在会话启动时，**不返回任何错误**，对应的 CloudWatch 日志组里也没有日志。
- 本账号 microVM 的实际上限在 2.88 GB 和 3.09 GB 之间，与 3 GB 一致。
- 镜像内容和可写空间共用同一块约 8.8 GiB 的根文件系统。镜像每多 1 GiB，可写空间少 1 GiB（见右列）。

Runtime Instances：

| 镜像大小 | CreateAgentRuntime | 到 READY | 新会话第一条命令 |
|---|---|---|---|
| 1.84 GB | 接受 | 12 s | 正常，53.6 s（含实例启动） |
| 2.68 GB | **拒绝**：`ServiceQuotaExceededException: maxImageSizeMb limit exceeded for account <account-id>` | - | - |
| 3.52 GB | **拒绝**，同上 | - | - |

- Instances 在创建时就检查，报错信息明确。本账号 Instances 的配额是默认的 2 GB，与 microVM 不同。

### B. 真实大镜像（Instances）

| 镜像 | 套模板后大小 | 结果 |
|---|---|---|
| `life-sciences/ecology/animal-reid` | 2.79 GB | CreateAgentRuntime 拒绝，`maxImageSizeMb limit exceeded` |
| `mathematical-sciences/formal-mathematics/gen-turan-paths` | 3.91 GB | CreateAgentRuntime 拒绝，同上；`bench.py submit` 在创建沙箱前拒绝（1.5 s，见下文改动） |

Terminal-Bench-Science 的 70 个镜像中（amd64 构建），6 个超过 2 GiB，4 个超过 3 GiB，最大 3.67 GiB。超过 3 GiB 的 4 个都是 Lean 形式化数学任务，解压后约 10 GB。

### C. 解压后大小

镜像压缩后 0.16 GB，解压后比基础镜像多 7 GiB：

| 模式 | 创建 | 新会话第一条命令 |
|---|---|---|
| microVM | 接受，154 s 到 READY | **无输出**，与 A 中超限镜像的现象相同 |
| Instances | 接受，12 s 到 READY | 正常；根文件系统剩余 12,853 MiB（基础镜像时约 20,000 MiB） |

- microVM 的镜像解压后必须放得进约 8.8 GiB 的根文件系统。**压缩后不超限不等于能运行**，压缩率高的镜像（Python 环境、模型、编译缓存）要同时看解压后大小。
- Instances 的根卷总大小不随镜像变化（均为 28,596 MiB）。`freeSpaceGiB = 20` 时，镜像解压后越大，任务可写的空间越少。

### D. 可写空间与写满时的行为

| 项 | microVM | Instances |
|---|---|---|
| 根文件系统 | overlay，共 8,972 MiB，可用 4,835 MiB | overlay，共 28,596 MiB，可用约 20,000 MiB |
| vCPU | 2 | 4 |
| `/dev/shm` | tmpfs，64 MiB（写 512 MiB 失败） | tmpfs，64 MiB（写 512 MiB 失败） |
| 写满前写入 | 5,121 MiB，6 s | 20,317 MiB，20 s |
| 写满时的错误 | **`Input/output error`**（`dd ... fsync failed`），不是 `No space left on device` | `No space left on device` |
| 写满时写小文件、执行命令 | 正常 | 正常 |
| 删除后空间回收 | 立即 | 异步，约 10 s（删除后立即看只回收了 2 GiB，10 s 后全部回收） |
| 同一沙箱的下一个会话 | 干净（写满只影响当前会话） | 干净，新会话可用 19,929 MiB |

### E. 完整 trial：任务产出 8 GiB

| 模式 | reward | 过程 |
|---|---|---|
| microVM | 0 | agent 先检查空间，发现只剩约 4.2 GiB，没有写文件，结束时反问用户如何处理；共 15 s |
| Instances | 1 | 写入 8 GiB 后判分通过；共 94 s |

`storage_mb` 大于 microVM 可写空间的任务在 microVM 上必然失败，并且失败看起来像 agent 放弃，不会报环境错误。

### F. 完整 trial：任务把磁盘写满

修改前（`trial.sh` 不预留空间）：

| 模式 | S3 上的结果 | 会话 |
|---|---|---|
| microVM | `summary.json` 为 **0 字节**，`trial.log` / `verifier.log` 为 0 字节；`bench.py results` 解析时崩溃（`JSONDecodeError`） | 已自行停止 |
| Instances | **没有 `summary.json`**，`status.json` 停在 `uploading`，客户端永远等不到完成 | **仍在运行**，手动调用 StopRuntimeSession 才停止；否则会占用实例直到 8 小时空闲超时 |

改动（已提交）：

- `trial.sh` 开始时预留 64 MiB 文件，`finish()` 第一步删除它，保证写满后仍能写出结果并停止会话。
- `bench.py results` 遇到无法解析的 `summary.json` 时返回错误信息，不再崩溃。

修改后：

| 模式 | reward | `summary.json` | 会话 |
|---|---|---|---|
| microVM | 1 | 331 字节，内容完整 | 已自行停止 |
| Instances | 1 | 334 字节，内容完整 | 已自行停止 |

仍然存在：磁盘写满期间写的日志（`verifier.log`、`trial.log`）为空。

### G. 拆分构建：`gen-turan-paths`（3.91 GB）

镜像里体积最大的两个目录：`/root/project`（Lean 项目和 Mathlib 编译缓存，7.5 GiB）和 `/root/.elan`（Lean 工具链，2.7 GiB）。

```bash
scripts/build_split.sh <ecr>/tbs/...gen-turan-paths:latest <ecr>/bench/gen-turan-paths \
  s3://<bucket>/bench-runner/images/gen-turan-paths /root/project /root/.elan
```

| 步骤 | 结果 |
|---|---|
| 打包上传 `/root/project` | `root_project.tar.gz`，2.70 GB |
| 打包上传 `/root/.elan` | `root_.elan.tar.gz`，0.75 GB |
| 瘦身镜像（含模板） | **0.48 GB**（原 3.91 GB） |
| 构建总耗时（开发机，单线程 gzip） | 653 s |
| 创建 Instances 沙箱 | 接受，12.7 s |
| 安装 agent | 59.7 s |
| 恢复两个目录（S3 在 us-east-2，实例在 us-east-1） | 79 s |
| agent 执行 `lean --version` | 8 s，版本号正确（`PATH`、`ELAN_HOME` 保留） |
| 判分：核对文件并执行 `lake build` | 11 s；reward 1 |

恢复后与原镜像逐项对比：

| 项 | 原镜像 | 恢复后 |
|---|---|---|
| `/root/project` 文件数 / 字节数 | 120,145 / 7,590,393,944 | 120,145 / 7,590,393,944 |
| `/root/.elan` 文件数 / 字节数 | 13,914 / 2,843,358,839 | 13,914 / 2,843,358,839 |
| `lake build` | `Build completed successfully (8478 jobs)`，本地 19 s | 相同输出，10 s（编译缓存有效，没有重新编译 Mathlib） |

这个任务原本使用 Harbor 的独立判分模式，本工具尚不支持，所以这里用的是自写的校验任务，没有运行官方测试。

### H. 回归

| 任务 | 模式 | reward | trial 总时长 |
|---|---|---|---|
| fix-git | microVM | 1 | 65 s |
| fix-git | Instances | 1 | 63 s |

## 3. 结果汇总

| 问题 | microVM | Instances |
|---|---|---|
| 镜像压缩后超限 | 创建成功，会话**静默失败**（无输出、无错误、无日志）。本账号上限约 3 GB | 创建时直接拒绝，`maxImageSizeMb`。本账号上限 2 GB（默认值） |
| 镜像解压后过大 | 放不进约 8.8 GiB 根文件系统时同样静默失败；镜像每多 1 GiB，可写空间少 1 GiB | 可以运行，但占用根卷可写空间 |
| 可写空间 | 约 4.7 GiB（减去镜像超出基础镜像的部分） | 由 capacity provider 决定，本次约 20 GiB |
| 磁盘写满 | 报 `Input/output error` | 报 `No space left on device` |
| 任务写满磁盘时 trial 能否收尾 | 修改前结果文件为空；修改后正常 | 修改前没有结果且会话不停止；修改后正常 |
| `/dev/shm` | 64 MiB | 64 MiB |
| 超过上限的镜像 | 不适合（可写空间太小） | 拆分构建后可运行，环境与原镜像一致（G） |

本次测试带来的代码改动：

- `trial.sh`：预留 64 MiB，磁盘写满时仍能写出结果并停止会话；支持拆分构建镜像的恢复步骤（`/etc/bench/restore.list`），恢复耗时记录在 `summary.json` 的 `timings_s.restore`。
- `bench.py`：提交前从 ECR 读取镜像大小，超过配置的 `max_image_mb` 直接拒绝；会话无输出时给出明确原因；`summary.json` 损坏时不崩溃。`submitted.json` 记录 `image_bytes`。
- 新增 `scripts/build_split.sh`；`aws.mjs get` 改为流式下载并支持 `s3://` 地址。
- IAM 示例：调用方增加 `ecr:DescribeImages`；执行角色可读 `<prefix>/images/*`。

大镜像的处理方案见 [large-images.md](large-images.md)。
