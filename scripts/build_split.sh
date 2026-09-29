#!/usr/bin/env bash
# Split build for images over the size limit (Runtime Instances mode).
#
# Moves the given directories out of the task's original image into S3 (one .tar.gz each),
# builds a slim image without them, and wraps it with adapter/ like build_instances.sh.
# The slim image carries /etc/bench/restore.list; trial.sh restores every listed archive
# to its original path before the agent starts, so the task sees the original filesystem.
#
#   scripts/build_split.sh <original-image> <ecr-repo-uri> <s3-prefix> <path> [<path> ...]
#   e.g. scripts/build_split.sh <acct>.dkr.ecr.us-east-1.amazonaws.com/tbs/gen-turan-paths:latest \
#          <acct>.dkr.ecr.us-east-1.amazonaws.com/bench/gen-turan-paths \
#          s3://<results-bucket>/<results-prefix>/images/gen-turan-paths /root/project /root/.elan
#
# <s3-prefix> must be in the results bucket, under <results-prefix>/images/ (the execution
# role policy grants read there). Pushes <ecr-repo-uri>:split. Finding the large directories:
#   docker run --rm --entrypoint sh <original-image> -c 'du -xsh /* /root/* /opt/* 2>/dev/null | sort -rh | head'
set -euo pipefail
BASE=${1:?original image}; REPO=${2:?ecr repo uri}; S3=${3:?s3 prefix}; shift 3
[ $# -gt 0 ] || { echo "give at least one path to move out" >&2; exit 2; }
S3=${S3%/}
TAG=${TAG:-split}
PLATFORM=${PLATFORM:-linux/amd64}
HERE=$(cd "$(dirname "$0")/.." && pwd)
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT

REGISTRY=${REPO%%/*}
REGION=$(echo "$REGISTRY" | cut -d. -f4)
aws ecr get-login-password --region "$REGION" | docker login -u AWS --password-stdin "$REGISTRY" >/dev/null 2>&1 \
    || echo "docker login skipped (a credential helper may already be configured)"
docker pull -q --platform "$PLATFORM" "$BASE" >/dev/null

# 1. Each path -> one gzip tarball in S3 (streamed, nothing staged on local disk).
: > "$WORK/restore.list"
for p in "$@"; do
  rel=${p#/}; rel=${rel%/}
  key="$S3/$(echo "$rel" | tr '/' '_').tar.gz"
  echo "uploading /$rel -> $key"
  docker run --rm --platform "$PLATFORM" --entrypoint tar "$BASE" -C / -czf - "$rel" \
    | aws s3 cp - "$key" --only-show-errors
  echo "$key" >> "$WORK/restore.list"
done

# 2. Slim image: the original filesystem minus those paths, flattened so the removed
#    content is really gone, with the original ENV / WORKDIR / USER carried over.
docker image inspect --format '{{json .Config}}' "$BASE" > "$WORK/config.json"
python3 - "$WORK" "$BASE" "$@" <<'EOF'
import json, sys
work, base, paths = sys.argv[1], sys.argv[2], sys.argv[3:]
c = json.load(open(f"{work}/config.json"))
lines = [f"FROM {base} AS full", "RUN rm -rf " + " ".join(json.dumps(p) for p in paths),
         "FROM scratch", "COPY --from=full / /"]
lines += [f"ENV {e.split('=', 1)[0]}={json.dumps(e.split('=', 1)[1])}" for e in c.get("Env") or []]
if c.get("WorkingDir"):
    lines.append(f"WORKDIR {c['WorkingDir']}")
if c.get("User"):
    lines.append(f"USER {c['User']}")
if c.get("Cmd"):
    lines.append("CMD " + json.dumps(c["Cmd"]))
lines.append("COPY restore.list /etc/bench/restore.list")
open(f"{work}/Dockerfile", "w").write("\n".join(lines) + "\n")
EOF
docker build -q --platform "$PLATFORM" -t "$REPO:slim-base" "$WORK" >/dev/null

# 3. Same adapter template as every other Instances image.
TAG=$TAG PLATFORM=$PLATFORM "$HERE/scripts/build_instances.sh" "$REPO:slim-base" "$REPO"
echo "restore list:"; cat "$WORK/restore.list"
