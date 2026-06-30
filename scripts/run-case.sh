#!/usr/bin/env bash
set -euo pipefail

case_name="${1:-}"
if [[ -z "$case_name" ]]; then
  echo "usage: $0 <oom-before|oom-after|cpu-before|cpu-after|deadlock-before|deadlock-after|scheduling>" >&2
  exit 64
fi

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "run-case.sh must run inside Linux. Use scripts/run-case-in-docker.sh from macOS." >&2
  exit 65
fi

if [[ "$(id -u)" -ne 0 ]]; then
  echo "run-case.sh needs root inside the container to install procps and create a non-root user." >&2
  exit 66
fi

if ! command -v ps >/dev/null 2>&1 || ! command -v top >/dev/null 2>&1 || ! command -v pgrep >/dev/null 2>&1; then
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y procps
fi

if ! id -u agent >/dev/null 2>&1; then
  useradd -m -s /bin/bash agent
fi

arch="$(uname -m)"
case "$arch" in
  aarch64|arm64)
    agent_bin="/work/agent-app-leak/agent-leak-app-arm64"
    ;;
  x86_64|amd64)
    agent_bin="/work/agent-app-leak/agent-leak-app-x86"
    ;;
  *)
    echo "unsupported container architecture: $arch" >&2
    exit 67
    ;;
esac

if [[ ! -x "$agent_bin" ]]; then
  chmod +x "$agent_bin"
fi

case "$case_name" in
  oom-before)
    default_memory_limit=50
    default_cpu_max=100
    default_multi_thread=false
    default_run_seconds=160
    ;;
  oom-after)
    default_memory_limit=128
    default_cpu_max=100
    default_multi_thread=false
    default_run_seconds=160
    ;;
  cpu-before)
    default_memory_limit=512
    default_cpu_max=100
    default_multi_thread=false
    default_run_seconds=160
    ;;
  cpu-after)
    default_memory_limit=512
    default_cpu_max=10
    default_multi_thread=false
    default_run_seconds=90
    ;;
  deadlock-before)
    default_memory_limit=512
    default_cpu_max=10
    default_multi_thread=true
    default_run_seconds=90
    ;;
  deadlock-after)
    default_memory_limit=512
    default_cpu_max=10
    default_multi_thread=false
    default_run_seconds=90
    ;;
  scheduling)
    default_memory_limit=512
    default_cpu_max=100
    default_multi_thread=true
    default_run_seconds=45
    ;;
  *)
    echo "unknown case: $case_name" >&2
    exit 64
    ;;
esac

memory_limit="${MEMORY_LIMIT:-$default_memory_limit}"
cpu_max="${CPU_MAX_OCCUPY:-$default_cpu_max}"
multi_thread="${MULTI_THREAD_ENABLE:-$default_multi_thread}"
run_seconds="${RUN_SECONDS:-$default_run_seconds}"
timestamp="$(date '+%Y%m%d-%H%M%S')"
evidence_dir="/work/evidence/$case_name/$timestamp"
runtime_dir="/tmp/b1-2-agent-$case_name-$timestamp"

mkdir -p "$evidence_dir"
mkdir -p "$runtime_dir/upload_files" "$runtime_dir/api_keys" "$runtime_dir/logs"
printf 'agent_api_key_test' > "$runtime_dir/api_keys/secret.key"
chown -R agent:agent "$runtime_dir"

cat > "$evidence_dir/run.env" <<EOF
CASE_NAME=$case_name
STARTED_AT=$timestamp
CONTAINER_ARCH=$arch
AGENT_BIN=$agent_bin
AGENT_HOME=$runtime_dir
AGENT_PORT=15034
AGENT_UPLOAD_DIR=$runtime_dir/upload_files
AGENT_KEY_PATH=$runtime_dir/api_keys
AGENT_LOG_DIR=$runtime_dir/logs
MEMORY_LIMIT=$memory_limit
CPU_MAX_OCCUPY=$cpu_max
MULTI_THREAD_ENABLE=$multi_thread
RUN_SECONDS=$run_seconds
EOF

