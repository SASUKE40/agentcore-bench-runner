#!/usr/bin/env bash
# microVM mode: build the task image for arm64 from the task's own environment/ directory
# (Dockerfile used as-is), add the adapter "tools" stage (static busybox, curl if missing;
# same template for every task) and push to ECR. Run on an arm64 host, e.g. Graviton EC2.
#
#   scripts/build_microvm.sh <task-dir> <ecr-repo-uri>     # pushes <ecr-repo-uri>:arm64
set -euo pipefail
TASK_DIR=${1:?task dir}
REPO=${2:?ecr repo uri}
TAG=${TAG:-arm64}
HERE=$(cd "$(dirname "$0")/.." && pwd)

REGISTRY=${REPO%%/*}
REGION=$(echo "$REGISTRY" | cut -d. -f4)
aws ecr get-login-password --region "$REGION" | docker login -u AWS --password-stdin "$REGISTRY" >/dev/null 2>&1 \
    || echo "docker login skipped (a credential helper may already be configured)"
docker build --platform linux/arm64 -t "$REPO:$TAG-task" "$TASK_DIR/environment"
docker build --platform linux/arm64 --target tools --build-arg BASE="$REPO:$TAG-task" \
    --build-arg APT_PACKAGES="${APT_PACKAGES:-}" -t "$REPO:$TAG" "$HERE/adapter"
docker push "$REPO:$TAG"
