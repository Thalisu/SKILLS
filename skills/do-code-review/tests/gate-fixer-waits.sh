#!/usr/bin/env bash
# gate-fixer-waits.sh: the do-code-review-gate-fixer fork waits on a command the harness moved to the
# background in short, bounded calls, and ends the attempt on its own stop line when it never returns.
# The Gate fixer runs as a background subagent, so a Gate or Diff-test run longer than a few minutes
# comes back moved to the background whatever the Bash call's timeout. With no rule it improvises
# long sleeps or a poll, outlives the orchestrator's bounded wait on its return file, and the fix
# run lands nothing. It has no Agent tool, so the only thing it waits on is a command.
# The wait and the ban are prose the fork follows, so they are proven over the paragraphs of its
# agent body that carry them, wherever they sit.
# Run: bash skills/do-code-review/tests/gate-fixer-waits.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
agent="$here/../agents/do-code-review-gate-fixer.md"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

body="$tmp/body.md"
body_of "$agent" >"$body"

mapfile -t loop_terms < <(own_loop_phrasings)
wait_cmd="timeout 60 tail -f /dev/null"

echo "# do-code-review-gate-fixer.md: a command moved to the background is waited on in short calls, bounded at nine"
wait_para="$(paragraph_with "$body" "$wait_cmd" | tr -s ' ')"
flat="$wait_para"
expect "the agent body has a paragraph giving the wait \`$wait_cmd\`" test -n "$flat"
carries_each "it says the harness moves a Bash call to the background after a few minutes, whatever the call's timeout" \
  "Bash" -- \
  "minute" -- \
  "whatever its \`timeout\`" "whatever its timeout" "whatever the call's \`timeout\`" "whatever the call's timeout" \
  "regardless of its timeout" "regardless of its \`timeout\`" "regardless of the call's timeout" -- \
  "to the background"
expect "the wait paragraph never claims a long Bash timeout keeps the wait in the foreground" \
  bash -c '! grep -qF "never moves the wait" <<<"$1"' _ "$wait_para"
carries_any "the wait calls run one at a time" \
  "one at a time" "one after the other" "one after another" "in sequence"
carries_each "the wait is repeated up to nine calls in all" \
  "nine" -- \
  "in all" "at most" "up to" "no more than"

# A notification reaches the fork only once its current tool call ends, which is why each wait call
# is short: one long call holds the notification back for as long as it runs.
echo "# do-code-review-gate-fixer.md: a command moved to the background reaches the fork as a notification once its current call ends"
flat="$(paragraphs_naming "notification" | grep -F "background" | head -n1)"
expect "the agent body has a paragraph on the notification of a command moved to the background" test -n "$flat"
carries_each "the notification arrives once the fork's current call ends" \
  "command" -- \
  "notification" -- \
  "call ends" "call returns" "call finishes" "call is over" "between calls" "call has ended"

# `not fixed:` is the line the orchestrator reads as an attempt that turned nothing green, and the
# Gate fixer's contract is one commit per attempt or none: any other end is a return it cannot route.
echo "# do-code-review-gate-fixer.md: when the ninth wait ends with no result, the attempt ends with no commit and a not fixed: line"
flat="$wait_para"
carries_each "after the ninth call with no result the fork restores its edits, makes no commit and writes not fixed: to its return file" \
  "no result" "without a result" "no notification" "without a notification" "has not returned" "did not return" "not returned" -- \
  "nine" -- \
  "restore" "Restore" -- \
  "no commit" "without a commit" "not commit" "never commit" -- \
  "not fixed:" -- \
  "return file" "Return file"
flat="$(awk '{ n = split($0, s, /\. /); for (i = 1; i <= n; i++) if (index(s[i], "not fixed:")) print s[i] }' <<<"$wait_para")"
carries_any "the not fixed line names the command that did not return" \
  "naming the command" "names the command" "naming that command" "names that command" "the command that" "command"

# The sanctioned wait is itself a `tail -f`, so it is masked before the ban is looked for: the line
# telling the fork to run it never answers for the ban on a loop or poll of its own.
echo "# do-code-review-gate-fixer.md: the fork never waits with a loop or poll of its own"
paras="$(paragraphs_naming "${loop_terms[@]}")"
flat="${paras//"$wait_cmd"/the bounded wait}"
expect "the fork's contract has a passage on waiting with a loop of its own" test -n "$paras"
subject_denies "it forbids the fork a wait loop or a poll of its own" "You|you|fork|Gate fixer" "${loop_terms[@]}"

# The orchestrator waits on the return file a bounded time and runs every Finding's check, the scan,
# the Diff tests and the Gate itself once the Gate fixer returns: a Gate fixer that re-ran the whole
# unit loop first outlived that wait, and its attempt landed nothing.
mapfile -t whole_suite < <(whole_suite_phrasings)
echo "# do-code-review-gate-fixer.md: the Gate fixer runs what its red block names and the test files the commits touch, never the whole unit suite or the Gate"
flat="$(paragraphs_naming "${whole_suite[@]}")"
expect "the agent body has a passage on the project's whole unit suite" test -n "$flat"
subject_denies "it forbids the Gate fixer running the whole unit suite or the Gate itself" "You|you|Gate fixer" "${whole_suite[@]}" "Gate"
affirms "it has the Gate fixer run what its red block names" \
  "run" "Run" -- \
  "red block"
carries_each "what the red block names is the failing tests and checks it printed, and the duplication scan when the red is its rows" \
  "failing test" "tests that failed" "failed test" "failing check" "checks that failed" -- \
  "scan"
carries_each "it lets the Gate fixer run the test files its commit and the Fixers' commits touch as well" \
  "test file" "tests" -- \
  "your commit touches" "your commit touched" "your commit changes" "your fix touches" "you touched" "you touch" "your diff touches" -- \
  "Fixers' commits" "Fixers' commit" "Fixers committed" "Fixers touched" "Fixers' diff"
carries_each "it leaves the whole suite and the Gate to the orchestrator, which runs them once the Gate fixer returns" \
  "orchestrator" -- \
  "Gate" -- \
  "return"

[ "$fails" -eq 0 ] && exit 0
exit 1
