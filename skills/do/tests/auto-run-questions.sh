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

still_asked_with_the_answer_shown() { # $1 the place, its statement of the discard question flattened in $flat
  # Optional: $2 the question, as the labels name it (default: the discard question), $3 what it comes before (default: before the discard)
  local question="${2:-the discard question}" moment="${3:-before the discard}"
  local stated="${2:-the question before uncommitted changes are discarded}"
  if [ -z "$flat" ]; then
    fail "$1 states $stated (passage not found)"
    return
  fi
  carries "$1 says what $question becomes under --auto" "--auto"
  carries_any "$1 still asks the developer $moment under --auto" \
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

echo "# a moved target on a resume: (abort / continue) is still asked under --auto, each side's drops named line by line, with the choice-taker's answer shown"

moved_question="the (abort / continue) question"
moved_moment="before an abort or a continue"

# The bullet the session writes the question from, read from `moved=ask` on: what comes before it is
# `moved=continue`, taken without asking. The `--auto` paragraph of the bullet above it belongs to
# the `(continue / stop)` question, which the choice-taker rules, and is never read here.
moved_bullet="$(bullets_opening_on "$ticket" "\`stop=moved\`" | grep -F "moved=ask" | grep -F "(abort / continue)" | head -n 1)"
expect "ticket.md's stop=moved bullet words the (abort / continue) question on moved=ask" test -n "$moved_bullet"
flat=""
[ -z "$moved_bullet" ] || flat="${moved_bullet#*moved=ask}"
still_asked_with_the_answer_shown "ticket.md's stop=moved bullet, at moved=ask," "$moved_question" "$moved_moment"

# The question as the developer reads it: the bullet's fenced block, one side at a time.
asked=""
case "$flat" in *'```'*'(abort / continue)'*)
  asked="${flat#*\`\`\`}"
  asked="${asked%%\`\`\`*}"
  ;;
esac
expect "ticket.md's moved=ask question is a block closing on (abort / continue)" test -n "$asked"
abort_side=""
continue_side=""
case "$asked" in *"abort:"*" continue:"*)
  abort_side="${asked#*abort:}"
  abort_side="${abort_side%% continue:*}"
  continue_side="${asked#* continue:}"
  ;;
esac
# Read without `uncommitted=`, which would answer for `committed=`.
flat="${abort_side//uncommitted=/}"
carries_each "ticket.md's moved=ask question names what an abort drops line by line: the staged paths and the commits made by hand" \
  "one line per" "a line per" "line per" "per line" "one line each" "each on its own line" "each on a line" -- \
  "staged=" -- "committed="
flat="$abort_side"
carries "ticket.md's moved=ask question names the uncommitted work an abort drops" "uncommitted="
flat="$continue_side"
carries_each "ticket.md's moved=ask question names what a continue lands again line by line: the commits the developer removed" \
  "one line per" "a line per" "line per" "per line" "one line each" "each on its own line" "each on a line" -- \
  "dropped="

