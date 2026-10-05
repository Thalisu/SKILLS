#!/usr/bin/env bash
# auto-run-questions.sh: under `--auto` a run question is ruled by the `choice-taker`, and the run
# finds that route wherever the question is stated. The session follows the prose it reads at the
# step, with nobody there to answer: a step that still says its question waits for the developer,
# or a Playbook restating it as asked whenever the run reaches it, stops an unattended run with the
# work already landed. forks.md is the one home of the route (the brief, and what the run does on a
# `settled` Ruling), so each place stating a question names `--auto` and sends the reader there,
# and forks.md's table of run questions has a row for it.
#
# The passages are found by what they say, never by their number: the steps are renumbered whenever
# one is added or absorbed. Each is flattened before it is read, since the references hard-wrap.
# Run: bash skills/do/tests/auto-run-questions.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
mech="$here/../references/mechanics.md"
forks="$here/../references/forks.md"
ticket="$here/../references/ticket.md"
bugfix="$here/../references/bug-fix.md"
refactoring="$here/../references/refactoring.md"
fails=0

rules_it_under_auto() { # $1 the place, its text flattened in $flat: it names `--auto`, and the choice-taker or forks.md as what rules the question there
  # Optional: $2 the question, as the labels name it (default: the one before a full suite or a remote run)
  local question="${2:-the question before a full suite or a remote run}"
  if [ -z "$flat" ]; then
    fail "$1 states $question (passage not found)"
    return
  fi
  carries "$1 says what $question becomes under --auto" "--auto"
  carries_any "$1 hands that question to the choice-taker under --auto" "choice-taker" "(forks.md)"
}

echo "# the question before a full suite or a remote run: ruled by the choice-taker under --auto"

# The shared mechanics: the verification's own item, where every Playbook sends the reader.
verification="$(passage_of "$mech" "## The verification" "## The close")"
flat="$(item_holding <(printf '%s\n' "$verification") '[0-9]+\.' "remote run" | tr '\n' ' ' | tr -s ' ')"
expect "mechanics.md's verification carries the item on a full suite or a remote run" test -n "$flat"
carries "mechanics.md's verification item says what its question becomes under --auto" "--auto"
carries "mechanics.md's verification item names the choice-taker as what rules its question under --auto" \
  "choice-taker"
carries "mechanics.md's verification item links forks.md, the home of the route" "(forks.md)"
carries "mechanics.md's verification item still records each flow as not run on a no" "not run"

# The one home of the route: only a question the table lists takes it, and the row names the file
# of the step that asks it.
flat="$(passage_of "$forks" "### A run question under" "### " | grep '^|' | grep -E 'full suite|remote run')"
expect "forks.md's table of run questions has a row for the question before a full suite or a remote run" \
  test -n "$flat"
carries "forks.md's row for that question names mechanics.md, the file of its step" "(mechanics.md)"

# Every Playbook that reaches the verification restates the question at its own step.
flat="$(item_holding "$ticket" '\*\*[0-9]+\.' ". Verification.**" | tr '\n' ' ' | tr -s ' ')"
rules_it_under_auto "ticket.md's Verification step"

flat="$(item_holding "$bugfix" '\*\*[0-9]+\.' ". Verification.**" | tr '\n' ' ' | tr -s ' ')"
rules_it_under_auto "bug-fix.md's Verification step"

flat="$(item_holding "$refactoring" '### [0-9]+\.' ". Verification" | tr '\n' ' ' | tr -s ' ')"
rules_it_under_auto "refactoring.md's Verification step"

# refactoring.md's index of the questions the run asks: a table row is read alone, since a route
# written on another question's row says nothing of this one.
index="$(passage_of "$refactoring" "## Questions and stops" "## Steps")"
flat="$({
  paragraph_with <(printf '%s\n' "$index") "--auto" all | grep -v '^|'
  grep '^|' <<<"$index" | grep -F -- "--auto"
} | grep -E 'full suite|remote run|13' | tr '\n' ' ' | tr -s ' ')"
rules_it_under_auto "refactoring.md's index of questions"

# A sentence saying a reserved yes is asked whenever the run reaches it contradicts the route unless
# its own paragraph carries the `--auto` side.
stale="$(paragraph_with "$refactoring" "whenever" all | tr -s ' ' |
  grep -F "whenever the run reaches" | grep -vF -- "--auto")"
if [ -z "$stale" ]; then
  ok "refactoring.md never says a reserved yes is asked whenever the run reaches it without its --auto route"
else
  fail "refactoring.md never says a reserved yes is asked whenever the run reaches it without its --auto route (found: $stale)"
