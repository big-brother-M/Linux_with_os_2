#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 {oom-before|oom-after|cpu-before|cpu-after|deadlock-before|deadlock-after}" >&2
  exit 64
fi

case_name="$1"

case "$case_name" in
  oom-before)       evidence_dir="evidence/oom-before/20260604-062049" ;;
  oom-after)        evidence_dir="evidence/oom-after/20260604-061950" ;;
  cpu-before)       evidence_dir="evidence/cpu-before/20260604-062432" ;;
  cpu-after)        evidence_dir="evidence/cpu-after/20260604-062541" ;;
  deadlock-before)  evidence_dir="evidence/deadlock-before/20260604-062841" ;;
  deadlock-after)   evidence_dir="evidence/deadlock-after/20260604-063035" ;;
  *)
    echo "unknown case: $case_name" >&2
    exit 64
    ;;
esac

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

case_label="$(printf '%s' "$case_name" | tr '[:lower:]' '[:upper:]')"
printf '\033[1;36m=== %s | ORIGINAL TERMINAL EVIDENCE ===\033[0m\n' "$case_label"
printf 'SOURCE: %s\n\n' "$evidence_dir"

printf '\033[1;33m[RUN ENVIRONMENT]\033[0m\n'
grep -E '^(CASE_NAME|STARTED_AT|MEMORY_LIMIT|CPU_MAX_OCCUPY|MULTI_THREAD_ENABLE|APP_PID)=' "$evidence_dir/run.env"

printf '\n\033[1;33m[PROCESS MONITOR: timestamp, PID, state, CPU, MEM, RSS]\033[0m\n'
case "$case_name" in
  oom-before)
    cat "$evidence_dir/monitor.csv"
    ;;
  oom-after)
    awk -F, 'NR == 1 { print; next } $6 != previous_rss { print; previous_rss=$6 }' "$evidence_dir/monitor.csv"
    ;;
  *)
    { head -n 2 "$evidence_dir/monitor.csv"; tail -n 1 "$evidence_dir/monitor.csv"; }
    ;;
esac

printf '\n\033[1;33m[APPLICATION LOG]\033[0m\n'
case "$case_name" in
  oom-before|oom-after)
    grep -E 'Current Heap|Memory limit exceeded|Self-terminating|^Killed$' "$evidence_dir/app.log"
    ;;
  cpu-before)
    grep -E 'Started\. Maximum CPU|Current Load|CPU Threshold Violated|^Terminated$' "$evidence_dir/app.log"
    ;;
  cpu-after)
    grep -E 'Started\. Maximum CPU|Peak reached|Cooldown complete|^Terminated$' "$evidence_dir/app.log" |
      awk 'NR <= 4 { print; next } { previous=last; last=$0 } END { if (previous != "") print previous; if (last != "") print last }'
    ;;
  deadlock-before)
    grep -E 'Concurrency:|LOCK ACQUIRED|Need resource|WAITING' "$evidence_dir/app.log"
    ;;
  deadlock-after)
    grep -E 'Concurrency:|Task Scheduler Initialized|All tasks completed|^Terminated$' "$evidence_dir/app.log"
    ;;
esac

if [[ "$case_name" == deadlock-before ]]; then
  printf '\n\033[1;33m[PROCESS SNAPSHOT AT 90s]\033[0m\n'
  grep -E '^\[|^ *38 +33|^38 +38|^38 +120|^38 +121' "$evidence_dir/process_snapshot.txt"
fi

printf '\n\033[1;33m[RESULT]\033[0m\n'
cat "$evidence_dir/result.env"
