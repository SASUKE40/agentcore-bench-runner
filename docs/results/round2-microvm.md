# 第二轮 · microVM

修复后的代码，全量。

reward 1：49 / 87

| 任务 | 镜像 MB（压缩后） | reward | 分类 | agent s | 判分 s | 可写空间 MB（开始 -> 结束） | 错误 |
|---|---|---|---|---|---|---|---|
| adaptive-rejection-sampler | 34 | 0 | agent 解题失败 | 534 | 9 | 4404 -> 2895 |  |
| bn-fit-modify | 256 | 1 | 通过 | 219 | 10 | 3842 -> 2625 |  |
| break-filter-js-from-html | 408 | 0 | agent 解题失败 | 1060 | 10 | 3384 -> 3278 |  |
| build-cython-ext | 283 | 1 | 通过 | 702 | 3 | 3722 -> 3484 |  |
| build-pmars | 72 | 0 | agent 解题失败 | 167 | 3 | 4324 -> 3784 |  |
| build-pov-ray | 166 | 1 | 通过 | 634 | 19 | 4066 -> 3300 |  |
| caffe-cifar-10 | 207 | 0 | agent 超时 | 1200 | 5 | 3980 -> 3169 | agent timed out after 1200s |
| cancel-async-tasks | 48 | 0 | agent 解题失败 | 115 | 17 | 4357 -> 4279 |  |
| chess-best-move | 224 | 0 | agent 解题失败 | 127 | 5 | 3905 -> 3704 |  |
| circuit-fibsqrt | 139 | 1 | 通过 | 743 | 5 | 4137 -> 4059 |  |
| cobol-modernization | 157 | 1 | 通过 | 426 | 4 | 4091 -> 4011 |  |
| code-from-image | 48 | 1 | 通过 | 19 | 4 | 4357 -> 4280 |  |
| compile-compcert | 41 | 1 | 通过 | 1033 | 5 | 4381 -> 1123 |  |
| configure-git-webserver | 74 | 0 | 端口 8080 被占用 | 260 | 29 | 4349 -> 3888 |  |
| constraints-scheduling | 53 | 1 | 通过 | 59 | 7 | 4338 -> 4138 |  |
| count-dataset-tokens | 48 | 1 | 通过 | 199 | 3 | 4357 -> 3627 |  |
| crack-7z-hash | 352 | 1 | 通过 | 159 | 5 | 3756 -> 3546 |  |
| custom-memory-heap-crash | 1235 | - | 提交失败 | - | - | - -> - | agent install failed (exit 1): |
| db-wal-recovery | 174 | 0 | agent 解题失败 | 187 | 7 | 3984 -> 3783 |  |
| distribution-search | 177 | 1 | 通过 | 235 | 3 | 4081 -> 3950 |  |
| dna-assembly | 34 | 0 | agent 解题失败 | 970 | 7 | 4404 -> 4200 |  |
| dna-insert | 34 | 0 | agent 解题失败 | 243 | 6 | 4404 -> 4203 |  |
| extract-elf | 353 | 1 | 通过 | 93 | 6 | 3374 -> 3174 |  |
| extract-moves-from-video | 34 | 0 | agent 解题失败 | 253 | 5 | 4404 -> 2839 |  |
| feal-differential-cryptanalysis | 114 | 0 | agent 解题失败 | 951 | 5 | 4189 -> 4107 |  |
| feal-linear-cryptanalysis | 146 | 1 | 通过 | 352 | 3 | 4116 -> 4042 |  |
| filter-js-from-html | 404 | 0 | agent 解题失败 | 307 | 16 | 3392 -> 3285 |  |
| financial-document-processor | 55 | 1 | 通过 | 111 | 9 | 4363 -> 4034 |  |
| fix-code-vulnerability | 197 | 1 | 通过 | 45 | 2 | 3985 -> 3977 |  |
| fix-git | 159 | 1 | 通过 | 47 | 5 | 4176 -> 4098 |  |
| fix-ocaml-gc | 777 | 1 | 通过 | 1211 | 208 | 3344 -> 1842 |  |
| gcode-to-text | 49 | 1 | 通过 | 159 | 4 | 4355 -> 4060 |  |
| git-leak-recovery | 101 | 1 | 通过 | 44 | 7 | 4256 -> 4056 |  |
| git-multibranch | 220 | 0 | 端口 8080 被占用 | 680 | 23 | 3847 -> 3646 |  |
| gpt2-codegolf | 611 | 0 | agent 超时 | 900 | 6 | 3682 -> 3006 | agent timed out after 900s |
| headless-terminal | 80 | 1 | 通过 | 189 | 18 | 4285 -> 4232 |  |
| hf-model-inference | 403 | 1 | 通过 | 51 | 7 | 3414 -> 2881 |  |
| install-windows-3.11 | 577 | 0 | agent 解题失败 | 408 | 15 | 2899 -> 2292 |  |
| kv-store-grpc | 48 | 1 | 通过 | 49 | 2 | 4357 -> 4279 |  |
| large-scale-text-editing | 78 | 1 | 通过 | 115 | 43 | 4226 -> 4077 |  |
| largest-eigenval | 85 | 1 | 通过 | 79 | 2 | 4271 -> 4072 |  |
| llm-inference-batching-scheduler | 48 | 1 | 通过 | 1101 | 4 | 4357 -> 4279 |  |
| log-summary-date-ranges | 49 | 1 | 通过 | 39 | 3 | 4351 -> 4274 |  |
| mailman | 165 | 1 | 通过 | 417 | 30 | 4038 -> 3818 |  |
| make-doom-for-mips | 199 | 0 | agent 超时 | 900 | 33 | 3984 -> 3689 | agent timed out after 900s |
| make-mips-interpreter | 489 | 0 | agent 解题失败 | 1253 | 33 | 3045 -> 2895 |  |
| mcmc-sampling-stan | 234 | 1 | 通过 | 1202 | 215 | 3898 -> 3156 |  |
| merge-diff-arc-agi-task | 58 | 1 | 通过 | 120 | 8 | 4322 -> 4122 |  |
| model-extraction-relu-logits | 84 | 1 | 通过 | 667 | 11 | 4273 -> 4143 |  |
| modernize-scientific-stack | 326 | 1 | 通过 | 24 | 5 | 3520 -> 3127 |  |
| mteb-leaderboard | 6965 | - | 镜像超过上限 | - | - | - -> - | image is 6965 MB compressed, over max_image_mb=3000; see docs/large-images.md |
| mteb-retrieve | 6979 | - | 镜像超过上限 | - | - | - -> - | image is 6979 MB compressed, over max_image_mb=3000; see docs/large-images.md |
| multi-source-data-merger | 230 | 1 | 通过 | 48 | 5 | 3925 -> 3587 |  |
| nginx-request-logging | 69 | 0 | 端口 8080 被占用 | 253 | 5 | 4323 -> 4231 |  |
| openssl-selfsigned-cert | 51 | 0 | agent 解题失败 | 52 | 4 | 4349 -> 4243 |  |
| overfull-hbox | 138 | 1 | 通过 | 198 | 35 | 4143 -> 3882 |  |
| password-recovery | 67 | 1 | 通过 | 266 | 7 | 4276 -> 4067 |  |
| path-tracing | 392 | 1 | 通过 | 1297 | 13 | 3431 -> 3129 |  |
| path-tracing-reverse | 166 | 1 | 通过 | 1048 | 11 | 4105 -> 3785 |  |
| polyglot-c-py | 148 | 1 | 通过 | 162 | 7 | 4158 -> 3957 |  |
| polyglot-rust-c | 266 | 0 | agent 超时 | 900 | 6 | 3754 -> 3553 | agent timed out after 900s |
| portfolio-optimization | 180 | 1 | 通过 | 333 | 67 | 3959 -> 3822 |  |
| protein-assembly | 48 | 0 | agent 解题失败 | 489 | 4 | 4357 -> 4206 |  |
| prove-plus-comm | 512 | 1 | 通过 | 28 | 8 | 3181 -> 2981 |  |
| pypi-server | 89 | 0 | 端口 8080 被占用 | 432 | 4 | 4261 -> 4153 |  |
| pytorch-model-cli | 203 | - | 磁盘写满，rootfs 只读 | 263 | None | 3979 -> 1265 | root filesystem became read-only (disk full); could not fetch tests |
| pytorch-model-recovery | 319 | 0 | agent 解题失败 | 0 | 8 | 3651 -> 3088 |  |
| query-optimize | 123 | 0 | agent 解题失败 | 378 | 1122 | 4248 -> 3999 |  |
| raman-fitting | 48 | 0 | agent 解题失败 | 380 | 4 | 4357 -> 4011 |  |
| regex-chess | 60 | 1 | 通过 | 2370 | 51 | 4336 -> 4243 |  |
| regex-log | 34 | 1 | 通过 | 112 | 6 | 4404 -> 4204 |  |
| reshard-c4-data | 1122 | 1 | 通过 | 408 | 120 | 2114 -> 0 |  |
| rstan-to-pystan | 55 | - | lost（无心跳） | - | - | - -> - | sandbox gone: no heartbeat since 2026-09-28T18:10:42Z, last phase agent |
| sam-cell-seg | 471 | - | 磁盘写满，rootfs 只读 | 391 | None | 3176 -> 2733 | root filesystem became read-only (disk full); could not fetch tests |
| sanitize-git-repo | 203 | 1 | 通过 | 117 | 4 | 4127 -> 4047 |  |
| schemelike-metacircular-eval | 48 | 0 | agent 解题失败 | 2034 | 85 | 4354 -> 4276 |  |
| sparql-university | 34 | 1 | 通过 | 224 | 9 | 4401 -> 4095 |  |
| sqlite-db-truncate | 48 | 1 | 通过 | 102 | 4 | 4357 -> 4280 |  |
| sqlite-with-gcov | 47 | 1 | 通过 | 167 | 5 | 4389 -> 3616 |  |
| torch-pipeline-parallelism | 34 | 0 | agent 解题失败 | 344 | 39 | 4401 -> 3524 |  |
| torch-tensor-parallelism | 34 | - | agent 解题失败 | 200 | 900 | 4401 -> 3719 |  |
| train-fasttext | 508 | 0 | agent 解题失败 | 367 | 13 | 3668 -> 2283 |  |
| tune-mjcf | 84 | 0 | agent 超时 | 900 | 23 | 4219 -> 4031 | agent timed out after 900s |
| video-processing | 284 | 0 | agent 解题失败 | 512 | 9 | 3852 -> 3552 |  |
| vulnerable-secret | 123 | 1 | 通过 | 101 | 4 | 4153 -> 4076 |  |
| winning-avg-corewars | 303 | 1 | 通过 | 2160 | 22 | 3709 -> 3597 |  |
| write-compressor | 288 | 1 | 通过 | 443 | 7 | 3745 -> 3545 |  |
