# 第一轮 · microVM

初版代码。本轮暴露的问题及修复见 [batch-tests.md](../batch-tests.md#22-第一轮运行暴露的问题)。

reward 1：54 / 87

| 任务 | 镜像 MB（压缩后） | reward | 分类 | agent s | 判分 s | 可写空间 MB（开始 -> 结束） | 错误 |
|---|---|---|---|---|---|---|---|
| adaptive-rejection-sampler | 34 | 1 | 通过 | 515 | 12 | 4404 -> 2895 |  |
| bn-fit-modify | 256 | 1 | 通过 | 151 | 12 | 3842 -> 2806 |  |
| break-filter-js-from-html | 408 | 1 | 通过 | 480 | 5 | 3384 -> 3278 |  |
| build-cython-ext | 283 | 1 | 通过 | 303 | 3 | 3722 -> 3492 |  |
| build-pmars | 72 | 1 | 通过 | 156 | 4 | 4324 -> 3784 |  |
| build-pov-ray | 166 | 1 | 通过 | 168 | 14 | 4066 -> 3310 |  |
| caffe-cifar-10 | 207 | 0 | agent 超时 | 1201 | 5 | 3980 -> 1775 | agent timed out after 1200s |
| cancel-async-tasks | 48 | 0 | agent 解题失败 | 102 | 16 | 4357 -> 4279 |  |
| chess-best-move | 224 | 1 | 通过 | 153 | 8 | 3905 -> 3696 |  |
| circuit-fibsqrt | 139 | 1 | 通过 | 833 | 4 | 4137 -> 4060 |  |
| cobol-modernization | 157 | 1 | 通过 | 340 | 4 | 4091 -> 4014 |  |
| code-from-image | 48 | 1 | 通过 | 19 | 5 | 4357 -> 4280 |  |
| compile-compcert | 41 | - | lost（无心跳） | - | - | - -> - | sandbox gone: no heartbeat since 2026-09-28T15:36:05Z, last phase agent |
| configure-git-webserver | 74 | 0 | 端口 8080 被占用 | 315 | 31 | 4349 -> 3875 |  |
| constraints-scheduling | 53 | 1 | 通过 | 87 | 7 | 4338 -> 4138 |  |
| count-dataset-tokens | 48 | 1 | 通过 | 75 | 3 | 4357 -> 3627 |  |
| crack-7z-hash | 352 | 0 | agent 解题失败 | 356 | 8 | 3756 -> 3554 |  |
| custom-memory-heap-crash | 1235 | - | lost（无心跳） | - | - | - -> - | sandbox gone: no heartbeat since 2026-09-28T15:24:51Z, last phase agent |
| db-wal-recovery | 174 | 1 | 通过 | 60 | 8 | 3984 -> 3783 |  |
| distribution-search | 177 | 1 | 通过 | 159 | 4 | 4081 -> 3950 |  |
| dna-assembly | 34 | 1 | 通过 | 779 | 8 | 4404 -> 4203 |  |
| dna-insert | 34 | 0 | agent 解题失败 | 269 | 6 | 4404 -> 4203 |  |
| extract-elf | 353 | 1 | 通过 | 67 | 7 | 3270 -> 3069 |  |
| extract-moves-from-video | 34 | 0 | agent 解题失败 | 313 | 5 | 4404 -> 2410 |  |
| feal-differential-cryptanalysis | 114 | 0 | agent 超时 | 1800 | 3 | 4189 -> 4024 | agent timed out after 1800s |
| feal-linear-cryptanalysis | 146 | 0 | agent 解题失败 | 935 | 9 | 4116 -> 4041 |  |
| filter-js-from-html | 404 | 0 | agent 解题失败 | 177 | 11 | 3392 -> 3285 |  |
| financial-document-processor | 55 | 1 | 通过 | 119 | 7 | 4363 -> 4034 |  |
| fix-code-vulnerability | 197 | 1 | 通过 | 39 | 2 | 3985 -> 3977 |  |
| fix-git | 159 | 1 | 通过 | 49 | 4 | 4176 -> 4099 |  |
| fix-ocaml-gc | 777 | 1 | 通过 | 1100 | 234 | 3344 -> 1842 |  |
| gcode-to-text | 49 | 1 | 通过 | 353 | 4 | 4355 -> 4059 |  |
| git-leak-recovery | 101 | 1 | 通过 | 51 | 7 | 4256 -> 4056 |  |
| git-multibranch | 220 | 0 | agent 解题失败 | 848 | 23 | 3847 -> 3644 |  |
| gpt2-codegolf | 611 | 0 | agent 超时 | 900 | 8 | 3683 -> 3482 | agent timed out after 900s |
| headless-terminal | 80 | 0 | agent 解题失败 | 107 | 32 | 4286 -> 4227 |  |
| hf-model-inference | 403 | 1 | 通过 | 52 | 9 | 3414 -> 2881 |  |
| install-windows-3.11 | 577 | - | 提交失败 | - | - | - -> - | agent install failed (exit 127): |
| kv-store-grpc | 48 | 1 | 通过 | 45 | 3 | 4357 -> 4279 |  |
| large-scale-text-editing | 78 | 1 | 通过 | 157 | 55 | 4226 -> 4041 |  |
| largest-eigenval | 85 | 1 | 通过 | 58 | 3 | 4271 -> 4073 |  |
| llm-inference-batching-scheduler | 48 | 1 | 通过 | 415 | 4 | 4357 -> 4279 |  |
| log-summary-date-ranges | 49 | 1 | 通过 | 33 | 5 | 4351 -> 4274 |  |
| mailman | 165 | 1 | 通过 | 423 | 25 | 4038 -> 3818 |  |
| make-doom-for-mips | 199 | - | 提交失败 | - | - | - -> - | agent install failed (exit 127): |
| make-mips-interpreter | 489 | - | 提交失败 | - | - | - -> - | agent install failed (exit 127): |
| mcmc-sampling-stan | 234 | 1 | 通过 | 630 | 166 | 3898 -> 3158 |  |
| merge-diff-arc-agi-task | 58 | 1 | 通过 | 106 | 13 | 4322 -> 4122 |  |
| model-extraction-relu-logits | 84 | 0 | agent 解题失败 | 697 | 18 | 4273 -> 4143 |  |
| modernize-scientific-stack | 326 | 1 | 通过 | 21 | 5 | 3520 -> 3127 |  |
| mteb-leaderboard | 6965 | - | 镜像超过上限 | - | - | - -> - | image is 6965 MB compressed, over max_image_mb=3000; see docs/large-images.md |
| mteb-retrieve | 6979 | - | 镜像超过上限 | - | - | - -> - | image is 6979 MB compressed, over max_image_mb=3000; see docs/large-images.md |
| multi-source-data-merger | 230 | 1 | 通过 | 57 | 6 | 3925 -> 3587 |  |
| nginx-request-logging | 69 | 0 | 端口 8080 被占用 | 197 | 6 | 4323 -> 4232 |  |
| openssl-selfsigned-cert | 51 | 1 | 通过 | 50 | 3 | 4349 -> 4272 |  |
| overfull-hbox | 138 | 1 | 通过 | 690 | 32 | 4143 -> 3882 |  |
| password-recovery | 67 | 1 | 通过 | 413 | 6 | 4276 -> 4076 |  |
| path-tracing | 392 | 1 | 通过 | 570 | 26 | 3431 -> 3108 |  |
| path-tracing-reverse | 166 | 1 | 通过 | 1539 | 10 | 4105 -> 3775 |  |
| polyglot-c-py | 148 | 1 | 通过 | 221 | 5 | 4158 -> 3908 |  |
| polyglot-rust-c | 266 | 0 | agent 超时 | 900 | 8 | 3754 -> 3554 | agent timed out after 900s |
| portfolio-optimization | 180 | 1 | 通过 | 267 | 95 | 3959 -> 3822 |  |
| protein-assembly | 48 | 0 | agent 解题失败 | 685 | 6 | 4357 -> 4206 |  |
| prove-plus-comm | 512 | 1 | 通过 | 28 | 9 | 3181 -> 2981 |  |
| pypi-server | 89 | 0 | 端口 8080 被占用 | 198 | 5 | 4261 -> 4157 |  |
| pytorch-model-cli | 203 | 1 | 通过 | 152 | 12 | 3979 -> 2646 |  |
| pytorch-model-recovery | 319 | 0 | agent 解题失败 | 0 | 9 | 3651 -> 3088 |  |
| query-optimize | 123 | 1 | 通过 | 376 | 1114 | 4248 -> 3999 |  |
| raman-fitting | 48 | 0 | agent 解题失败 | 611 | 4 | 4357 -> 3884 |  |
| regex-chess | 60 | 1 | 通过 | 1914 | 91 | 4339 -> 4246 |  |
| regex-log | 34 | 1 | 通过 | 156 | 7 | 4404 -> 4204 |  |
| reshard-c4-data | 1122 | 0 | agent 解题失败 | 317 | 1 | 2117 -> 2081 |  |
| rstan-to-pystan | 55 | - | lost（无心跳） | - | - | - -> - | sandbox gone: no heartbeat since 2026-09-28T16:14:40Z, last phase agent |
| sam-cell-seg | 471 | 0 | agent 解题失败 | 368 | 22 | 3179 -> 538 |  |
| sanitize-git-repo | 203 | 1 | 通过 | 90 | 3 | 4127 -> 4048 |  |
| schemelike-metacircular-eval | 48 | 1 | 通过 | 1633 | 106 | 4357 -> 4279 |  |
| sparql-university | 34 | 0 | agent 解题失败 | 245 | 8 | 4404 -> 3985 |  |
| sqlite-db-truncate | 48 | 1 | 通过 | 158 | 3 | 4357 -> 4280 |  |
| sqlite-with-gcov | 47 | 1 | 通过 | 147 | 4 | 4392 -> 3622 |  |
| torch-pipeline-parallelism | 34 | 1 | 通过 | 238 | 41 | 4404 -> 3527 |  |
| torch-tensor-parallelism | 34 | - | agent 解题失败 | 121 | 900 | 4404 -> 3722 |  |
| train-fasttext | 508 | 0 | 磁盘写满 | 3600 | 7 | 3671 -> 0 | agent timed out after 3600s |
| tune-mjcf | 84 | 1 | 通过 | 259 | 21 | 4222 -> 4045 |  |
| video-processing | 284 | 0 | agent 解题失败 | 314 | 8 | 3855 -> 3579 |  |
| vulnerable-secret | 123 | 1 | 通过 | 91 | 7 | 4156 -> 4079 |  |
| winning-avg-corewars | 303 | 1 | 通过 | 1615 | 8 | 3710 -> 3599 |  |
| write-compressor | 288 | 1 | 通过 | 467 | 7 | 3750 -> 3549 |  |
