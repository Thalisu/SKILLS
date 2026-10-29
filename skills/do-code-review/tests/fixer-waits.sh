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
# The Fixer's lines carry no `<k>`: `not fixed:` is the line of `## Two ends with no commit` that
# the orchestrator reads as a Finding left alone, so any other end is a return it cannot route.
carries_each "a wait that ends with no notification is repeated up to nine calls in all, then the Fixer restores its edits, makes no commit and writes not fixed: to its return file" \
  "no verdict" "without a verdict" "no notification" "without a notification" -- \
  "nine" -- \
  "restore" "Restore" -- \
  "no commit" "without a commit" "not commit" "never commit" -- \
  "not fixed:" -- \
  "return file" "Return file"
flat="$(awk '{ n = split($0, s, /\. /); for (i = 1; i <= n; i++) if (index(s[i], "not fixed:")) print s[i] }' <<<"$wait_para")"
carries_any "the not fixed line names the test author dispatch that never returned" \
  "test author" "unit-test-author" "author dispatch" "naming the dispatch" "names the dispatch" \
  "naming that dispatch" "names that dispatch" "naming the agent" "names the agent"

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

[ "$fails" -eq 0 ] && exit 0
exit 1
