#!/usr/bin/env bash
# stretch-budget.sh: the contract of scripts/stretch-budget.sh, the verdict the Builder reads after
# each behaviour's commit to know whether its Stretch goes on or returns.
# Run: bash skills/do/tests/stretch-budget.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/stretch-budget.sh"
fails=0

run() { # $1.. the script's arguments: its stdout in $out, its exit in $rc
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines reads $out
  out="$(bash "$script" "$@" 2>/dev/null)" || rc=$?
}

began=1700000000

run "$began" "$((began + 40 * 60 - 1))"
check_lines "a Stretch that began one second less than 40 minutes ago continues" 0 "$rc" \
  "stretch=continue"

run "$began" "$((began + 40 * 60))"
check_lines "a Stretch that began exactly 40 minutes ago stops" 0 "$rc" \
  "stretch=stop"

run "$began" "$((began + 40 * 60 + 1))"
check_lines "a Stretch that began more than 40 minutes ago stops" 0 "$rc" \
  "stretch=stop"

exit "$((fails > 0))"
