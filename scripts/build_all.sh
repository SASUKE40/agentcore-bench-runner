#!/usr/bin/env bash
# Build and push images for many Harbor tasks with the same template -- no per-task options.
#
#   scripts/build_all.sh microvm   <ecr-registry> <task-dir>...   # run on an arm64 host
#   scripts/build_all.sh instances <ecr-registry> <task-dir>...   # run on an x86_64 host
#
# Each task goes to <ecr-registry>/bench/<task>:<mode tag> (repositories are created if
# missing). A task that fails to build is recorded and skipped; the loop continues.
# Output: build-<mode>.tsv with  task  status  seconds  compressed_MB  image
set -uo pipefail
MODE=${1:?microvm|instances}
REGISTRY=${2:?ecr registry, e.g. 123456789012.dkr.ecr.us-east-2.amazonaws.com}
shift 2
HERE=$(cd "$(dirname "$0")" && pwd)
REGION=$(echo "$REGISTRY" | cut -d. -f4)
OUT=${OUT:-build-$MODE.tsv}
case $MODE in microvm) TAG=arm64 ;; instances) TAG=instances ;; *) echo "bad mode $MODE" >&2; exit 2 ;; esac

aws ecr get-login-password --region "$REGION" | docker login -u AWS --password-stdin "$REGISTRY" >/dev/null 2>&1 \
    || echo "docker login skipped (a credential helper may already be configured)"
test_packages() {  # package names from "apt-get install ..." / "apt install ..." lines
  [ -f "$1" ] || return 0
  grep -oE 'apt(-get)?[[:space:]]+install[^;&|]*' "$1" \
    | sed -E 's/apt(-get)?[[:space:]]+install//' | tr ' \t' '\n\n' \
    | grep -E '^[a-z0-9][a-z0-9.+:=~-]*$' | grep -v '^-' | sort -u | tr '\n' ' '
}
: > "$OUT"
for dir in "$@"; do
  task=$(basename "$dir")
  repo="$REGISTRY/bench/$task"
  aws ecr describe-repositories --region "$REGION" --repository-names "bench/$task" >/dev/null 2>&1 \
    || aws ecr create-repository --region "$REGION" --repository-name "bench/$task" >/dev/null
  # Packages the task's grading script apt-installs are installed at build time instead
  # (Instances has no Linux capabilities, so apt/dpkg fail at run time).
  pkgs=$(test_packages "$dir/tests/test.sh")
  t0=$(date +%s)
  if [ "$MODE" = microvm ]; then
    APT_PACKAGES=$pkgs TAG=$TAG "$HERE/build_microvm.sh" "$dir" "$repo" > "build-$MODE-$task.log" 2>&1
  else
    base=$(sed -n 's/^[[:space:]]*docker_image[[:space:]]*=[[:space:]]*"\(.*\)".*/\1/p' "$dir/task.toml" | head -1)
    if [ -z "$base" ]; then
      printf '%s\tno-docker_image\t0\t-\t-\n' "$task" | tee -a "$OUT"; continue
    fi
    APT_PACKAGES=$pkgs TAG=$TAG "$HERE/build_instances.sh" "$base" "$repo" > "build-$MODE-$task.log" 2>&1
  fi
  rc=$?
  secs=$(( $(date +%s) - t0 ))
  if [ $rc -ne 0 ]; then
    printf '%s\tbuild-failed\t%s\t-\t%s\n' "$task" "$secs" "build-$MODE-$task.log" | tee -a "$OUT"; continue
  fi
  bytes=$(aws ecr describe-images --region "$REGION" --repository-name "bench/$task" \
          --image-ids imageTag=$TAG --query 'imageDetails[0].imageSizeInBytes' --output text 2>/dev/null)
  printf '%s\tok\t%s\t%s\t%s\n' "$task" "$secs" "$(( ${bytes:-0} / 1000000 ))" "$repo:$TAG" | tee -a "$OUT"
done
