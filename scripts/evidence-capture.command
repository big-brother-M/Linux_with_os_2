#!/bin/zsh
set -euo pipefail

project_root="$(cd "$(dirname "${0:A}")/.." && pwd)"

if [[ $# -gt 0 ]]; then
  cases=("$@")
else
  cases=(oom-before oom-after cpu-before cpu-after deadlock-before deadlock-after)
fi

cd "$project_root"

for case_name in "${cases[@]}"; do
  printf '\033]0;B1-2 Evidence - %s\007' "$case_name"
  clear
  printf '\033[1;32m$ ./scripts/show-report-evidence.sh %s\033[0m\n' "$case_name"
  ./scripts/show-report-evidence.sh "$case_name"
  printf '\n\033[1;32m[CAPTURE READY — source files were read without modification]\033[0m\n'
  printf '%s\n' "$case_name" > /tmp/b1-2-current-case
  sleep 15
done

rm -f /tmp/b1-2-current-case
printf '\nAll six evidence views completed.\n'
sleep 60
