# 第一轮 · Instances

初版代码，跑到 84 个任务时停止（capacity provider 的实例空闲超时导致大量 lost）。

reward 1：48 / 84

| 任务 | 镜像 MB（压缩后） | reward | 分类 | agent s | 判分 s | 可写空间 MB（开始 -> 结束） | 错误 |
|---|---|---|---|---|---|---|---|
| adaptive-rejection-sampler | 37 | 0 | 缺少 capability | 606 | 8 | 19565 -> 15844 |  |
| bn-fit-modify | 265 | 1 | 通过 | 164 | 11 | 18818 -> 17639 |  |
| break-filter-js-from-html | 386 | 1 | 通过 | 237 | 4 | 18029 -> 18224 |  |
| build-cython-ext | 307 | 0 | agent 解题失败 | 315 | 3 | 18556 -> 18437 |  |
| build-pmars | 68 | 0 | 缺少 capability | 326 | 4 | 19332 -> 19152 |  |
| build-pov-ray | 166 | 0 | agent 解题失败 | 275 | 11 | 19046 -> 18336 |  |
| caffe-cifar-10 | 212 | - | lost（无心跳） | - | - | - -> - | sandbox gone: no heartbeat since 2026-09-28T16:36:15Z, last phase agent |
| cancel-async-tasks | 49 | 1 | 通过 | 66 | 18 | 19464 -> 19540 |  |
| chess-best-move | 243 | 1 | 通过 | 153 | 5 | 18893 -> 18659 |  |
| circuit-fibsqrt | 153 | 1 | 通过 | 763 | 5 | 19185 -> 19171 |  |
| cobol-modernization | 166 | 1 | 通过 | 373 | 4 | 19122 -> 19127 |  |
| code-from-image | 49 | 1 | 通过 | 13 | 4 | 19566 -> 19563 |  |
| compile-compcert | 43 | - | lost（无心跳） | - | - | - -> - | sandbox gone: no heartbeat since 2026-09-28T16:36:09Z, last phase agent |
| configure-git-webserver | 74 | 0 | agent 解题失败 | 397 | 7 | 19527 -> 19200 |  |
| constraints-scheduling | 55 | 1 | 通过 | 65 | 8 | 19385 -> 19318 |  |
| count-dataset-tokens | 49 | 1 | 通过 | 79 | 3 | 19402 -> 18860 |  |
| crack-7z-hash | 359 | 1 | 通过 | 102 | 4 | 18636 -> 18408 |  |
| custom-memory-heap-crash | 1272 | 0 | agent 解题失败 | 198 | 10 | 13958 -> 13696 |  |
| db-wal-recovery | 179 | 1 | 通过 | 78 | 7 | 18984 -> 18837 |  |
| distribution-search | 186 | 1 | 通过 | 145 | 3 | 19048 -> 19044 |  |
| dna-assembly | 37 | - | lost（无心跳） | - | - | - -> - | sandbox gone: no heartbeat since 2026-09-28T16:40:28Z, last phase verifier |
| dna-insert | 37 | 0 | agent 解题失败 | 208 | 7 | 19524 -> 19387 |  |
| extract-elf | 351 | 1 | 通过 | 100 | 7 | 18214 -> 17976 |  |
| extract-moves-from-video | 37 | 0 | 缺少 capability | 245 | 5 | 19469 -> 18355 |  |
| feal-differential-cryptanalysis | 118 | 0 | agent 解题失败 | 346 | 4 | 19305 -> 19278 |  |
| feal-linear-cryptanalysis | 155 | - | lost（无心跳） | - | - | - -> - | sandbox gone: no heartbeat since 2026-09-28T16:42:28Z, last phase agent |
| filter-js-from-html | 381 | 0 | agent 解题失败 | 221 | 142 | 18319 -> 17041 |  |
| financial-document-processor | 59 | 1 | 通过 | 102 | 8 | 19462 -> 19096 |  |
| fix-code-vulnerability | 194 | 1 | 通过 | 38 | 2 | 18856 -> 19127 |  |
| fix-git | 161 | 1 | 通过 | 41 | 4 | 19147 -> 19244 |  |
| fix-ocaml-gc | 769 | - | lost（无心跳） | - | - | - -> - | sandbox gone: no heartbeat since 2026-09-28T16:44:02Z, last phase agent |
| gcode-to-text | 50 | 1 | 通过 | 339 | 3 | 19453 -> 19325 |  |
| git-leak-recovery | 99 | 1 | 通过 | 45 | 6 | 19336 -> 19252 |  |
| git-multibranch | 227 | 0 | 缺少 capability | 604 | 9 | 18881 -> 18637 |  |
| gpt2-codegolf | 617 | - | lost（无心跳） | - | - | - -> - | sandbox gone: no heartbeat since 2026-09-28T16:46:05Z, last phase verifier |
| headless-terminal | 81 | 1 | 通过 | 125 | 18 | 19454 -> 19483 |  |
| hf-model-inference | 6191 | - | 镜像超过上限 | - | - | - -> - | image is 6191 MB compressed, over max_image_mb=2000; see docs/large-images.md |
| install-windows-3.11 | 588 | - | 提交失败 | - | - | - -> - | agent install failed (exit 127): |
| kv-store-grpc | 49 | 1 | 通过 | 49 | 3 | 19464 -> 19526 |  |
| large-scale-text-editing | 78 | 1 | 通过 | 123 | 40 | 19396 -> 19338 |  |
| largest-eigenval | 89 | 1 | 通过 | 83 | 2 | 19444 -> 19491 |  |
| llm-inference-batching-scheduler | 49 | 1 | 通过 | 393 | 3 | 19474 -> 19545 |  |
| log-summary-date-ranges | 50 | 1 | 通过 | 26 | 4 | 19502 -> 19558 |  |
| mailman | 166 | - | lost（无心跳） | - | - | - -> - | sandbox gone: no heartbeat since 2026-09-28T16:44:30Z, last phase agent |
| make-doom-for-mips | 209 | - | 提交失败 | - | - | - -> - | agent install failed (exit 127): |
| make-mips-interpreter | 526 | - | 提交失败 | - | - | - -> - | agent install failed (exit 127): |
| mcmc-sampling-stan | 240 | 1 | 通过 | 727 | 158 | 18846 -> 17855 |  |
| merge-diff-arc-agi-task | 60 | 1 | 通过 | 173 | 5 | 19506 -> 19279 |  |
| model-extraction-relu-logits | 88 | 1 | 通过 | 124 | 4 | 19329 -> 19336 |  |
| modernize-scientific-stack | 350 | 1 | 通过 | 18 | 5 | 18219 -> 17887 |  |
| mteb-leaderboard | 8824 | - | 镜像超过上限 | - | - | - -> - | image is 8824 MB compressed, over max_image_mb=2000; see docs/large-images.md |
| mteb-retrieve | 8814 | - | 镜像超过上限 | - | - | - -> - | image is 8814 MB compressed, over max_image_mb=2000; see docs/large-images.md |
| multi-source-data-merger | 228 | 1 | 通过 | 68 | 5 | 18874 -> 18589 |  |
| nginx-request-logging | 70 | 0 | 端口 8080 被占用 | 544 | 5 | 19373 -> 19473 |  |
| openssl-selfsigned-cert | 49 | 1 | 通过 | 32 | 4 | 19391 -> 19556 |  |
| overfull-hbox | 139 | 1 | 通过 | 221 | 28 | 19126 -> 18937 |  |
| password-recovery | 65 | 1 | 通过 | 167 | 7 | 19355 -> 19256 |  |
| path-tracing | 402 | - | lost（无心跳） | - | - | - -> - | sandbox gone: no heartbeat since 2026-09-28T16:54:40Z, last phase agent |
| path-tracing-reverse | 173 | - | lost（无心跳） | - | - | - -> - | sandbox gone: no heartbeat since 2026-09-28T16:54:50Z, last phase agent |
| polyglot-c-py | 156 | 1 | 通过 | 169 | 5 | 19216 -> 19008 |  |
| polyglot-rust-c | 278 | 1 | 通过 | 845 | 6 | 18701 -> 18461 |  |
| portfolio-optimization | 200 | 1 | 通过 | 259 | 50 | 18849 -> 18892 |  |
| protein-assembly | 49 | 0 | agent 解题失败 | 545 | 4 | 19445 -> 19444 |  |
| prove-plus-comm | 496 | 1 | 通过 | 24 | 6 | 17899 -> 17685 |  |
| pypi-server | 86 | 1 | 通过 | 196 | 4 | 19290 -> 19389 |  |
| pytorch-model-cli | 220 | - | lost（无心跳） | - | - | - -> - | sandbox gone: no heartbeat since 2026-09-28T16:47:07Z, last phase agent |
| pytorch-model-recovery | 6108 | - | 镜像超过上限 | - | - | - -> - | image is 6108 MB compressed, over max_image_mb=2000; see docs/large-images.md |
| query-optimize | 123 | 0 | agent 解题失败 | 276 | 357 | 19365 -> 19233 |  |
| raman-fitting | 49 | 1 | 通过 | 352 | 3 | 19394 -> 19158 |  |
| regex-chess | 60 | - | lost（无心跳） | - | - | - -> - | sandbox gone: no heartbeat since 2026-09-28T17:04:52Z, last phase agent |
| regex-log | 37 | 1 | 通过 | 149 | 6 | 19584 -> 19380 |  |
| reshard-c4-data | 1437 | 1 | 通过 | 272 | 33 | 15614 -> 13540 |  |
| rstan-to-pystan | 56 | 0 | 缺少 capability | 778 | 6 | 19379 -> 16309 |  |
| sam-cell-seg | 485 | 0 | agent 解题失败 | 450 | 21 | 17881 -> 7679 |  |
| sanitize-git-repo | 206 | 1 | 通过 | 97 | 4 | 19130 -> 19162 |  |
| sparql-university | 37 | 1 | 通过 | 189 | 9 | 19492 -> 19109 |  |
| sqlite-db-truncate | 49 | 1 | 通过 | 106 | 4 | 19556 -> 19554 |  |
| sqlite-with-gcov | 50 | 1 | 通过 | 244 | 4 | 19586 -> 18843 |  |
| torch-pipeline-parallelism | 37 | 1 | 通过 | 256 | 54 | 19561 -> 14077 |  |
| torch-tensor-parallelism | 37 | 1 | 通过 | 75 | 49 | 19475 -> 14281 |  |
| train-fasttext | 514 | - | lost（无心跳） | - | - | - -> - | sandbox gone: no heartbeat since 2026-09-28T17:00:33Z, last phase agent |
| tune-mjcf | 85 | 1 | 通过 | 523 | 19 | 19367 -> 19268 |  |
| video-processing | 317 | 0 | agent 解题失败 | 330 | 8 | 18711 -> 18420 |  |
| vulnerable-secret | 138 | 1 | 通过 | 88 | 3 | 19162 -> 19207 |  |