# A stopped Final integration asks the same question from its own bullet, which is the one the
# session is reading there.
flat="$(bullets_opening_on "$ticket" "\`verdict=integration\`" | grep -F "(abort / continue)" | head -n 1)"
still_asked_with_the_answer_shown "ticket.md's verdict=integration bullet of a stopped Final integration" \
  "$moved_question" "$moved_moment"

# mechanics.md: every bullet that names the question, wherever it sits.
mech_bullets="$(bullets_opening_on "$mech" "- " | grep -F "(abort / continue)")"
expect "mechanics.md has a bullet naming the (abort / continue) question" test -n "$mech_bullets"
n=0
while IFS= read -r flat; do
  n=$((n + 1))
  still_asked_with_the_answer_shown "mechanics.md's bullet $n naming (abort / continue)" \
    "$moved_question" "$moved_moment"
done <<<"$mech_bullets"

echo "# a refactoring whose exit test failed: the revert is still asked under --auto, with the choice-taker's answer shown"

revert_question="the revert question"
revert_moment="before the revert that deletes the branch"

# The step, found as the first numbered one that says the revert takes the branch and its commits
# for good. It is read in the paragraphs that speak of the revert, and in any other naming the flag:
# the one on the harness and the full-suite yeses hands those two to the choice-taker, and its
# `--auto` never answers for the revert.
revert_heading="$(awk '
  BEGIN { RS = "" }
  /^### [0-9]+\./ { heading = $0; next }
  heading != "" && /[Rr]evert/ && /branch/ && /every commit|irreversibl|cannot be undone/ { print heading; exit }
' "$refactoring")"
expect "refactoring.md has a step whose failed exit test asks before the revert that deletes the branch" \
  test -n "$revert_heading"
flat=""
if [ -n "$revert_heading" ]; then
  revert_step="$(item_holding "$refactoring" '### [0-9]+\.' "$revert_heading")"
  flat="$({
    paragraph_with <(printf '%s\n' "$revert_step") "evert" all
    paragraph_with <(printf '%s\n' "$revert_step") "--auto" all | grep -vE 'harness|full suite|remote run'
  } | awk '!seen[$0]++' | tr '\n' ' ' | tr -s ' ')"
fi
still_asked_with_the_answer_shown "refactoring.md's exit test step, on a failure," "$revert_question" "$revert_moment"

# The index, in what it says of the revert: its row when the table speaks for the flag, and its
# prose from the first sentence naming the revert on, so the sentences on the questions the
# choice-taker rules, which come before it, never answer for this one.
flat="$({
  grep -i "revert" <<<"$index_under_auto" | grep '^ *|'
  paragraph_with <(printf '%s\n' "$index") "--auto" all | grep -v '^|' | tr -s ' ' |
    while IFS= read -r paragraph; do
      awk 'BEGIN { RS = "\\.[ \n]" } /[Rr]evert/ { on = 1 } on { print }' <<<"$paragraph"
    done
} | tr '\n' ' ' | tr -s ' ')"
still_asked_with_the_answer_shown "refactoring.md's index of questions" "$revert_question" "$revert_moment"

echo "# a claim or a close on a remote tracker: the yes is still asked under --auto, every write listed in order, with the choice-taker's answer shown, and a no writes nothing"

reply="$here/../references/reply.md"
tracker_question="the tracker question"
tracker_moment="before a write to the remote tracker"

# The claim, in the bullet that says what it is on a remote tracker. The bullet opens on the local
# claim, so it is read from its first sentence naming the tracker on: a flag named for the local
# write never answers for the issue's.
claim_bullet="$(bullets_opening_on "$mech" "- " | grep -F "remote tracker" | grep -F "Yours: outward:" |
  grep -i "claim" | head -n 1)"
expect "mechanics.md has a bullet whose claim on a remote tracker waits for a yes under Yours: outward:" \
  test -n "$claim_bullet"
flat="$(awk 'BEGIN { RS = "\\.[ \n]" } /remote tracker/ { on = 1 } on { print }' <<<"$claim_bullet" |
  tr '\n' ' ' | tr -s ' ')"
still_asked_with_the_answer_shown "mechanics.md's claim on a remote tracker" "$tracker_question" "$tracker_moment"

# The close's one question, in the numbered item that carries the line: its list of writes and what
# a yes and a no do come along with it.
flat="$(item_holding <(passage_of "$mech" "## The close" "## ") '[0-9]+\.' "Yours: outward:" |
  tr '\n' ' ' | tr -s ' ')"
expect "mechanics.md's close has an item whose one question carries Yours: outward:" test -n "$flat"
carries_any "mechanics.md's close question lists every write the yes makes" \
  "every write" "each write" "all the writes" "all of the writes"
carries_any "mechanics.md's close question lists those writes in the order the yes makes them" \
  "in the order" "in that order" "in order" "in this order"
carries_any "mechanics.md's close makes no write to the tracker on a no" \
  "no makes none" "no that makes none" "no writes nothing" "nothing is written" "writes nothing" \
  "no write is made" "makes no write"
still_asked_with_the_answer_shown "mechanics.md's close on a remote tracker" "$tracker_question" "$tracker_moment"

# The Playbook restates both at its own steps, which are what the session is reading there: each is
# read in the paragraph that names the line.
outward_paragraphs="$(paragraph_with "$ticket" "Yours: outward:" all | tr -s ' ')"
flat="$(grep -i "claim" <<<"$outward_paragraphs" | grep -F "remote tracker" | head -n 1)"
still_asked_with_the_answer_shown "ticket.md's claim step, on a remote tracker," "$tracker_question" "$tracker_moment"
flat="$(grep -E "every write|each write|all the writes|all of the writes" <<<"$outward_paragraphs" | head -n 1)"
still_asked_with_the_answer_shown "ticket.md's close step, on a Ticket that is an issue," \
  "$tracker_question" "$tracker_moment"

# The reply contract, in the bullet that gives a write to a remote tracker its `outward` line.
flat="$(bullets_opening_on "$reply" "- " | grep -F "remote tracker" | grep -F "outward" | head -n 1)"
still_asked_with_the_answer_shown "reply.md's bullet on a write to a remote tracker" \
  "$tracker_question" "$tracker_moment"

# The home those steps send the reader to counts a tracker write among the questions still asked,
# and its table of the questions the choice-taker rules has no row for one.
section="$(passage_of "$forks" "### A run question under" "### ")"
flat="$(for anchor in "cannot be undone" "leaves the machine" "irreversible" "still asked" \
  "still asks" "still put"; do
  paragraph_with <(printf '%s\n' "$section") "$anchor" all
done | awk '!seen[$0]++' | tr '\n' ' ' | tr -s ' ')"
carries_any "forks.md counts a write to a remote tracker among the questions still asked under --auto" \
  "remote tracker"
flat="$(grep '^|' <<<"$section" | grep -iE 'tracker|issue')"
expect "forks.md's table of run questions has no row for a write to a remote tracker" test -z "$flat"

echo "# nothing ruled under --auto: a Design fork takes the unruled stop as without the flag, a question still asked carries no answer and one line for the reason, and no other agent is forked"

unruled_stop_under_auto() { # $1 the place, $2 its section: in the paragraphs of it naming `--auto`, a Design fork nothing ruled stops the run as without the flag
  flat="$(paragraph_with <(printf '%s\n' "$2") "--auto" all | tr '\n' ' ' | tr -s ' ')"
  if [ -z "$flat" ]; then
    fail "$1 says what --auto does to a Design fork no choice-taker ruled (no paragraph of it names --auto)"
    return
  fi
  carries_each "$1 has a Design fork no choice-taker ruled stop the run under --auto as without the flag" \
    "stop" -- \
    "as without it" "as without the flag" "the flag as without" "exactly as without" "with or without" \
    "changes nothing" "adds nothing" "adds no route" "no route" "all the same" "the same way" \
    "the same stop" "still stops" "still takes" "unchanged" "hands nothing over" "never hands" \
    "rules nothing" "whatever the flag" "flag or no flag"
}

# The three places a session reads when no Ruling came back on a Design fork, each found by what it
# carries: the script that links the agent, the check's own `Losing criterion:` line, and the clause
# the unruled stop puts in its /discuss command. The run-question section's closing sentence on a
# Design fork sits in another section and never answers for the one the session is reading.
no_fork_section="$(item_holding "$forks" '### ' "link-skills.sh")"
expect "forks.md carries the section on a choice-taker that cannot be forked, naming what links it" \
  test -n "$no_fork_section"
unruled_stop_under_auto "forks.md's section on a choice-taker that cannot be forked" "$no_fork_section"
flat="$(tr '\n' ' ' <<<"$no_fork_section" | tr -s ' ')"
carries_each "forks.md forks no other agent in the choice-taker's place when the Agent tool is withheld or the agent is not listed" \
  "withheld" -- "not listed" "lists no" "no \`choice-taker\` listed" -- \
  "another agent" "other agent" "general-purpose" "general agent"

check_section="$(item_holding "$forks" '### ' "\`Losing criterion:\`")"
expect "forks.md carries the section checking a choice-taker's return before a side is read from it" \
  test -n "$check_section"
unruled_stop_under_auto "forks.md's section checking the choice-taker's return" "$check_section"

unruled_section="$(item_holding "$forks" '### ' "Design fork no choice-taker ruled")"
expect "forks.md carries the section on the stop of a Design fork no choice-taker ruled" \
  test -n "$unruled_section"
unruled_stop_under_auto "forks.md's section on the unruled stop" "$unruled_section"

# A question still asked under the flag whose choice-taker gave no usable return: read in the
# paragraphs that speak of both, and in a bullet list directly under one. The section's closing
# bullets say this of a question the choice-taker would have ruled, which goes back to the developer
# either way, and they never answer for a question whose message was to carry the return.
section="$(passage_of "$forks" "### A run question under" "### ")"
flat="$(asked_keys="$(printf '%s\n' "cannot be undone" "leaves the machine" "irreversible" \
  "remote tracker" "still asked" "still asks" "still put" "asked all the same" "reserved")" \
failed_keys="$(printf '%s\n' "withheld" "not listed" "lists no" "no \`choice-taker\` listed" \
  "cannot be forked" "can be forked" "not linked" "no Ruling" "not a Ruling" "fails" "failed" \
  "neither \`settled\`" "unusable" "no usable")" \
  awk '
    function any(text, keys, n,   i) { for (i = 1; i <= n; i++) if (index(text, keys[i])) return 1; return 0 }
    BEGIN {
      RS = ""
      na = split(ENVIRON["asked_keys"], asked, "\n")
      nf = split(ENVIRON["failed_keys"], failed, "\n")
    }
    {
      gsub(/\n[ \t]*/, " ")
      hit = any($0, asked, na) && any($0, failed, nf)
      if (hit || (prev && $0 ~ /^ *- /)) print
      prev = hit
    }
  ' <<<"$section" | tr '\n' ' ' | tr -s ' ')"
if [ -z "$flat" ]; then
  fail "forks.md says what a question still asked under --auto carries when its choice-taker cannot be forked or its return is no Ruling (no paragraph of the section speaks of both)"
else
  carries_each "forks.md covers, for a question still asked under --auto, a choice-taker that cannot be forked and a return that is no Ruling" \
    "withheld" "not listed" "lists no" "listed" "cannot be forked" "can be forked" "not linked" -- \
    "no Ruling" "not a Ruling" "fails" "failed" "neither" "unusable" "no usable"
  carries_any "forks.md has that question asked with no answer carried on it" \
    "no answer" "without an answer" "without the answer" "carries none" "carries nothing" \
    "nothing rides" "rides nothing" "no return rides" "no Ruling rides" "nothing above the question" \
    "with nothing above" "no lines above" "shows no" "shows nothing" "nothing is shown" \
    "nothing shown" "no \`Side:\`" "no side" "no Ruling to confirm" "nothing to confirm" \
    "decides from scratch" "decide from scratch"
  carries_each "forks.md has that question name the reason in one line" \
    "one line" "a line" "single line" -- "reason" "why" "which of" "which branch" "says which"
  carries_any "forks.md has no side read out of a return that is no Ruling on that question" \
    "takes no answer" "takes no side" "reads no side" "reads no answer" "no side is read" \
    "no side read" "no answer is read" "no answer read" "no side out of" "no answer out of" \
    "no side is taken" "no answer is taken" "nothing out of the return" "nothing is read" \
    "reads nothing" "never reads a side" "no side into" "not read as an answer"
  carries_any "forks.md forks no other agent in the choice-taker's place on that question" \
    "no other agent" "another agent" "other agent" "general-purpose" "general agent" \
    "in its place" "in the \`choice-taker\`'s place" "in the choice-taker's place"
  carries_any "forks.md never forks the choice-taker a second time on that question" \
    "second time" "second fork" "a second" "forked again" "forks again" "fork it again" \
    "re-fork" "retry" "retries" "only once" "once only" "twice"
fi

[ "$fails" -eq 0 ] && exit 0
exit 1
