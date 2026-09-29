# 大镜像的处理

镜像受两个限制，两种模式表现不同（测试数据见 [size-and-storage-tests.md](size-and-storage-tests.md)）：

| 限制 | microVM | Runtime Instances |
|---|---|---|
| 压缩后大小（ECR 的 `imageSizeInBytes`） | 账户配额，本账号实测约 3 GB。超限时 Harness 照样创建成功，**会话静默失败** | 账户配额 `maxImageSizeMb`，默认 2 GB，可申请调到 3 GB。超限时 `CreateAgentRuntime` 直接拒绝 |
| 解压后大小 | 镜像和可写空间共用约 8.8 GiB 的根文件系统，放不下时会话静默失败 | 占用根卷，挤占任务的可写空间 |

`bench.py submit` 在创建沙箱前读取 ECR 镜像大小，超过配置里的 `max_image_mb` 直接拒绝；microVM 会话无输出时给出上述原因。`max_image_mb` 按账户实际配额填写（十进制 MB）。

## 怎么选

1. 镜像在配额内，且 microVM 下解压后放得进根文件系统 → 直接运行。
2. Instances 镜像在 2-3 GB 之间 → 先申请把 `maxImageSizeMb` 调到 3 GB，最省事。
3. 超过 3 GB，或者 microVM 放不下 → **拆分构建，用 Instances 运行**。下面两种存放方式二选一：

| | A. S3 归档（已实现，已验证） | B. EBS 快照卷（设计，未在本仓库验证） |
|---|---|---|
| 大内容放在哪 | S3，每个目录一个 `.tar.gz` | EBS 快照，capacity provider 建卷时挂到原路径 |
| 每个 trial 的额外时间 | 下载并解压。实测 3.4 GB 压缩（10.4 GB 解压）用 79 s | 无下载；首次读取时从快照按需加载 |
| 基础设施 | 不需要新资源 | 每个快照要一个专用的 capacity provider |
| 根卷空间 | 需要容纳解压后的全部内容 | 内容在独立卷上，不占根卷 |
| 适合 | 默认选择；任务多、每个任务跑的次数不多 | 同一大镜像要跑很多次，或内容有几十 GB、下载时间不可接受 |

microVM 不适合拆分构建：可写空间只有约 4.7 GiB，放回去的内容本身就放不下。

## A. S3 归档（`scripts/build_split.sh`）

构建时（在任意能运行 docker 的 x86 机器上）：

```bash
# 1. 找出体积大的目录
docker run --rm --entrypoint sh <original-image> -c 'du -xsh /* /root/* /opt/* 2>/dev/null | sort -rh | head'

# 2. 拆分：大目录上传到 S3，生成瘦身镜像并套上通用模板，推送 <ecr-repo>:split
scripts/build_split.sh <original-image> <ecr-repo> \
  s3://<results-bucket>/<results-prefix>/images/<task> /root/project /root/.elan

# 3. 和其他镜像一样提交
python runner/bench.py --config config.instances.json submit --mode instances \
  --task tasks/<task> --image <ecr-repo>:split
```

脚本做的事：

1. 每个目录用 `tar -czf` 打包，直接流式上传到 S3，本地不落盘。
2. 瘦身镜像 = 原镜像删除这些目录后**压平成一层**（只在上层删除不会减小镜像），并带回原镜像的 `ENV`、`WORKDIR`、`USER`、`CMD`。镜像里写入 `/etc/bench/restore.list`，列出这些归档的地址。
3. 套上 `adapter/` 模板，与 `build_instances.sh` 相同。

运行时，`trial.sh` 在启动 agent 之前把 `restore.list` 里的归档逐个流式下载、解压到原路径，耗时记入 `summary.json` 的 `timings_s.restore`，不占 agent 的超时时间。恢复失败时不运行 agent，`summary.json` 的 `error` 写明原因。

实测（`gen-turan-paths`，3.91 GB，解压后约 10.4 GB）：瘦身镜像 0.48 GB；恢复后两个目录的文件数和字节数与原镜像完全一致，`lake build` 直接命中编译缓存，reward 1。

注意：

- **移出的目录不能是容器启动和安装 agent 时需要的**，因为恢复发生在这之后。不要移出 `/usr`、`/lib`、`/bin`、`/etc`、`/opt/bench*`。适合移出的是数据集、模型权重、conda / pip 环境、工具链、编译缓存这类只在任务执行时用到的目录。
- 恢复时间和归档大小成正比。归档放在与 capacity provider **同一区域**的桶里；上面的实测是跨区域（S3 在 us-east-2，实例在 us-east-1），同区域应更快。
- capacity provider 的根卷可写空间要大于：解压后的恢复内容 + 任务自身的 `storage_mb`。例如 `gen-turan-paths` 要求 `storage_mb = 32768`，本次测试的 20 GiB 根卷只够做环境校验，正式运行需要把 `rootVolume.freeSpaceGiB` 调到 45 GiB 以上。
- Instances 下 root 没有 CAP_CHOWN，解压后文件属主都是 root（权限位保留）。原镜像里有非 root 属主的文件时，依赖属主的任务会受影响。
- 执行角色需要 `s3:GetObject` 读 `<prefix>/images/*`（见 [iam/execution-role-policy.json](../iam/execution-role-policy.json)）。
- 构建时 gzip 是单线程，10 GB 内容在开发机上约 11 分钟。

## B. EBS 快照卷（设计）

适用于同一大镜像要反复运行的情况：每个 trial 不再下载，内容以快照卷的形式出现在原路径。

构建时：

1. 用 A 的方法得到瘦身镜像和归档（B 复用 A 的构建产物，只是换一种存放方式）。
2. 在同区域启动一台临时 EC2，挂一个新 EBS 卷，把归档解压进去，保持与原镜像相同的目录结构，然后创建快照。
3. 每个快照建一个 capacity provider，`computeConfiguration.volumes[].ebsConfiguration` 填 `snapshotId`、`sizeGiB`。
4. 创建 runtime 时，`filesystemConfigurations[].capacityProviderVolume` 填卷名和 `mountPath`（原目录路径）。瘦身镜像里不写 `restore.list`，`trial.sh` 就不做恢复。

需要注意：

- 一个卷只能挂到一个路径。多个大目录要么各用一个卷（每个 capacity provider 最多 5 个卷），要么挂它们共同的父目录，此时卷里要放父目录的**全部**原始内容，否则挂载会遮住镜像里的其他文件。
- 快照绑定在 capacity provider 上，所以是"一个大镜像一个 capacity provider"。`bench.py` 目前每种模式只读一个 `capacity_provider_arn`，需要按镜像配置不同的 capacity provider。
- capacity provider 的 operator 角色要对源快照有 `ec2:CreateVolume` 权限，缺少时实例在准备阶段失败（之前的 EBS 快照 PoC 实测）。
- 快照卷首次读取从 S3 按需加载。之前的 PoC 中，7.7 GiB 快照的会话冷启动为 52 s，但没有测量读满全部内容的时间。启动实例参数里的 `ephemeralVolumes[].ebs` 有 `volumeInitializationRate`（EBS 卷初始化速率），可能用于加快加载，未验证。

## microVM 的可选方向（未验证）

Harness 的 `filesystemConfigurations` 支持 EFS 访问点和 S3 Files 访问点，挂到指定路径。把大目录放在 EFS 上、以原路径挂载，理论上可以绕开 microVM 根文件系统的空间限制。需要 VPC 网络模式，本仓库没有验证。
