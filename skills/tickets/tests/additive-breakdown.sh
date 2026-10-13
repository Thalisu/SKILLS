#!/usr/bin/env bash
# additive-breakdown.sh: what SKILL.md has the session do on a feature whose open Tickets leave
# something of the Spec uncovered: the run does not stop, it cuts only what is uncovered, and the
# breakdown shows only the new Tickets, each numbered after the feature's last one, with its Build
# repository and the fields of any breakdown, then the one question.
# The session decides this from what it read of the feature folder, which no script carries, so the
# decision is proven over the two passages that carry it. The eval case adds-only-the-missing-tickets
# grades it on a live run: its grader has to ask for that same breakdown, and its fixture has to be a
# feature with a published Ticket and a finding no Ticket covers, or the run it grades is another one.
# Run: bash skills/tickets/tests/additive-breakdown.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/../SKILL.md"
case_dir="$here/../evals/adds-only-the-missing-tickets"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

goes_on=(
  "goes on" "go on" "carries on" "continues" "proceeds" "keeps going" "does not stop"
  "is not stopped" "run moves on" "moves on to"
)
mapfile -t only_uncovered < <(only_uncovered_phrasings)
only_new=(
  "only the new ticket" "only new ticket" "only the ticket it adds" "only the tickets it adds"
  "only the added ticket" "only the tickets the run adds" "only the tickets this run adds"
  "only the tickets being added" "only the missing ticket" "only the tickets it cut"
  "only the tickets this run cut" "new tickets only" "new ticket only" "new tickets alone"
  "only what is new" "only the new ones" "only the one new ticket" "only one new ticket"
  "only one ticket" "only the tickets cut by this run" "only the tickets cut in this run"
)
never_recut=(
  "never recut" "not recut" "never re-cut" "not re-cut" "no recut" "never a recut" "not a recut"
  "never cut again" "not cut again" "without recutting" "nothing is recut" "none of them is recut"
  "none is recut" "never cut a second time" "not cut a second time" "no full recut"
  "never the whole spec" "recut none" "recuts none" "recuts nothing"
)
any_fields=(
  "same fields" "same field" "every field" "each field" "all the fields" "all fields"
  "fields of any breakdown" "fields any breakdown" "fields a breakdown" "fields above"
  "fields listed above" "usual fields" "fields every ticket" "fields of every ticket"
)
one_question=(
  "one question" "single question" "same question" "closing question" "approval question"
  "the question"
)
mapfile -t changes_it < <(changed_phrasings)
mapfile -t moved_out < <(moved_out_phrasings)
mapfile -t edge_added < <(edge_added_phrasings)
mapfile -t untouched < <(untouched_phrasings)

echo "# SKILL.md / ## 1: open Tickets that leave something uncovered are no stop"
# shellcheck disable=SC2034 # the carries_* assertions read $flat
flat="$(passage_of "$skill" "**Open tickets and what they cover.**" "## 2. Explore the code" |
  tr '\n' ' ' | tr -s ' ')"
flat="${flat,,}"
expect "the ground step reads what the open tickets cover" test -n "${flat// /}"
carries_each "the run goes on when the open tickets leave something uncovered" \
  "uncovered" "not covered" "no open ticket covers" -- \
  "${goes_on[@]}"
carries_any "it cuts only what is uncovered" "${only_uncovered[@]}"

echo "# SKILL.md / ## 4: the breakdown on a feature with open Tickets"
passage_of "$skill" "## 4. Put the breakdown to the user" "## 5. Publish" >"$tmp/step4.md"
flat="$(passage_of "$tmp/step4.md" "### On a feature with open tickets" "##" | tr '\n' ' ' | tr -s ' ')"
flat="${flat,,}"
expect "the breakdown step has a passage on a feature with open tickets" test -n "${flat// /}"
carries_any "the breakdown lists only the new tickets" "${only_new[@]}"
carries_any "the existing tickets are never recut" "${never_recut[@]}"
carries_each "each new ticket is numbered after the feature's last one" \
  "number" -- \
  "after" "follow" "next" "continu" "onward" "above" -- \
  "last" "highest" "greatest" "largest"
