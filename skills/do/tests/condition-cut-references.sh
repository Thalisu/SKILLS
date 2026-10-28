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
skill="$here/../SKILL.md"
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

echo "# second-run.md: a run that forks the reader once loads no text about a second reader run"

# The reader section of mechanics.md is read by every run that forks the reader; the reuse gate is
# read only once a Digest already sits beside the Ticket.
flat="$(flat_section "$refs/mechanics.md" "## The reader")"
carries "mechanics.md's reader section points at second-run.md when a Digest already sits beside the Ticket" \
  "Read [second-run.md](second-run.md) when " "Digest already sits beside the Ticket"
# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$flat"
absent "mechanics.md's reader section no longer holds the second run" "### A second run"
absent "mechanics.md's reader section no longer reuses a Digest itself" "\`verdict=reuse\` (exit 0)"
absent "mechanics.md's reader section no longer re-forks the reader itself" "\`verdict=fork\` (exit 1)"
flat="$(flat_section "$refs/ticket.md" "## Door")"
carries "ticket.md's door points at second-run.md for the digest check" "Read [second-run.md](second-run.md) when "

expect "second-run.md exists" test -f "$refs/second-run.md"
flat="$({ tr '\n' ' ' <"$refs/second-run.md"; } 2>/dev/null | tr -s ' ')"
carries "second-run.md runs the digest check and routes on its reuse and fork verdicts" \
  "grounding.sh digest" "\`verdict=reuse\`" "\`verdict=fork\`"

echo "# verification.md: a run with no affected flow loads none of the front-end verification text"

# mechanics.md is read by every Playbook that builds in a worktree; the flows run after the landing
# are read only by a run that has one.
flat="$(tr '\n' ' ' <"$refs/mechanics.md" | tr -s ' ')"
carries "mechanics.md points at verification.md when the run has an affected flow" \
  "Read [verification.md](verification.md) when " "affected flow"
# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$flat"
absent "mechanics.md no longer holds the verification" "## The verification"
absent "mechanics.md no longer runs the affected flows itself" "scripts/flows.sh [--infra <pattern>]"
for playbook in ticket.md bug-fix.md refactoring.md; do
  flat="$(tr '\n' ' ' <"$refs/$playbook" | tr -s ' ')"
  carries "$playbook's verification step points at verification.md" "Read [verification.md](verification.md) when "
done
for file in ticket.md bug-fix.md refactoring.md forks.md; do
  # shellcheck disable=SC2034  # lib.sh's absent reads $out
  out="$(tr '\n' ' ' <"$refs/$file" | tr -s ' ')"
  absent "$file no longer sends the verification to mechanics.md" "verification in [mechanics.md](mechanics.md)"
  absent "$file no longer names mechanics.md as the verification's home" "verification of [mechanics.md](mechanics.md)"
done

expect "verification.md exists" test -f "$refs/verification.md"
flat="$({ tr '\n' ' ' <"$refs/verification.md"; } 2>/dev/null | tr -s ' ')"
carries "verification.md runs the affected flows by script and stops blocked on an infrastructure failure" \
  "scripts/flows.sh" "\`verdict=blocked\`"
carries "verification.md asks before a full suite, ruled by the choice-taker under --auto" "--auto" "choice-taker"
carries "verification.md fixes a red flow as one more unit of the build loop" "[build-loop.md](build-loop.md)" "\`bugfix\`"

echo "# each new reference opens on every reader that reaches it and the condition that sends them"

opening() { # $1 file: the first paragraph past the title, on one line
  awk 'BEGIN { RS = "" } !/^#/ { gsub(/\n/, " "); print; exit }' "$1" 2>/dev/null | tr -s ' '
}

flat="$(opening "$refs/flows.md")"
carries_each "flows.md's opening names the Builder, do-impeccable and the session in the Builder's place" \
  "Builder" -- "do-impeccable" -- "session"
carries "flows.md's opening names its condition, the Digest's Observable criteria naming a criterion" \
  "\`## Observable criteria\`" "names a criterion"

