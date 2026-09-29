#!/usr/bin/env bash
# Runtime Instances mode: wrap the task's original image with adapter/ (same template for
# every task) and push to ECR. <original-image> is the task's [environment].docker_image.
#
#   scripts/build_instances.sh <original-image> <ecr-repo-uri>   # pushes <ecr-repo-uri>:instances
#   e.g. scripts/build_instances.sh alexgshaw/fix-git:20251031 <acct>.dkr.ecr.<region>.amazonaws.com/bench/fix-git
set -euo pipefail
BASE=${1:?original image}
REPO=${2:?ecr repo uri}
TAG=${TAG:-instances}
PLATFORM=${PLATFORM:-linux/amd64}
HERE=$(cd "$(dirname "$0")/.." && pwd)

REGISTRY=${REPO%%/*}
REGION=$(echo "$REGISTRY" | cut -d. -f4)
aws ecr get-login-password --region "$REGION" | docker login -u AWS --password-stdin "$REGISTRY" >/dev/null 2>&1 \
    || echo "docker login skipped (a credential helper may already be configured)"
docker build --platform "$PLATFORM" --build-arg BASE="$BASE" \
    --build-arg APT_PACKAGES="${APT_PACKAGES:-}" -t "$REPO:$TAG" "$HERE/adapter"
docker push "$REPO:$TAG"