carries "each new ticket carries its build repository" "build repository"
carries_any "each new ticket carries the fields of any breakdown" "${any_fields[@]}"
carries_any "the message still ends on the one question" "${one_question[@]}"

echo "# SKILL.md / ## 4: the existing Tickets the cut changes, and the ones it leaves alone"
# The yes approves an edit of a Ticket another run may have claimed, so the edit is on the page the
# developer answers from: what leaves the Ticket, where it goes, and what the Ticket now waits on.
carries_each "the breakdown shows each existing ticket the cut changes" \
  "existing ticket" "open ticket" "published ticket" "ticket already" "tickets already" -- \
  "${changes_it[@]}"
carries_each "with the criterion moved out of it" \
  "criteri" -- \
  "${moved_out[@]}"
carries_each "quoted, and with the new ticket it moves to" \
  "quot" "verbatim" "word for word" "written out" "in full" "as written" -- \
  "moved to" "moves to" "goes to" "handed to" "handed over to" "now sits in" "now lives in" \
  "ticket it moves" "ticket it moved" "ticket that takes it" "ticket taking it" "its new ticket"
carries_each "and with the blocked by edge added to it" \
  "blocked by" -- \
  "${edge_added[@]}"
carries_any "every other existing ticket is named as untouched" "${untouched[@]}"
at_moved="$(first_at "${moved_out[@]}")"
at_untouched="$(first_at "${untouched[@]}")"
label="the changed and the untouched tickets are shown before the one question"
if [ "$at_moved" -gt 0 ] && [ "$at_untouched" -gt 0 ]; then
  passage="$flat"
  flat="${flat:$((at_moved > at_untouched ? at_moved : at_untouched))}"
  carries_any "$label" "${one_question[@]}"
  flat="$passage"
else fail "$label (moved criterion at $at_moved, untouched at $at_untouched)"; fi

echo "# evals/adds-only-the-missing-tickets: the prompt"
prompt="$(cat "$case_dir/prompt.md" 2>/dev/null)"
expect "the prompt types /tickets with a spec" grep -qE '^/tickets +[^[:space:]]' <<<"$prompt"
label="the prompt carries no --auto, so the breakdown is put to the developer"
if [ -n "$prompt" ] && ! grep -qF -- "--auto" <<<"$prompt"; then ok "$label"; else fail "$label"; fi

echo "# evals/adds-only-the-missing-tickets: the grader asks for the same breakdown"
grader="$case_dir/graders/breakdown-shows-only-the-new-tickets.md"
expect "the case holds the breakdown-shows-only-the-new-tickets grader" test -f "$grader"
# shellcheck disable=SC2034 # field reads the frontmatter the caller left in $out
out="$(frontmatter "$grader" 2>/dev/null)"
expect "the grader is judged by a model" test "$(field type)" = "llm"
flat="$(field criteria | tr '\n' ' ' | tr -s ' ')"
flat="${flat,,}"
expect "the grader carries its criteria" test -n "${flat// /}"
carries_any "the run did not stop" \
  "did not stop" "does not stop" "not stop" "no stop" "went on" "goes on" "without stopping" \
  "instead of stopping" "rather than stopping" "did not refuse" "not refused" "not end on the stop"
carries_any "the breakdown shows only the new tickets" "${only_new[@]}"
carries_each "numbered after the last existing one" \
  "number" -- \
  "after" "follow" "next" "continu" -- \
  "last" "highest" "existing"
carries "each with its build repository" "build repository"
carries_any "and the usual fields" "${any_fields[@]}" "acceptance criteria" "estimate"
carries_each "the message ends on the one approval question" \
  "${one_question[@]}" -- \
  "ends" "end " "last line" "final line" "closes" "closing"