fi

echo "# refactoring: the two-homes choice and the harness yes are ruled under --auto, the discard and the revert stay the developer's"

homes="the choice between two homes the request fits equally"
harness="the yes for a harness that cannot stay inside its bound"

# The step itself, in the item or the paragraph that states the question: that is what the session
# is reading when it would otherwise stop and wait.
door="$(item_holding "$refactoring" '### [0-9]+\.' ". Door")"
flat="$(item_holding <(printf '%s\n' "$door") '[0-9]+\.' "homes" | tr '\n' ' ' | tr -s ' ')"
rules_it_under_auto "refactoring.md's Door, in the item on two homes," "$homes"

pin="$(item_holding "$refactoring" '### [0-9]+\.' ". Pin")"
flat="$(paragraph_with <(printf '%s\n' "$pin") "harness" all | tr -s ' ' | grep -F "cannot be driven inside")"
rules_it_under_auto "refactoring.md's Pin, in the paragraph on a behaviour outside the harness's bound," "$harness"

run_questions="$(passage_of "$forks" "### A run question under" "### " | grep '^|')"
flat="$(grep -F "homes" <<<"$run_questions")"
expect "forks.md's table of run questions has a row for $homes" test -n "$flat"
carries "forks.md's row for that choice names refactoring.md, the file of its step" "(refactoring.md)"
flat="$(grep -F "harness" <<<"$run_questions")"
expect "forks.md's table of run questions has a row for $harness" test -n "$flat"
carries "forks.md's row for that yes names refactoring.md, the file of its step" "(refactoring.md)"

# The index, read one statement at a time: a sentence of its prose naming `--auto`, or a row of its
# table of questions. A row counts when it names `--auto` itself or sits under a column that does,
# and it is read with that header so the column's name answers for the flag.
questions_table="$(awk '/^\|/ { on = 1; print; next } on { exit }' <<<"$index")"
questions_header="$(head -n 1 <<<"$questions_table")"
index_under_auto="$({
  paragraph_with <(printf '%s\n' "$index") "--auto" all | grep -v '^|' | tr -s ' ' |
    awk 'BEGIN { RS = "\\.[ \n]" } /--auto/ { print }'
  if grep -qF -- "--auto" <<<"$questions_header"; then
    tail -n +3 <<<"$questions_table" | while IFS= read -r row; do printf '%s %s\n' "$questions_header" "$row"; done
  else
    grep -F -- "--auto" <<<"$questions_table"
  fi
})"
flat="$(grep -E 'homes|steps? ([0-9]+(, and |, | and ))*1([^0-9]|$)|\| 1 \|' <<<"$index_under_auto" | tr '\n' ' ')"
rules_it_under_auto "refactoring.md's index of questions" "$homes"
flat="$(grep -E 'harness|steps? ([0-9]+(, and |, | and ))*3([^0-9]|$)|\| 3 \|' <<<"$index_under_auto" | tr '\n' ' ')"
rules_it_under_auto "refactoring.md's index of questions" "$harness"

# The discard and the revert cannot be undone, so the flag never reaches them. forks.md's table is
# the whole list of what takes the route, and a statement of refactoring.md naming the choice-taker
# beside either of the two has to say that one is still asked.
flat="$(grep -iE 'discard|revert' <<<"$run_questions")"
expect "forks.md's table of run questions has no row for the discard of uncommitted changes or the revert of the branch" \
  test -z "$flat"

handed=""
while IFS= read -r statement; do
  [ -n "$statement" ] || continue
  kept=""
  for key in "still asked" "still asks" "asked of the developer" "asks the developer" \
    "stay the developer's" "stays the developer's" "remain the developer's" "remains the developer's" \
    "never ruled" "never handed" "not ruled" "not handed" "never the \`choice-taker\`" "no \`choice-taker\`"; do
    grep -qF -- "$key" <<<"$statement" && kept=yes
  done
  [ -n "$kept" ] || handed="$statement"
done < <({
  paragraph_with "$refactoring" "choice-taker" all | grep -v '^ *|' | tr -s ' ' |
    awk 'BEGIN { RS = "\\.[ \n]" } /choice-taker/ { print }'
  grep '^ *|' "$refactoring" | grep -F "choice-taker"
} | grep -iE 'discard|revert')
if [ -z "$handed" ]; then
  ok "refactoring.md never hands the discard of uncommitted changes or the revert of the branch to the choice-taker"
else
  fail "refactoring.md never hands the discard of uncommitted changes or the revert of the branch to the choice-taker (found: $handed)"
fi

[ "$fails" -eq 0 ] && exit 0
exit 1
