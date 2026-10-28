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

run loop=global agent=available
same "loop-line.sh prints Loop: global and a line naming global-unit-test-author as the unit author for loop=global with the Agent tool available" \
  "Loop: global
Unit test author: global-unit-test-author"

run loop=global agent=withheld
same "loop-line.sh prints Loop: fallback and a line saying the Agent tool is withheld, so the run writes every unit test itself and authors the flow itself, for loop=global with the Agent tool withheld" \
  "Loop: fallback
Agent tool withheld: the run writes every unit test itself, red first, and authors the flow itself"

# The ticket Playbook's step 0 quotes what the script prints and keeps no mapping of its own, so the
# rule has one home and the prose cannot drift from it.
bullet="$(passage_of "$here/../references/ticket.md" "- The loop line" "- " | tr '\n' ' ' | tr -s ' ')"
expect "ticket.md step 0 carries its loop line bullet" test -n "$bullet"
expect "the ticket Playbook's step 0 takes its loop line from loop-line.sh off the door's loop= line" \
  grep -qF "scripts/loop-line.sh <the door's loop= line>" <<<"$bullet"
if grep -qE '`Loop: (policy|global|fallback)` (when|otherwise)|reads `Loop: fallback` instead' <<<"$bullet"; then
  fail "ticket.md states the loop line mapping as prose no more"
else ok "ticket.md states the loop line mapping as prose no more"; fi

[ "$fails" = 0 ]
