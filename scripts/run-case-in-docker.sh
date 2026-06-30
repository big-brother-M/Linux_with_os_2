#!/usr/bin/env bash
set -euo pipefail

case_name="${1:-}"
if [[ -z "$case_name" ]]; then
  echo "usage: $0 <oom-before|oom-after|cpu-before|cpu-after|deadlock-before|deadlock-after|scheduling>" >&2
  exit 64
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd "$script_dir/.." && pwd)"
image="${B1_2_DOCKER_IMAGE:-ubuntu:24.04}"

docker run --rm \
  --platform linux/arm64 \
  --env MEMORY_LIMIT \
  --env CPU_MAX_OCCUPY \
  --env MULTI_THREAD_ENABLE \
  --env RUN_SECONDS \
  --volume "$project_dir:/work" \
  --workdir /work \
  "$image" \
  bash /work/scripts/run-case.sh "$case_name"
