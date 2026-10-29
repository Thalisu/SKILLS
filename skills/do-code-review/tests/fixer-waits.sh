#!/usr/bin/env bash
# fixer-waits.sh: the do-code-review-fixer fork waits on its unit test author in the foreground.
# The Agent tool runs an agent in the background unless the call sets `run_in_background: false`,
# so a test author dispatched without it comes back as a launch with no verdict, and the Fixer
# improvises a poll on a side effect (`until ...; do sleep; done`, `tail -f`). The poll outlives the
# Bash tool's timeout, the harness moves it to the background, and it runs stale long after the
# Fixer returned to the orchestrator waiting on its return file.
# The dispatch and the ban are prose the Fixer follows, so they are proven over the paragraphs of
# its agent body that carry them, wherever they sit.
# Run: bash skills/do-code-review/tests/fixer-waits.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
agent="$here/../agents/do-code-review-fixer.md"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# The body alone: a frontmatter hook naming the test author never answers for the prose the Fixer
# follows.
body="$tmp/body.md"
body_of "$agent" >"$body"

mapfile -t foreground_flag < <(foreground_phrasings)
mapfile -t every_agent < <(every_dispatch_phrasings)
mapfile -t loop_terms < <(own_loop_phrasings)

echo "# do-code-review-fixer.md: the unit test author, whose verdict the fix waits on, is dispatched in the foreground"
flat="$(paragraphs_naming "unit-test-author" "unit test author" "${every_agent[@]}")"
expect "the agent body has a passage on dispatching the unit test author" test -n "$flat"
carries_any "the unit test author's dispatch sets the Agent tool's run_in_background: false" "${foreground_flag[@]}"

# The agent body speaks to the Fixer as "you", so the ban's subject is the Fixer in the second person.
echo "# do-code-review-fixer.md: the Fixer never waits with a loop of its own, since the Bash timeout moves the call to the background"
paras="$(paragraphs_naming "${loop_terms[@]}")"
flat="$(grep -E 'timeout|time out|times out' <<<"$paras" | head -n1)"
[ -n "$flat" ] || flat="$(head -n1 <<<"$paras")"
expect "the Fixer's contract has a passage on waiting with a loop of its own" test -n "$flat"
subject_denies "it forbids the Fixer a wait loop or a poll of its own" "You|you|fork|Fixer" "${loop_terms[@]}"
carries_each "the ban covers a dispatch and a slow command alike" \
  "dispatch" "agent" "Agent" -- \
  "command" "shell call" "Bash call"
carries_each "it ties the ban to the Bash tool's timeout moving the call to the background" \
  "Bash" -- \
  "timeout" "time out" "times out" -- \
  "to the background" "into the background" "backgrounds it" "backgrounded"

echo "# do-code-review-fixer.md: the fallback wait for a backgrounded test author is bounded and ends on the Fixer's own stop line"
wait_para="$(paragraph_with "$body" "timeout 60 tail -f /dev/null" | tr -s ' ')"
flat="$wait_para"
expect "the agent body has a paragraph giving the fallback wait \`timeout 60 tail -f /dev/null\`" test -n "$flat"
carries_each "it says the harness moves a Bash call to the background after a few minutes, whatever its timeout" \
  "whatever its \`timeout\`" "whatever its timeout" "regardless of its timeout" -- \
  "to the background"
carries_each "a command the harness moved to the background is waited on the same way as a launched agent" \
  "launch" -- \
  "command" -- \
  "moved to the background"
expect "the wait paragraph never claims a long Bash timeout keeps the wait in the foreground" \
  bash -c '! grep -qF "never moves the wait" <<<"$1"' _ "$wait_para"
flat="$wait_para"
carries_each "a wait call that ends with no notification is repeated until the notification arrives or the 50-minute budget runs out" \
  "no verdict" "without a verdict" "no result" "without a result" "no notification" "without a notification" -- \
  "until" -- \
  "budget" "50 minutes"

# The orchestrator waits on the return file a bounded time and runs the Gate itself once the Fixer
# returns: a Fixer that ran the whole unit loop first outlived that wait, and its commit was dropped.
mapfile -t whole_suite < <(whole_suite_phrasings)
echo "# do-code-review-fixer.md: the Fixer runs its own Finding's test and the test files its commit touches, never the whole unit suite or the Gate"
flat="$(paragraphs_naming "${whole_suite[@]}")"
expect "the agent body has a passage on the project's whole unit suite" test -n "$flat"
subject_denies "it forbids the Fixer running the whole unit suite or the Gate itself" "You|you|Fixer" "${whole_suite[@]}" "Gate"
affirms "it has the Fixer run its own Finding's test" \
  "run" "Run" -- \
  "your Finding's test" "the Finding's test" "your own test" "its own test" "your test"
carries_each "it lets the Fixer run the test files its commit touches as well" \
  "test file" "tests" -- \
  "your commit touches" "your commit touched" "your commit changes" "your fix touches" "you touched" "you touch" "your diff touches"
carries_each "it leaves the whole suite and the Gate to the orchestrator, which runs them once the Fixer returns" \
  "orchestrator" -- \
  "Gate" -- \
  "return"

# The orchestrator waits six `returns.sh 540` windows, 54 minutes, on the return file and discards a
# Fixer whose file lands later: a Fixer with no clock of its own runs past that, its commit is never
# picked and the Review never lands. The Fixer has no stack, and its line carries no `<k>`.
echo "# do-code-review-fixer.md: the Fixer keeps a 50-minute wall-clock budget from its first command and stops on not fixed: out of time"
wall_clock_budget "the Fixer" "not fixed: out of time"

[ "$fails" -eq 0 ] && exit 0
exit 1
