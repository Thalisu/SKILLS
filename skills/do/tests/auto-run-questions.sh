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

echo "# a question still asked under --auto: the choice-taker's return rides on it, and nothing is done on that return before the developer answers"

# Every paragraph of the section that speaks of a question the flag leaves with the developer, read
# together: the guarantee may be split over more than one of them. The numbered steps of the route
# a ruled question takes carry none of these phrases, so their `choice-taker` never answers here.
section="$(passage_of "$forks" "### A run question under" "### ")"
flat="$(for anchor in "cannot be undone" "leaves the machine" "irreversible" "remote tracker" \
  "still asked" "still asks" "still put"; do
  paragraph_with <(printf '%s\n' "$section") "$anchor" all
done | awk '!seen[$0]++' | tr '\n' ' ' | tr -s ' ')"
expect "forks.md's section on run questions covers the ones still asked under --auto" test -n "$flat"

carries_each "forks.md forks the choice-taker on a question still asked under --auto" \
  "choice-taker" -- "fork" "Agent tool" "handed" "brief"
carries_each "forks.md hands that choice-taker the step's own question and options" \
  "choice-taker" -- \
  "as the step words it" "as its step words it" "the step's own question" "its step's own question" \
  "its own question" "the step's own words" "same question" "never reword" "not reword" \
  "without rewording" "not rewritten" "never rewritten" "same brief" "brief above" "brief of" \
  "that brief" "keys above" "step 1"
carries_each "forks.md puts a settled return's side and norm on the question" \
  "settled" -- "\`Side:\`" "Side" "side" -- "\`Norm:\`" "Norm" "norm"
carries_each "forks.md puts an extreme return on the question quoted with its reason" \
  "extreme" -- "quote" "verbatim" "word for word" "as it came back" "as they came back" -- \
  "reason" "Reason"
carries_any "forks.md keeps the return on the question as it came back" \
  "as it came back" "as they came back" "verbatim" "word for word" "unchanged" "quoted" "quotes"
carries_any "forks.md has the run do nothing on that return before the developer answers" \
  "before the developer answers" "until the developer answers" "before the developer's answer" \
  "until the developer's answer" "before their answer" "until their answer" "before they answer" \
  "until they answer" "before the developer's yes" "without the developer's yes" "before their yes" \
  "without their yes" "waits for the developer" "wait for the developer" "waits for their" \
  "never acts on" "does not act on" "not acted on" "acts on neither" "acts on nothing" \
  "never follows" "does not follow" "follows neither" "not followed"

echo "# the discard of uncommitted work on a resume: still asked under --auto, with the choice-taker's answer shown and nothing discarded first"

# A bullet is read from its marker to the first line that is not indented under it, so the bullets
# nested in it come along and a blank line inside it does not cut it short.
bullets_opening_on() { # $1 file, $2 a fixed string a bullet's marker line carries within its first 30 characters: each such bullet flattened, one per line, on stdout
  bullet_key="$2" awk '
    function flush() { if (on) print item; on = 0; item = "" }
    {
      match($0, /^ */)
      lead = RLENGTH
    }
    on && $0 !~ /^ *$/ && lead <= indent { flush() }
    !on && match($0, /^ *- /) {
      at = index($0, ENVIRON["bullet_key"])
      if (at > 0 && at - RLENGTH <= 30) { on = 1; indent = lead }
    }
    on { item = item " " $0 }
    END { flush() }
  ' "$1" | tr -s ' '
}
still_asked_with_the_answer_shown() { # $1 the place, its statement of the discard question flattened in $flat
  if [ -z "$flat" ]; then
    fail "$1 states the question before uncommitted changes are discarded (passage not found)"
    return
  fi
  carries "$1 says what the discard question becomes under --auto" "--auto"
  carries_any "$1 still asks the developer before the discard under --auto" \
    "still asked" "still asks" "still put" "still the developer's" "asked of the developer" \
    "asks the developer" "stay the developer's" "stays the developer's" "remain the developer's" \
    "remains the developer's" "as without it" "as without the flag" "the flag as without" \
    "asked all the same" "asks all the same" "asks it all the same" "never ruled" "not ruled" \
    "never handed" "not handed" "rules nothing"
  carries_any "$1 shows the choice-taker's answer on that question, itself or through forks.md" \
    "choice-taker" "(forks.md)"
}

# ticket.md routes a resume on the script's verdict, one bullet per verdict: every bullet that opens
# on `verdict=ask` and speaks of the discard states the question, in a Ticket run's resume and in a
# stopped Final integration's alike.
ask_bullets="$(bullets_opening_on "$ticket" "\`verdict=ask\`" | grep -i "discard")"
expect "ticket.md states the discard question on verdict=ask for a Ticket run's resume and for a stopped Final integration" \
  test "$(grep -c . <<<"$ask_bullets")" -ge 2
n=0
while IFS= read -r flat; do
  n=$((n + 1))
  still_asked_with_the_answer_shown "ticket.md's verdict=ask bullet $n"
done <<<"$ask_bullets"

# The bullet that words the question in full is the one the session writes it from.
flat="$(grep -E "per file|uncommitted=" <<<"$ask_bullets" | head -n 1)"
expect "ticket.md has a verdict=ask bullet that words the discard question in full" test -n "$flat"
carries_any "ticket.md's discard question names the changes one line per file" \
  "one line per file" "a line per file" "line per file" "one line each" "per file"
# Read without the word `uncommitted`, which would answer for the commit.
flat="${flat//uncommitted/}"
carries_each "ticket.md has nothing stashed, committed or restored before the developer's answer" \
  "stash" -- "commit" -- "restore" -- \
  "without the answer" "before the answer" "before it" "until the answer" "without their answer" \
  "before their answer" "before the developer answers" "until the developer answers" \
  "without the developer's yes" "before the developer's yes" "without a yes" "before a yes"

# refactoring.md's resume step, found as the first numbered step that speaks of the discard, read in
# the paragraphs that do.
resume_heading="$(awk '
  /^### [0-9]+\./ { heading = $0 }
  heading != "" && tolower($0) ~ /discard/ { print heading; exit }
' "$refactoring")"
flat=""
if [ -n "$resume_heading" ]; then
  flat="$(paragraph_with <(item_holding "$refactoring" '### [0-9]+\.' "$resume_heading") "iscard" all |
    tr '\n' ' ' | tr -s ' ')"
fi
still_asked_with_the_answer_shown "refactoring.md's resume step"
carries_any "refactoring.md's resume step puts its question before uncommitted changes" \
  "uncommitted" "Uncommitted"

# The home those steps send the reader to counts the discard among the questions still asked, and
# has nothing discarded on the choice-taker's return.
section="$(passage_of "$forks" "### A run question under" "### ")"
flat="$(for anchor in "cannot be undone" "leaves the machine" "irreversible" "still asked" \
  "still asks" "still put"; do
  paragraph_with <(printf '%s\n' "$section") "$anchor" all
done | awk '!seen[$0]++' | tr '\n' ' ' | tr -s ' ')"
carries_each "forks.md counts uncommitted work discarded among the questions still asked under --auto" \
  "uncommitted" "Uncommitted" -- "thrown away" "discard"
carries_any "forks.md has nothing discarded on the choice-taker's return before the developer answers" \
  "nothing is discarded" "nothing discarded" "discards nothing" "no discard" "never discards" \
  "not discarded"

[ "$fails" -eq 0 ] && exit 0
exit 1