echo "# evals/adds-only-the-missing-tickets: a grader asks for the changed and the untouched tickets"
grader="$case_dir/graders/existing-tickets-shown-as-changed-or-untouched.md"
expect "the case holds the existing-tickets-shown-as-changed-or-untouched grader" test -f "$grader"
# shellcheck disable=SC2034 # field reads the frontmatter the caller left in $out
out="$(frontmatter "$grader" 2>/dev/null)"
expect "that grader is judged by a model" test "$(field type)" = "llm"
flat="$(field criteria | tr '\n' ' ' | tr -s ' ')"
flat="${flat,,}"
expect "that grader carries its criteria" test -n "${flat// /}"
carries_each "ticket 02 is shown as changed" \
  "02" -- \
  "${changes_it[@]}"
carries_each "with the email criterion moved out of it to the new ticket" \
  "email" -- \
  "criteri" -- \
  "${moved_out[@]}" -- \
  "new ticket" "04"
carries_each "and a blocked by edge to the new ticket added to it" \
  "blocked by" -- \
  "${edge_added[@]}"
carries_each "tickets 01 and 03 are named as untouched" \
  "01" -- \
  "03" -- \
  "${untouched[@]}"

echo "# evals/adds-only-the-missing-tickets: the fixture is an open feature with something uncovered"
fixture="$tmp/fixture"
mkdir "$fixture"
scaffold_rc=0
lay_scaffold "$case_dir/case.yaml" "$fixture" || scaffold_rc=$?
spec="$(find "$fixture/.scratch" -name spec.md 2>/dev/null | head -n 1)"
feature="$(dirname "${spec:-$fixture/none/spec.md}")"
mapfile -t tickets < <(find "$feature/issues" -maxdepth 1 -name '*.md' 2>/dev/null | sort)
label="the scaffold lays a feature folder with a spec"
if [ "$scaffold_rc" = 0 ] && [ -n "$spec" ]; then ok "$label"; else
  fail "$label (scaffold exit $scaffold_rc)"
  echo "      extract: $(tail -1 "$tmp/extract.log")"
  echo "      scaffold: $(tail -1 "$tmp/scaffold.log")"
fi
expect "the prompt names that feature" grep -qF -- "$(basename "$feature")" <<<"$prompt"
expect "the feature holds at least one published ticket" test "${#tickets[@]}" -gt 0
# The breakdown shows a Build repository only on a spec with a Repositories section, so a fixture
# without one is a run the grader's criteria cannot pass.
expect "the spec lists its repositories" grep -qx -- "## Repositories" "${spec:-/dev/null}"

finding="$(passage_of "${spec:-/dev/null}" "## Implementation Decisions" "## " |
  grep -E '^- Moved by the run on Ticket .+ at the Plan step: .+\. Belongs to: .+\.$' | head -n 1)"
expect "the spec's Implementation Decisions hold a finding line a stopped do run wrote" test -n "$finding"
behaviour="$(sed -E 's/^- Moved by the run on Ticket .* at the Plan step: (.*)\. Belongs to: [^.]*\.$/\1/' <<<"$finding")"
label="no published ticket carries the finding's behaviour, so it is uncovered"
if [ -n "$finding" ] && [ "${#tickets[@]}" -gt 0 ] && ! grep -qiF -- "$behaviour" "${tickets[@]}"; then
  ok "$label"
else fail "$label"; fi

# The grader above asks for a changed Ticket and for untouched ones, so the fixture has to hold both:
# the Ticket the finding names, still carrying the criterion that leaves it, and another beside it.
named="$(sed -nE 's/^- Moved by the run on Ticket ([0-9]+).*/\1/p' <<<"$finding")"
changed="$(find "$feature/issues" -maxdepth 1 -name "${named:-none}-*.md" 2>/dev/null | head -n 1)"
expect "the ticket the finding names is published in the feature" test -n "$changed"
expect "that ticket still holds the email criterion the cut moves out" \
  grep -qiE '^- \[ \] .*email' "${changed:-/dev/null}"
expect "another published ticket is there to be named untouched" test "${#tickets[@]}" -gt 1

exit $((fails > 0))
