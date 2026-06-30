#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <pid> [interval_seconds]" >&2
  exit 64
fi

pid="$1"
interval="${2:-1}"
thread_log="${THREAD_LOG:-}"
top_log="${TOP_LOG:-}"

printf 'timestamp,pid,stat,cpu_percent,mem_percent,rss_kb,vsz_kb,nlwp,command\n'

while kill -0 "$pid" 2>/dev/null; do
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  proc_line="$(ps -p "$pid" -o pid=,stat=,pcpu=,pmem=,rss=,vsz=,nlwp=,comm= || true)"

  if [[ -z "${proc_line// }" ]]; then
    break
  fi

  echo "$proc_line" | awk -v ts="$ts" '{
    command=$8
    for (i = 9; i <= NF; i++) {
      command = command " " $i
    }
    printf "%s,%s,%s,%s,%s,%s,%s,%s,%s\n", ts, $1, $2, $3, $4, $5, $6, $7, command
  }'

  if [[ -n "$thread_log" ]]; then
    {
      echo "[$ts]"
      ps -L -p "$pid" -o pid,tid,stat,pcpu,pmem,comm || true
      echo
    } >> "$thread_log"
  fi

  if [[ -n "$top_log" ]]; then
    {
      echo "[$ts]"
      top -b -n 1 -p "$pid" | sed -n '1,20p' || true
      echo
    } >> "$top_log"
  fi

  sleep "$interval"
done
