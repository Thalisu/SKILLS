#!/usr/bin/env bash
# condition-cut-references.sh: the text a run needs only under a condition lives in a reference of
# its own, read when that condition holds, so a run whose condition does not hold never loads it.
# The files every run opens whole keep a pointer to it in its place.
# Run: bash skills/do/tests/condition-cut-references.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
refs="$here/../references"
builder="$refs/builder.md"
agent="$here/../agents/do-builder.md"
fails=0

subsection() { # $1 file, $2 the heading line; the flattened subsection on stdout
  passage_of "$1" "$2" "#" 2>/dev/null | tail -n +2 | tr '\n' ' ' | tr -s ' '
}

echo "# flows.md: a Builder whose Digest names no observable criterion loads no text about the flows"

# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$(cat "$builder")"
absent "builder.md no longer holds the flows section" "## The flows"
absent "builder.md no longer decides which criteria get a flow" "Which criteria get a flow"
absent "builder.md no longer decides who authors a flow" "Who authors it"
absent "builder.md no longer reads the E2E author's report" "Reading the author's report"
flat="$(tr '\n' ' ' <"$builder" | tr -s ' ')"
carries_each "builder.md points at flows.md when the Digest's Observable criteria names a criterion" \
  "Read [flows.md](flows.md) when " -- "Observable criteria"

expect "flows.md exists" test -f "$refs/flows.md"
flat="$(subsection "$refs/flows.md" "## Which criteria get a flow")"
carries "flows.md decides which criteria get a flow from the Digest's Observable criteria" \
  "\`## Observable criteria\`" "no criterion a user can observe"
flat="$(subsection "$refs/flows.md" "## Who authors it")"
carries "flows.md decides who authors a flow from the brief's Loop: key" "\`Loop: policy\`"
# shellcheck disable=SC2034  # lib.sh's carries reads $flat
flat="$(subsection "$refs/flows.md" "## Reading the author's report")"
carries "flows.md counts the report's runs before its verdict, then routes each verdict" \
  "third run" "\`GREEN\`" "\`BLOCKED\`" "\`HANDBACK\`" "\`REFUSED_INCOMPLETE_INPUT\`"

echo "# time-budget.md: a Builder whose Stretch stays within its budget loads no text about a spent one"

# The Builder opens builder.md and its own definition whole on every Stretch: what a stretch=stop
# answer asks of it, and what the session does with that return, are read only once it comes.
for always in "$builder" "$agent"; do
  name="$(basename "$always")"
  flat="$(tr '\n' ' ' <"$always" | tr -s ' ')"
  carries "$name still asks the time budget command after each behaviour's commit" "stretch-budget.sh"
  carries_each "$name points at time-budget.md when the command answers stretch=stop" \
    "Read [time-budget.md](time-budget.md) when " "Read \`~/.claude/skills/do/references/time-budget.md\` when " -- \
    "stretch=stop"
  # shellcheck disable=SC2034  # lib.sh's absent reads $out
  out="$flat"
  absent "$name no longer returns stopped on a spent budget itself" "spent time budget as the reason"
  absent "$name no longer names the spent budget on a stopped: line itself" "naming the spent time budget"
  absent "$name no longer carries the spent-budget return" "time budget spent after the second behaviour's commit"
  absent "$name no longer says who clears a spent budget" "cleared by the next fork alone"
done

expect "time-budget.md exists" test -f "$refs/time-budget.md"
flat="$({ tr '\n' ' ' <"$refs/time-budget.md"; } 2>/dev/null | tr -s ' ')"
carries_each "on stretch=stop the Stretch returns stopped naming the spent budget, nothing uncommitted" \
  "stretch=stop" -- "\`stopped\`" -- "nothing is uncommitted" "nothing uncommitted"
carries "a stop read after the Plan's last behaviour, with no flow left, returns built" "\`built\`"
carries "the session forks the next Stretch with the same brief" "same brief"

echo "# global-authors.md: a build loop whose loop line reads Loop: policy loads no global or fallback author text"

# build-loop.md and flows.md are read on every policy run: the global authors, the Project map and
# the TDD fallback are read only once the loop line names them.
for always in "$refs/build-loop.md" "$refs/flows.md"; do
  name="$(basename "$always")"
  flat="$({ tr '\n' ' ' <"$always"; } 2>/dev/null | tr -s ' ')"
  carries "$name points at global-authors.md when the loop line reads Loop: global or Loop: fallback" \
    "Read [global-authors.md](global-authors.md) when " "\`Loop: global\`" "\`Loop: fallback\`"
  # shellcheck disable=SC2034  # lib.sh's absent reads $out
  out="$flat"
  absent "$name no longer dispatches the global unit test author" "global-unit-test-author"
  absent "$name no longer dispatches the global end-to-end test author" "global-e2e-test-author"
  absent "$name no longer routes to the TDD fallback" "tdd-fallback.md"
  absent "$name no longer reads an unfilled Project map slot" "none yet → /testing-policy"
done

expect "global-authors.md exists" test -f "$refs/global-authors.md"
flat="$({ tr '\n' ' ' <"$refs/global-authors.md"; } 2>/dev/null | tr -s ' ')"
carries "global-authors.md dispatches both global authors with the Project map" \
  "subagent_type: global-unit-test-author" "subagent_type: global-e2e-test-author" "Project map: "
carries "global-authors.md sends Loop: fallback and a BLOCKED map slot to the TDD fallback" \
  "[tdd-fallback.md](tdd-fallback.md)" "\`BLOCKED\`" "none yet → /testing-policy"

[ "$fails" -eq 0 ]
