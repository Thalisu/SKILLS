#!/usr/bin/env bash
# group-waves.sh: the contract of scripts/group-waves.sh, the Waves the pr Playbook and the fix run
# fork on, every number of a Wave line at once.
# Run: bash skills/do-code-review/tests/group-waves.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/group-waves.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

run() { # stdin the number records: the script's output in $out, its exit in $rc
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines and same read $out
  out="$(cd "$tmp" && bash "$script" 2>&1)" || rc=$?
}

run < <(printf '3\tsrc/a.ts src/a.test.ts\n5\tdocs/x.md\n')
check_lines "two numbers whose file sets are non-empty and disjoint come back on one Wave" 0 "$rc" \
  "wave=1 numbers=3,5"
same "two numbers that cannot collide are never split across Waves" "wave=1 numbers=3,5"

run < <(printf '3\tsrc/a.ts src/a.test.ts\n5\tsrc/b.ts src/a.ts\n')
same "two numbers whose file sets share a file come back on two separate Waves" \
  "wave=1 numbers=3"$'\n'"wave=2 numbers=5"
check_lines "two numbers sharing a file still exit 0" 0 "$rc" "wave=1 numbers=3" "wave=2 numbers=5"

echo
if [ "$fails" = 0 ]; then echo "group-waves: all checks passed"; else
  echo "group-waves: $fails failed"
  exit 1
fi
