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

foreground_flag=(
  "run_in_background: false" "run_in_background: \`false" "run_in_background\`: \`false"
  "run_in_background\` set to \`false" "run_in_background\` to \`false" "run_in_background=false"
  "run_in_background\` set to false" "run_in_background\` to false"
)

# A sentence that says the thing is not done: the passage names a loop, and one of its sentences
# carries both the loop and a negator, so a passage that only describes a poll never answers for one
# that forbids it.
denies() { # $1 label, $2.. fixed strings naming the thing; one sentence of $flat carries one of them and a negator word
  local label="$1" phrases
  shift
  phrases="$(printf '%s\n' "$@")"
  if phrases="$phrases" awk '
    BEGIN { n = split(ENVIRON["phrases"], p, "\n") }
    {
      m = split($0, sentence, /\. /)
      for (j = 1; j <= m; j++) {
        named = 0
        for (k = 1; k <= n; k++) if (index(sentence[j], p[k])) named = 1
        if (named && (" " sentence[j] " ") ~ /[^A-Za-z](never|Never|not|no|No|nor|without|forbidden|forbids)[^A-Za-z]|n'"'"'t[^A-Za-z]/) found = 1
      }
    }
    END { exit !found }
  ' <<<"$flat"; then ok "$label"; else fail "$label (no sentence denies: $*)"; fi
}

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
echo "# builder.md / build-loop.md: the Builder never waits with a loop of its own, since the Bash timeout moves the call to the background"
loop_terms=(
  "wait loop" "poll" "\`until" "\`while" "tail -f" "sleep loop" "loop of its own" "loop of their own"
  "until\` loop" "while\` loop"
)
paras="$(
  for term in "${loop_terms[@]}"; do
    paragraph_with "$builder" "$term" all
    paragraph_with "$build_loop" "$term" all
  done | tr -s ' ' | awk '!seen[$0]++'
)"
flat="$(grep -E 'timeout|time out|times out' <<<"$paras" | head -n1)"
[ -n "$flat" ] || flat="$(head -n1 <<<"$paras")"
expect "the Builder's contract has a passage on waiting with a loop of its own" test -n "$flat"
denies "it forbids the Builder a wait loop or a poll of its own" "${loop_terms[@]}"
carries_each "the ban covers a dispatch and a slow command alike" \
  "dispatch" "agent" "Agent" -- \
  "command" "shell call" "Bash call"
carries_each "it ties the ban to the Bash tool's timeout moving the call to the background" \
  "Bash" -- \
  "timeout" "time out" "times out" -- \
  "to the background" "into the background" "backgrounds it" "backgrounded"

# The paragraph also names `600000` for a test or a suite, so the wait call's own timeout is proven
# over the sentences carrying that number, one of which has to be about the wait.
echo "# builder.md / ## The time budget: the fallback wait for a backgrounded agent is itself in the foreground and has a next step"
wait_para="$(paragraph_with "$builder" "timeout 540 tail -f /dev/null" | tr -s ' ')"
flat="$wait_para"
expect "builder.md has a paragraph giving the fallback wait \`timeout 540 tail -f /dev/null\`" test -n "$flat"
flat="$(awk '{ n = split($0, s, /\. /); for (i = 1; i <= n; i++) if (index(s[i], "600000")) print s[i] }' <<<"$wait_para")"
carries_each "the wait call runs with the Bash tool's timeout set to 600000 ms, above the wait's own timeout 540" \
  "timeout 540" "tail -f /dev/null" "wait call" "the wait" "waits with" "wait itself" -- \
  "timeout"
flat="$wait_para"
carries_each "a wait call that ends with no verdict is repeated a bounded number of times, then the Stretch returns blocked naming the dispatch" \
  "no verdict" "without a verdict" "no notification" "without a notification" -- \
  "twice" "at most" "up to" "a bounded number" "once more" "no more than" -- \
  "blocked" -- \
  "naming the dispatch" "names the dispatch" "naming that dispatch" "names that dispatch" \
  "naming the agent" "names the agent" "naming the dispatched" "names the dispatched"

[ "$fails" -eq 0 ] && exit 0
exit 1
