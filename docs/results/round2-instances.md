# 第二轮 · Instances

修复后的代码，全量。

reward 1：52 / 89

| 任务 | 镜像 MB（压缩后） | reward | 分类 | agent s | 判分 s | 可写空间 MB（开始 -> 结束） | 错误 |
|---|---|---|---|---|---|---|---|
| adaptive-rejection-sampler | 37 | 0 | agent 超时 | 900 | 6 | 19629 -> 18411 | agent timed out after 900s |
| bn-fit-modify | 265 | 1 | 通过 | 171 | 9 | 18759 -> 17652 |  |
| break-filter-js-from-html | 386 | 1 | 通过 | 676 | 4 | 18070 -> 18210 |  |
| build-cython-ext | 307 | 1 | 通过 | 458 | 3 | 18554 -> 18331 |  |
| build-pmars | 68 | 1 | 通过 | 260 | 3 | 19388 -> 19126 |  |
| build-pov-ray | 166 | 0 | agent 解题失败 | 782 | 6 | 19109 -> 18278 |  |
| caffe-cifar-10 | 212 | 0 | agent 超时 | 1200 | 4 | 18915 -> 16908 | agent timed out after 1200s |
| cancel-async-tasks | 49 | 1 | 通过 | 209 | 18 | 19427 -> 19550 |  |
| chess-best-move | 243 | 1 | 通过 | 127 | 5 | 18801 -> 18586 |  |
| circuit-fibsqrt | 153 | 1 | 通过 | 1156 | 4 | 19126 -> 19161 |  |
| cobol-modernization | 166 | 1 | 通过 | 445 | 4 | 19117 -> 19126 |  |
| code-from-image | 49 | 1 | 通过 | 18 | 4 | 19530 -> 19538 |  |
| compile-compcert | 43 | - | lost（无心跳） | - | - | - -> - | sandbox gone: no heartbeat since 2026-09-29T00:02:44Z, last phase agent |
| configure-git-webserver | 74 | 0 | agent 超时 | 900 | 8 | 19499 -> 19163 | agent timed out after 900s |
| constraints-scheduling | 55 | 1 | 通过 | 44 | 7 | 19370 -> 19300 |  |
| count-dataset-tokens | 49 | 1 | 通过 | 75 | 3 | 19369 -> 18858 |  |
| crack-7z-hash | 359 | 1 | 通过 | 186 | 5 | 18616 -> 18356 |  |
| custom-memory-heap-crash | 1272 | 0 | agent 解题失败 | 298 | 11 | 13946 -> 13782 |  |
| db-wal-recovery | 179 | 1 | 通过 | 107 | 6 | 19012 -> 18880 |  |
| distribution-search | 186 | 1 | 通过 | 102 | 4 | 19071 -> 19059 |  |
| dna-assembly | 37 | 1 | 通过 | 703 | 7 | 19512 -> 19385 |  |
| dna-insert | 37 | 0 | agent 解题失败 | 287 | 5 | 19468 -> 19376 |  |
| extract-elf | 351 | 1 | 通过 | 85 | 7 | 18014 -> 18077 |  |
| extract-moves-from-video | 37 | 0 | agent 解题失败 | 98 | 5 | 19467 -> 19340 |  |
| feal-differential-cryptanalysis | 118 | 0 | agent 解题失败 | 444 | 4 | 19312 -> 19284 |  |
| feal-linear-cryptanalysis | 155 | 1 | 通过 | 1502 | 3 | 19170 -> 19157 |  |
| filter-js-from-html | 381 | 0 | agent 解题失败 | 269 | 240 | 18084 -> 16945 |  |
| financial-document-processor | 59 | 1 | 通过 | 91 | 8 | 19441 -> 19094 |  |
| fix-code-vulnerability | 194 | 1 | 通过 | 21 | 2 | 19031 -> 19125 |  |
| fix-git | 161 | 1 | 通过 | 59 | 4 | 19197 -> 19242 |  |
| fix-ocaml-gc | 769 | 1 | 通过 | 165 | 194 | 17860 -> 16340 |  |
| gcode-to-text | 50 | 1 | 通过 | 300 | 3 | 19386 -> 19314 |  |
| git-leak-recovery | 99 | 1 | 通过 | 41 | 7 | 19348 -> 19190 |  |
| git-multibranch | 227 | 0 | 缺少 capability | 869 | 10 | 18747 -> 18673 |  |
| gpt2-codegolf | 617 | 0 | agent 超时 | 900 | 7 | 18323 -> 18078 | agent timed out after 900s |
| headless-terminal | 81 | 1 | 通过 | 79 | 17 | 19475 -> 19469 |  |
| hf-model-inference | 6191 | - | 镜像超过上限 | - | - | - -> - | image is 6191 MB compressed, over max_image_mb=2000; see docs/large-images.md |
| install-windows-3.11 | 588 | 0 | agent 解题失败 | 833 | 14 | 17564 -> 16930 |  |
| kv-store-grpc | 49 | 1 | 通过 | 37 | 3 | 19399 -> 19509 |  |
| large-scale-text-editing | 78 | 1 | 通过 | 167 | 44 | 19289 -> 19318 |  |
| largest-eigenval | 89 | 1 | 通过 | 123 | 2 | 19326 -> 19306 |  |
| llm-inference-batching-scheduler | 49 | 1 | 通过 | 612 | 4 | 19390 -> 19534 |  |
| log-summary-date-ranges | 50 | 1 | 通过 | 25 | 3 | 19382 -> 19548 |  |
| mailman | 166 | 0 | agent 超时 | 1800 | 10 | 19049 -> 18840 | agent timed out after 1800s |
| make-doom-for-mips | 209 | 0 | agent 超时 | 900 | 33 | 18875 -> 18752 | agent timed out after 900s |
| make-mips-interpreter | 526 | 1 | 通过 | 980 | 4 | 17642 -> 17545 |  |
| mcmc-sampling-stan | 240 | 1 | 通过 | 1195 | 185 | 18844 -> 17817 |  |
| merge-diff-arc-agi-task | 60 | 1 | 通过 | 115 | 5 | 19343 -> 19276 |  |
| model-extraction-relu-logits | 88 | 1 | 通过 | 282 | 22 | 19398 -> 19335 |  |
| modernize-scientific-stack | 350 | 1 | 通过 | 30 | 5 | 18189 -> 17885 |  |
| mteb-leaderboard | 8824 | - | 镜像超过上限 | - | - | - -> - | image is 8824 MB compressed, over max_image_mb=2000; see docs/large-images.md |
| mteb-retrieve | 8814 | - | 镜像超过上限 | - | - | - -> - | image is 8814 MB compressed, over max_image_mb=2000; see docs/large-images.md |
| multi-source-data-merger | 228 | 1 | 通过 | 53 | 5 | 18876 -> 18596 |  |
| nginx-request-logging | 70 | 0 | agent 解题失败 | 846 | 4 | 19382 -> 19470 |  |
| openssl-selfsigned-cert | 49 | 0 | agent 解题失败 | 39 | 3 | 19368 -> 19496 |  |
| overfull-hbox | 139 | 1 | 通过 | 163 | 28 | 19239 -> 19025 |  |
| password-recovery | 65 | 1 | 通过 | 271 | 7 | 19318 -> 19245 |  |
| path-tracing | 402 | 0 | 缺少 capability | 1001 | 7 | 18075 -> 17878 |  |
| path-tracing-reverse | 173 | 0 | 缺少 capability | 1639 | 8 | 19139 -> 18806 |  |
| polyglot-c-py | 156 | 0 | agent 解题失败 | 247 | 5 | 19210 -> 18976 |  |
| polyglot-rust-c | 278 | 0 | agent 解题失败 | 489 | 7 | 18656 -> 18467 |  |
| portfolio-optimization | 200 | 1 | 通过 | 266 | 52 | 18836 -> 18882 |  |
| protein-assembly | 49 | 0 | agent 解题失败 | 1674 | 4 | 19553 -> 19418 |  |
| prove-plus-comm | 496 | 1 | 通过 | 27 | 7 | 17890 -> 17785 |  |
| pypi-server | 86 | 1 | 通过 | 241 | 4 | 19332 -> 19385 |  |
| pytorch-model-cli | 220 | - | lost（无心跳） | - | - | - -> - | sandbox gone: no heartbeat since 2026-09-29T00:48:17Z, last phase agent |
| pytorch-model-recovery | 6108 | - | 镜像超过上限 | - | - | - -> - | image is 6108 MB compressed, over max_image_mb=2000; see docs/large-images.md |
| qemu-alpine-ssh | - | - | 构建失败，无镜像 | - | - | - -> - | image not found in ECR |
| qemu-startup | - | - | 构建失败，无镜像 | - | - | - -> - | image not found in ECR |
| query-optimize | 123 | 0 | agent 解题失败 | 335 | 410 | 19358 -> 19231 |  |
| raman-fitting | 49 | 0 | agent 解题失败 | 325 | 3 | 19367 -> 19149 |  |
| regex-chess | 60 | 1 | 通过 | 2135 | 64 | 19330 -> 19495 |  |
| regex-log | 37 | 1 | 通过 | 102 | 6 | 19457 -> 19379 |  |
| reshard-c4-data | 1437 | 1 | 通过 | 272 | 34 | 15603 -> 13538 |  |
| rstan-to-pystan | 56 | 0 | agent 解题失败 | 898 | 5 | 19362 -> 16433 |  |
| sam-cell-seg | 485 | 0 | agent 解题失败 | 483 | 19 | 17817 -> 7546 |  |
| sanitize-git-repo | 206 | 1 | 通过 | 85 | 4 | 19084 -> 19168 |  |
| schemelike-metacircular-eval | 49 | 1 | 通过 | 1184 | 67 | 19530 -> 19540 |  |
| sparql-university | 37 | 1 | 通过 | 145 | 8 | 19490 -> 19168 |  |
| sqlite-db-truncate | 49 | 1 | 通过 | 98 | 3 | 19454 -> 19562 |  |
| sqlite-with-gcov | 50 | 1 | 通过 | 297 | 5 | 19605 -> 18879 |  |
| torch-pipeline-parallelism | 37 | 1 | 通过 | 467 | 45 | 19465 -> 11500 |  |
| torch-tensor-parallelism | 37 | 0 | agent 解题失败 | 83 | 54 | 19490 -> 14278 |  |
| train-fasttext | 514 | 0 | agent 解题失败 | 633 | 7 | 18366 -> 13800 |  |
| tune-mjcf | 85 | 1 | 通过 | 164 | 15 | 19351 -> 19268 |  |
| video-processing | 317 | 0 | agent 解题失败 | 824 | 5 | 18742 -> 18324 |  |
| vulnerable-secret | 138 | 1 | 通过 | 62 | 4 | 19183 -> 19222 |  |
| winning-avg-corewars | 300 | 0 | agent 解题失败 | 3409 | 7 | 18723 -> 18629 |  |
| write-compressor | 299 | 1 | 通过 | 658 | 5 | 18692 -> 18468 |  |