flat="$(opening "$refs/time-budget.md")"
carries_each "time-budget.md's opening names the Builder and the build step that reads a spent-budget return" \
  "Builder" -- "build step"
carries "time-budget.md's opening names its condition, stretch=stop or a stopped: line naming a spent budget" \
  "stretch=stop" "spent time budget"

flat="$(opening "$refs/global-authors.md")"
carries_each "global-authors.md's opening names the build loop and the flows" "build loop" -- "flows"
carries "global-authors.md's opening names its condition, the loop line reading Loop: global or Loop: fallback" \
  "\`Loop: global\`" "\`Loop: fallback\`"

flat="$(opening "$refs/second-run.md")"
carries_each "second-run.md's opening names the door and the reader section" "door" -- "reader section"
carries "second-run.md's opening names its condition, a Digest already beside the Ticket" \
  "Digest already sits beside the Ticket"

flat="$(opening "$refs/verification.md")"
carries_each "verification.md's opening names the verification steps and the Final integration" \
  "verification step" -- "Final integration"
carries "verification.md's opening names its condition, an affected flow or a full E2E suite" \
  "affected flow" "full_e2e=yes"

echo "# SKILL.md's references list names each new reference with its readers and its condition"

entry() { # $1 file name: its SKILL.md references-list bullet, flattened
  bullets_opening_on "$skill" "[$1](references/$1):" | tr -s ' '
}

flat="$(entry flows.md)"
carries "the flows.md entry names its readers and its condition" \
  "Builder" "do-impeccable" "\`## Observable criteria\`" "names a criterion"
flat="$(entry time-budget.md)"
carries "the time-budget.md entry names its readers and its condition" "Builder" "build step" "stretch=stop"
flat="$(entry global-authors.md)"
carries "the global-authors.md entry names its readers and its condition" \
  "build loop" "flows" "\`Loop: global\`" "\`Loop: fallback\`"
flat="$(entry second-run.md)"
carries "the second-run.md entry names its readers and its condition" \
  "door" "reader section" "Digest already sits beside the Ticket"
flat="$(entry verification.md)"
carries "the verification.md entry names its readers and its condition" \
  "verification step" "Final integration" "affected flow" "full_e2e=yes"

# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$(entry mechanics.md)"
absent "the mechanics.md entry no longer lists the verification" "the verification"
absent "the mechanics.md entry no longer lists the second run" "second run"
# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$(entry builder.md)"
absent "the builder.md entry no longer lists the flows" "flows"
absent "the builder.md entry no longer lists the time budget" "time budget"

echo "# every pointer to a new reference reads \`Read <file> when <condition>\`"

# A link to the file under any relative path, or its installed path in an agent definition, is a
# pointer, except SKILL.md's references-list entry and the links a file makes to itself.
for file in flows.md time-budget.md global-authors.md second-run.md verification.md; do
  key="${file//./\\.}"
  pointers=0
  misshapen=""
  for doc in "$refs"/*.md "$here"/../agents/*.md; do
    [ "$(basename "$doc")" = "$file" ] && continue
    while IFS= read -r hit; do
      [ -n "$hit" ] || continue
      pointers=$((pointers + 1))
      grep -qE "^Read (\[$key\]\($key\)|\`~/\.claude/skills/do/references/$key\`) when " <<<"$hit" ||
        misshapen="$misshapen${misshapen:+; }$(basename "$doc"): $hit"
    done < <(tr '\n' ' ' <"$doc" | tr -s ' ' |
      grep -oE "(Read )?(\[[^]]*\]\(([^)]*/)?$key\)|\`[^\`]*references/$key\`)( when )?")
  done
  expect "the do skill points at $file from the steps that read it" test "$pointers" -ge 1
  if [ -z "$misshapen" ]; then
    ok "every pointer to $file has the \`Read <file> when <condition>\` shape"
  else
    fail "every pointer to $file has the \`Read <file> when <condition>\` shape (misshapen: $misshapen)"
  fi
done

[ "$fails" -eq 0 ]
