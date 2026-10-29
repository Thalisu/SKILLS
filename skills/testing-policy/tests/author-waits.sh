#!/usr/bin/env bash
# author-waits.sh: a test author waits on a command the harness moved to the background in short,
# bounded calls, and reports it as not returned when it never comes back.
# Test authors run as background subagents, so a Bash call longer than a few minutes (the unit
# author's full suite on a promotion, the e2e author's flows against a live stack) comes back moved
# to the background whatever its timeout. With no rule the author improvises sleeps or a poll,
# outlives the bounded wait of the Fixer, the PR fixer or the Builder that dispatched it, and that
# caller restores the work and drops the Finding or the behaviour.
# The rule is prose in the agent core every install renders, so it is proven over the list item of
# that core that carries it: the core is a list, and one item is the unit a reader acts on.
# Run: bash skills/testing-policy/tests/author-waits.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
render="$here/../scripts/render-agent.sh"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mapfile -t loop_terms < <(own_loop_phrasings)
wait_cmd="timeout 60 tail -f /dev/null"
marker='- |[0-9]+\. '

for kind in unit e2e; do
  core="$tmp/core-$kind.md"
  bash "$render" "$kind" --core-only >"$core"

  echo "# $kind core: a command moved to the background is waited on in short calls, one at a time"
  wait_item="$(item_holding "$core" "$marker" "$wait_cmd" | tr '\n' ' ' | tr -s ' ')"
  flat="$wait_item"
  expect "the $kind core has a list item giving the wait \`$wait_cmd\`" test -n "$flat"
  carries_each "it says the harness moves a Bash call to the background after a few minutes, whatever its timeout" \
    "Bash" -- \
    "minute" -- \
    "whatever its \`timeout\`" "whatever its timeout" "whatever the call's \`timeout\`" "whatever the call's timeout" \
    "regardless of its timeout" "regardless of its \`timeout\`" "regardless of the call's timeout" -- \
    "to the background"
  expect "the wait item never claims a long Bash timeout keeps the wait in the foreground" \
    bash -c '! grep -qF "never moves the wait" <<<"$1"' _ "$wait_item"
  carries_any "the wait calls run one at a time" \
    "one at a time" "one after the other" "one after another" "in sequence"

  # A notification reaches the author only once its current tool call ends, which is why each wait
  # call is short: one long call holds the notification back for as long as it runs.
  echo "# $kind core: a command moved to the background reaches the author as a notification once its current call ends"
  flat="$(item_holding "$core" "$marker" "notification" | tr '\n' ' ' | tr -s ' ')"
  expect "the $kind core has a list item on the notification of a command moved to the background" \
    bash -c 'grep -qF "background" <<<"$1"' _ "$flat"
  carries_each "the notification arrives once the author's current call ends" \
    "command" -- \
    "notification" -- \
    "call ends" "call returns" "call finishes" "call is over" "between calls" "call has ended"

  # The caller reads the author's report once it returns, inside its own bound: a report that names
  # the command as not returned is one it can route, a wait that outlives the bound is not.
  echo "# $kind core: after nine wait calls with no notification, the author reports the command as not returned"
  flat="$wait_item"
  carries_each "after nine wait calls with no notification it reports the command as not returned, naming it, in place of its output" \
    "nine" -- \
    "no notification" "without a notification" "no result" "without a result" -- \
    "not returned" "has not returned" "did not return" "never returned" -- \
    "naming it" "naming the command" "names the command" "naming that command" "names it" -- \
    "in place of its output" "instead of its output" "in place of the output" "instead of the output" "where its output would be" -- \
    "report" "Report"
  carries_any "it reports instead of waiting longer" \
    "instead of waiting" "rather than waiting" "rather than wait" "stop waiting" "stops waiting" \
    "never wait longer" "not wait longer" "no longer"

  # The sanctioned wait is itself a `tail -f`, so it is masked before the ban is looked for, and with no
  # `wait` in the mask, since an imperative "wait ..., never with a loop" carries the ban: the line
  # telling the author to run it never answers for the ban on a loop or poll of its own.
  echo "# $kind core: the author never waits with a loop or poll of its own"
  flat="${wait_item//"$wait_cmd"/the bounded call}"
  subject_denies "it forbids the author a wait loop or a poll of its own" "You|you|author|Wait|wait" "${loop_terms[@]}"
done

[ "$fails" -eq 0 ] && exit 0
exit 1