runuser -u agent -- env \
  AGENT_HOME="$runtime_dir" \
  AGENT_PORT=15034 \
  AGENT_UPLOAD_DIR="$runtime_dir/upload_files" \
  AGENT_KEY_PATH="$runtime_dir/api_keys" \
  AGENT_LOG_DIR="$runtime_dir/logs" \
  MEMORY_LIMIT="$memory_limit" \
  CPU_MAX_OCCUPY="$cpu_max" \
  MULTI_THREAD_ENABLE="$multi_thread" \
  "$agent_bin" > "$evidence_dir/app.log" 2>&1 &

launcher_pid="$!"
app_pid=""
for _ in $(seq 1 40); do
  candidate_pids="$(pgrep -u agent -f "$agent_bin" | sort -n || true)"
  candidate_count="$(printf '%s\n' "$candidate_pids" | sed '/^$/d' | wc -l)"
  app_pid="$(printf '%s\n' "$candidate_pids" | sed '/^$/d' | tail -n 1)"
  if [[ "$candidate_count" -ge 2 ]]; then
    break
  fi
  if ! kill -0 "$launcher_pid" 2>/dev/null; then
    break
  fi
  sleep 0.5
done

if [[ -z "$app_pid" ]]; then
  set +e
  wait "$launcher_pid"
  exit_code="$?"
  set -e
  printf 'STATE=exited_before_monitor\nEXIT_CODE=%s\n' "$exit_code" > "$evidence_dir/result.env"
  cp -a "$runtime_dir/logs" "$evidence_dir/agent_log_dir" 2>/dev/null || true
  echo "case $case_name finished before monitor could attach: $evidence_dir"
  exit 0
fi

printf 'LAUNCHER_PID=%s\nAPP_PID=%s\n' "$launcher_pid" "$app_pid" >> "$evidence_dir/run.env"

THREAD_LOG="$evidence_dir/threads.log" TOP_LOG="$evidence_dir/top.log" \
  /work/monitor.sh "$app_pid" 1 > "$evidence_dir/monitor.csv" &
monitor_pid="$!"

start_epoch="$(date +%s)"
state="running_after_timeout"

while kill -0 "$app_pid" 2>/dev/null; do
  now_epoch="$(date +%s)"
  elapsed=$((now_epoch - start_epoch))
  if (( elapsed >= run_seconds )); then
    break
  fi
  sleep 1
done

if ! kill -0 "$app_pid" 2>/dev/null; then
  state="exited"
fi

{
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] process snapshot"
  ps -ef | grep -E 'agent-leak-app|PID' | grep -v grep || true
  echo
  ps -p "$app_pid" -o pid,ppid,stat,pcpu,pmem,rss,vsz,nlwp,etime,comm || true
  echo
  ps -L -p "$app_pid" -o pid,tid,stat,pcpu,pmem,comm || true
} > "$evidence_dir/process_snapshot.txt"

if [[ "$state" == "running_after_timeout" ]]; then
  kill -TERM "$app_pid" 2>/dev/null || true
  sleep 2
  kill -KILL "$app_pid" 2>/dev/null || true
fi

kill "$monitor_pid" 2>/dev/null || true
set +e
wait "$monitor_pid" 2>/dev/null
monitor_exit="$?"
wait "$launcher_pid" 2>/dev/null
launcher_exit="$?"
set -e

cp -a "$runtime_dir/logs" "$evidence_dir/agent_log_dir" 2>/dev/null || true

cat > "$evidence_dir/result.env" <<EOF
STATE=$state
LAUNCHER_EXIT=$launcher_exit
MONITOR_EXIT=$monitor_exit
ENDED_AT=$(date '+%Y%m%d-%H%M%S')
EOF

echo "case $case_name finished: $evidence_dir"
