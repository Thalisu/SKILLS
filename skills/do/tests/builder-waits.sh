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

[ "$fails" -eq 0 ] && exit 0
exit 1
