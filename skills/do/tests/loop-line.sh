#!/usr/bin/env bash
# loop-line.sh: the contract of scripts/loop-line.sh, the loop line a ticket run quotes as Reply item
# 4 and copies as the Builder's `Loop:` key, printed off the door's loop= line and whether the
# session holds the Agent tool.
# Run: bash skills/do/tests/loop-line.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/loop-line.sh"
fails=0

run() {
  rc=0
  # shellcheck disable=SC2034  # lib.sh's same reads $out
  out="$(bash "$script" "$@" 2>&1)" || rc=$?
}

for word in policy fallback; do
  for agent in available withheld; do
    run "loop=$word" "agent=$agent"
    same "loop-line.sh prints Loop: $word for loop=$word with the Agent tool $agent" "Loop: $word"
    [ "$rc" = 0 ] || fail "loop=$word agent=$agent exits 0 (exit $rc)"
  done
done

[ "$fails" = 0 ]
