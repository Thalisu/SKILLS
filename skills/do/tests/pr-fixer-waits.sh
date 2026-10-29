#!/usr/bin/env bash
# pr-fixer-waits.sh: the do-pr-fixer fork waits on its unit test author in the foreground.
# The Agent tool runs an agent in the background unless the call sets `run_in_background: false`,
# so a `unit-test-author` dispatched without it comes back as a launch with no verdict, and the
# fork improvises a poll on a side effect (`until ...; do sleep; done`, `tail -f`). The poll
# outlives the Bash tool's timeout, the harness moves it to the background, and it runs stale long
# after the fork returned to the pr Playbook session waiting on its return file.
# The dispatch and the ban are prose the fork follows, so they are proven over the paragraphs of
# its agent body that carry them, wherever they sit.
# Run: bash skills/do/tests/pr-fixer-waits.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
agent="$here/../agents/do-pr-fixer.md"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# The body alone: the frontmatter's Agent hook names unit-test-author, and a paragraph of the hook
# never answers for the prose the fork follows.
body="$tmp/body.md"
body_of "$agent" >"$body"

mapfile -t foreground_flag < <(foreground_phrasings)
mapfile -t every_agent < <(every_dispatch_phrasings)

echo "# do-pr-fixer.md: the unit test author, whose verdict the fix waits on, is dispatched in the foreground"
flat="$(paragraphs_naming "unit-test-author" "unit test author" "${every_agent[@]}")"
expect "the agent body has a passage on dispatching the unit test author" test -n "$flat"
carries_any "the unit test author's dispatch sets the Agent tool's run_in_background: false" "${foreground_flag[@]}"

# The agent body speaks to the fork as "you", so the ban's subject is the fork in the second person.
echo "# do-pr-fixer.md: the fork never waits with a loop of its own, since the Bash timeout moves the call to the background"
mapfile -t loop_terms < <(own_loop_phrasings)
paras="$(paragraphs_naming "${loop_terms[@]}")"
flat="$(grep -E 'timeout|time out|times out' <<<"$paras" | head -n1)"
[ -n "$flat" ] || flat="$(head -n1 <<<"$paras")"
expect "the fork's contract has a passage on waiting with a loop of its own" test -n "$flat"
subject_denies "it forbids the fork a wait loop or a poll of its own" "You|you|fork" "${loop_terms[@]}"
carries_each "the ban covers a dispatch and a slow command alike" \
  "dispatch" "agent" "Agent" -- \
  "command" "shell call" "Bash call"
carries_each "it ties the ban to the Bash tool's timeout moving the call to the background" \
  "Bash" -- \
  "timeout" "time out" "times out" -- \
  "to the background" "into the background" "backgrounds it" "backgrounded"

echo "# do-pr-fixer.md: the fallback wait for a backgrounded test author is bounded and ends on the fork's own stop line"
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
# `not fixed <k>:` is the only line of `## The return file` that ends the fix short of a commit
# once the failure was reproduced: any other line is a return the session cannot route.
carries_each "a wait that ends with no notification is repeated up to nine calls in all, then the fork restores its edits and writes not fixed <k> to its return file" \
  "no verdict" "without a verdict" "no notification" "without a notification" -- \
  "nine" -- \
  "restore" "Restore" -- \
  "not fixed <k>:" -- \
  "return file" "Return file"
flat="$(awk '{ n = split($0, s, /\. /); for (i = 1; i <= n; i++) if (index(s[i], "not fixed <k>:")) print s[i] }' <<<"$wait_para")"
carries_any "the not fixed line names the test author dispatch that never returned" \
  "test author" "unit-test-author" "author dispatch" "naming the dispatch" "names the dispatch" \
  "naming that dispatch" "names that dispatch" "naming the agent" "names the agent"

# The session waits six `returns.sh 540` windows, 54 minutes, then gives the fixer up as `the fixer
# did not return`: a fixer still running past that can still commit and leave its stack up, so the
# fork has to stop on a clock of its own with room to spare.
echo "# do-pr-fixer.md: the fork keeps a 50-minute wall-clock budget from its first command and stops on not fixed <k>: out of time"
budget_terms=("50 minutes" "50-minute" "fifty minutes" "fifty-minute" "Fifty minutes")
paras="$(paragraphs_naming "${budget_terms[@]}")"
flat="$(grep -F "out of time" <<<"$paras" | head -n1)"
[ -n "$flat" ] || flat="$(head -n1 <<<"$paras")"
expect "the agent body has a paragraph naming the fork's 50-minute budget" test -n "$flat"
carries_each "the budget is 50 minutes, counted from the first command and read with date +%s" \
  "${budget_terms[@]}" -- \
  "first command" "first Bash call" "first shell call" "first call" -- \
  "date +%s"
carries_each "the budget is checked before a command or a wait call that could run past it" \
  "before any command" "before a command" "before each command" "before every command" \
  "before running a command" "before you run" "before any call" "before each call" "before a call" -- \
  "wait call" "a wait" "any wait" "each wait" "the wait"
carries_each "out of time, the fork restores its edits, tears down its stack and writes not fixed <k>: out of time, never a commit" \
  "restore" "Restore" -- \
  "tear down" "Tear down" "tears down" "teardown" "down -v" -- \
  "not fixed <k>: out of time" -- \
  "no commit" "never a commit" "never commit" "without a commit" "without committing" "not commit"

[ "$fails" -eq 0 ] && exit 0
exit 1
