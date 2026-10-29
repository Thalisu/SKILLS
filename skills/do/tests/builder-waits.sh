#!/usr/bin/env bash
# builder-waits.sh: the Builder waits on what its next step needs in the foreground. The Agent tool
# runs an agent in the background unless the call sets `run_in_background: false`, so a test author
# or an Implementer dispatched without it comes back as a launch with no verdict, and the Builder
# improvises a poll on a side effect (`until ...; do sleep 5; done`, `tail -f`). When the side effect
# never comes, the poll outlives the Bash tool's timeout, the harness moves it to the background,
# and it spins there as a stale shell long after the Stretch returned.
# The dispatches and the ban are prose the Builder follows, so they are proven over the passages
# that carry them: build-loop.md's `## The test authors` and builder.md's `## The Implementer`.
# Run: bash skills/do/tests/builder-waits.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
builder="$here/../references/builder.md"
build_loop="$here/../references/build-loop.md"
fails=0

mapfile -t foreground_flag < <(foreground_phrasings)

echo "# build-loop.md / ## The test authors: every author whose verdict the loop waits on is dispatched in the foreground"
flat="$(flat_section "$build_loop" "## The test authors")"
expect "build-loop.md has a section \`## The test authors\`" test -n "$flat"
carries_any "the test authors' dispatch sets the Agent tool's run_in_background: false" "${foreground_flag[@]}"

echo "# builder.md / ## The Implementer: the do-implementer dispatch runs in the foreground"
flat="$(flat_section "$builder" "## The Implementer")"
expect "builder.md has a section \`## The Implementer\`" test -n "$flat"
carries_any "the Implementer's dispatch sets the Agent tool's run_in_background: false" "${foreground_flag[@]}"

# The ban may sit in either file the Builder follows, so the passage is the paragraph naming a loop
# of the Builder's own, the one that also names the timeout when several do.
echo "# builder.md / build-loop.md: the Builder never waits with a loop of its own, and every call it waits on comes back inside the Bash timeout"
mapfile -t loop_terms < <(own_loop_phrasings)
paras="$(
  for term in "${loop_terms[@]}"; do
    paragraph_with "$builder" "$term" all
    paragraph_with "$build_loop" "$term" all
  done | tr -s ' ' | awk '!seen[$0]++'
)"
flat="$(grep -E 'timeout|time out|times out' <<<"$paras" | head -n1)"
[ -n "$flat" ] || flat="$(head -n1 <<<"$paras")"
expect "the Builder's contract has a passage on waiting with a loop of its own" test -n "$flat"
subject_denies "it forbids the Builder a wait loop or a poll of its own" "Builder" "${loop_terms[@]}"
carries_each "the ban covers a dispatch and a slow command alike" \
  "dispatch" "agent" "Agent" -- \
  "command" "shell call" "Bash call"
carries_each "it bounds every call the Builder waits on inside the Bash tool's timeout" \
  "Bash" -- \
  "timeout" "time out" "times out" -- \
  "inside the" "within the" "under the" "below the"

# The paragraph also names `600000` for a test or a suite, so the wait call's own timeout is proven
# over the sentences carrying that number, one of which has to be about the wait.
echo "# builder.md / ## The time budget: the fallback wait for a backgrounded agent is itself in the foreground and has a next step"
wait_para="$(paragraph_with "$builder" "timeout 60 tail -f /dev/null" | tr -s ' ')"
flat="$wait_para"
expect "builder.md has a paragraph giving the fallback wait \`timeout 60 tail -f /dev/null\`" test -n "$flat"
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
# `stopped` is the only verdict of `## The return` that ends a stretch short of `built` over anything
# but a Design fork: any other first line is a return the build step cannot route.
carries_each "a wait call that ends with no verdict is repeated up to nine calls in all, then the Stretch returns stopped naming the dispatch, with nothing uncommitted" \
  "no verdict" "without a verdict" "no notification" "without a notification" -- \
  "nine" -- \
  "returns \`stopped\`" -- \
  "naming the dispatch" "names the dispatch" "naming that dispatch" "names that dispatch" \
  "naming the agent" "names the agent" "naming the dispatched" "names the dispatched" -- \
  "nothing uncommitted" "nothing is uncommitted" "nothing is left uncommitted" "no uncommitted work"

[ "$fails" -eq 0 ] && exit 0
exit 1
