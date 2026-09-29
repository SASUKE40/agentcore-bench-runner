# 选择运行模式

先排除 docker-compose 多容器任务（`environment/docker-compose.yaml` 声明了 `main` 以外的服务），这类任务不支持，见 [limitations.md](limitations.md#docker-compose-多容器任务)。

然后检查镜像大小，再按顺序判断，第一个命中的条件决定模式（依据任务的 `task.toml` 和镜像）：

0. 镜像压缩后超过 3 GB → **拆分构建**，再用 Instances 运行（见 [large-images.md](large-images.md)）。换模式本身绕不开镜像大小上限
1. 需要 GPU（`[environment].gpus > 0`）→ **Instances**
2. `cpus > 2` 或 `memory_mb > 8192` → **Instances**
3. 需要超过约 5 GiB 可写空间（`storage_mb`）→ **Instances**
4. 只有 x86 镜像、`environment/` 无法构建 arm64 → **Instances**
5. 其他情况 → **microVM**

镜像大小按实际要运行的镜像计算，并以账户配额为准（本账号实测：microVM 约 3 GB，Instances 默认 2 GB，可申请调到 3 GB）。microVM 还要求镜像**解压后**放得进约 8.8 GiB 的根文件系统，否则会话静默失败。计算方式：microVM 是 arm64 构建结果，Instances 是原始镜像加模板层（模板层很小：busybox 约 1 MB，补装 curl 时再加几 MB 到十几 MB，估算值，以实际推送后的 ECR 镜像大小为准）。

两种模式下 `bench.py submit`、`trial.sh`、结果格式都相同，只有 `--mode` 和 `--image` 不同。

## microVM 模式

- 镜像：在 arm64 机器（如 Graviton EC2）上，对任务的 `environment/` 目录原样执行 `docker build --platform linux/arm64`，推送到 ECR。

  ```bash
  scripts/build_microvm.sh tasks/<task> <ecr-repo>        # 推送 <ecr-repo>:arm64
  ```

- 沙箱：`CreateHarness`。harness 接管容器启动命令并保持会话，所以镜像不需要任何入口改造。同一镜像的 harness 被复用，首次创建约 150 秒。
- 注意：少数任务的依赖只有 x86 版本（x86 wheel、qemu 类任务），arm64 构建会失败，这类任务用 Instances 模式。

## Runtime Instances 模式

- 镜像：直接使用任务 `task.toml` 里的 `docker_image`，外面套一层对所有任务相同的模板 `adapter/Dockerfile`：

  ```bash
  scripts/build_instances.sh <docker_image> <ecr-repo>    # 推送 <ecr-repo>:instances
  ```

  模板只做两件事：
  1. 加入 `/opt/bench/busybox` 和 `/opt/bench/entry.sh`，在会话期间保持容器运行并响应 `:8080/ping` 健康检查。任务镜像本身通常没有常驻进程。
  2. 镜像里缺 curl 时补装 curl 和 ca-certificates。许多任务的 `test.sh` 在判分时 `apt-get install curl`，而运行时没有 Linux capability，apt 无法工作，所以在构建时装好。其他需要预装的包用 `APT_PACKAGES="pkg ..."` 追加。

- 沙箱：`CreateAgentRuntime` + `capacityProviderConfiguration`，运行在你账户的 EC2 上，按 EC2 + EBS 计费。同一镜像的 runtime 被复用。
- 冷启动：capacity provider 没有空闲实例时，首条命令要等实例就绪，约 2 分钟。

## 可写空间大的任务

`task.toml` 的 `storage_mb` 超过 microVM 的约 5 GiB 时用 Instances 模式，**不需要改镜像**，在 capacity provider 上配置磁盘即可：

| 配置 | 范围 | 用途 |
|---|---|---|
| `rootVolume.freeSpaceGiB` | 2 - 65,000 GiB | 容器根文件系统的可用空间，任务的工作目录直接可写 |
| `volumes[].ebsConfiguration` | 最多 5 个，每个 1 - 65,536 GiB | 挂到指定路径的独立卷，可从快照初始化 |

磁盘配置属于 capacity provider，不属于单个任务。按任务的 `storage_mb` 分组，每组用一个 capacity provider。镜像解压后的内容也占用根卷，`freeSpaceGiB` 要按 `storage_mb` + 镜像解压后大小估算（实测：镜像多 7 GiB 时，20 GiB 的根卷只剩约 12.6 GiB 可写）。

## 镜像超过上限

见 [large-images.md](large-images.md)：拆分构建，大目录移到 S3（已实现）或 EBS 快照（设计），运行时放回原路径。
