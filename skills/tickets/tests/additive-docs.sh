#!/usr/bin/env bash
# additive-docs.sh: what docs/tickets.md tells a developer who reads it after a stopped `do` run, on
# a feature that already has Tickets. The stop is keyed on coverage: it fires when the open Tickets
# cover the whole Spec, and its message says nothing was cut, lists each Ticket with its status, says
# a recut needs them closed or deleted first, and gives no next command. Open Tickets that leave
# something uncovered are no stop: the run cuts only what is uncovered, numbers the new Tickets
# after the feature's last one, moves the criterion out of the stopped Ticket, adds the Blocked by
# edge to it, and renumbers or deletes none. A declined addition publishes nothing and the finding
# stays in the Spec.
# The developer acts on the page: one that still says existing Tickets stop the run has them close
# or delete open Tickets by hand, and the work those Tickets carry goes with them.
# The page is prose a person reads, which no script carries, so each outcome is proven over the
# passages that carry it. skills/tickets/evals/README.md is the list a developer picks an eval case
# from, so its rows have to say what the three additive cases and the stop case grade.
# Run: bash skills/tickets/tests/additive-docs.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
doc="$here/../../../docs/tickets.md"
evals="$here/../evals/README.md"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

mapfile -t whole_spec < <(whole_spec_phrasings)
mapfile -t nothing_cut < <(nothing_cut_phrasings)
mapfile -t with_status < <(with_status_phrasings)
mapfile -t recut < <(recut_phrasings)
mapfile -t no_next_command < <(no_next_command_phrasings)
mapfile -t only_uncovered < <(only_uncovered_phrasings)
mapfile -t moved_out < <(moved_out_phrasings)
mapfile -t edge_added < <(edge_added_phrasings)
mapfile -t never < <(never_phrasings)
mapfile -t deleted < <(deleted_phrasings)
mapfile -t declined < <(declined_phrasings)
mapfile -t on_open_tickets < <(on_open_tickets_phrasings)
mapfile -t nothing_published < <(nothing_published_phrasings)
mapfile -t finding_kept < <(finding_kept_phrasings)
mapfile -t later_run < <(later_run_phrasings)
open_tickets=("open ticket" "tickets still open" "tickets that are open")
# What marks a paragraph as speaking of the additive mode.
additive_marks=("uncovered" "additive" "an addition" "the addition" "open ticket")

# Every phrasing is matched in lower case, since the prose may write Ticket and Spec.
tr '[:upper:]' '[:lower:]' <"$doc" >"$tmp/page.md" 2>/dev/null
passage_of "$tmp/page.md" "## what it does" "## " >"$tmp/opening.md"
passage_of "$tmp/page.md" "## path, slice, stop" "## " >"$tmp/stops.md"
passage_of "$tmp/page.md" "## common questions" "## " >"$tmp/questions.md"

# A passage that lists the stops names the verdict among them, so a paragraph naming a stop, the
# verdict and tickets is one where tickets are listed as a stop.
stop_lists_key_on_coverage() { # $1 label, $2 a lowercased section: every paragraph of it listing tickets among the stops says what they cover
  local label="$1" paragraph bad=0
  while IFS= read -r paragraph; do
    grep -qF -- "cover" <<<"$paragraph" || bad=1
  done < <(paragraph_with "$2" "stop" all | grep -F -- "verdict" | grep -F -- "ticket")
  if [ "$bad" = 0 ]; then ok "$label"; else fail "$label"; fi
}

echo "# docs/tickets.md / ## What it does: the stop is keyed on coverage, and open tickets get what is missing"
flat="$(tr '\n' ' ' <"$tmp/opening.md" | tr -s ' ')"
expect "the page opens on what the skill does" test -n "${flat// /}"
carries_each "the stop it names is the open tickets covering the whole spec" \
  "${open_tickets[@]}" -- \
  "cover" -- \
  "${whole_spec[@]}"
stop_lists_key_on_coverage "no passage of it lists tickets as a stop without what they cover" "$tmp/opening.md"
carries_any "a feature with open tickets gets only what they leave uncovered" "${only_uncovered[@]}"

echo "# docs/tickets.md / ## Path, slice, stop: the stop row on tickets"
# The stop rows whose condition names tickets, read cell by cell: the other rows stop on the verdict
# or the journey, and a sentence of theirs cannot answer for this one.
rows="$(awk -F'|' '/^\|/ && $2 ~ /ticket/' "$tmp/stops.md")"
condition="$(awk -F'|' '{ print $2 }' <<<"$rows" | tr '\n' ' ' | tr -s ' ')"
message="$(awk -F'|' '{ print $3 }' <<<"$rows" | tr '\n' ' ' | tr -s ' ')"
flat="$condition"
expect "a row of the section is conditioned on tickets" test -n "${flat// /}"
carries_each "the condition is the open tickets covering the whole spec" \
  "${open_tickets[@]}" -- \
  "cover" -- \
  "${whole_spec[@]}"
label="no row is conditioned on tickets merely existing for the feature"
bad=0
while IFS= read -r cell; do
  [ -z "${cell// /}" ] || grep -qF -- "cover" <<<"$cell" || bad=1
done < <(awk -F'|' '{ print $2 }' <<<"$rows")
if [ -n "${rows// /}" ] && [ "$bad" = 0 ]; then ok "$label"; else fail "$label"; fi

# What the developer reads on that stop may sit in the row or in a paragraph of the section that
# speaks of what the tickets cover.
flat="$message $(paragraph_with "$tmp/stops.md" "cover" all | grep -v '^|' | tr '\n' ' ' | tr -s ' ')"
carries_any "the message says nothing was cut" "${nothing_cut[@]}"
carries_each "each existing ticket is listed with its status" \
  "each" "every" -- \
  "ticket" -- \
  "${with_status[@]}"
carries_each "a recut needs them closed or deleted first" \
  "close" -- \
  "delete" -- \
  "${recut[@]}"
carries_any "no next command follows" "${no_next_command[@]}"

echo "# docs/tickets.md: open tickets that leave something of the spec uncovered"
for mark in "${additive_marks[@]}"; do paragraph_with "$tmp/page.md" "$mark" all; done |
  sort -u >"$tmp/additive.txt"
flat="$(tr '\n' ' ' <"$tmp/additive.txt" | tr -s ' ')"
expect "the page speaks of a feature whose open tickets leave something uncovered" test -n "${flat// /}"
carries_any "the run cuts only what is uncovered" "${only_uncovered[@]}"
carries_each "it is reached from the /tickets line a stopped do run hands over" \
  "/tickets" -- \
  "/do" "\`do\`" -- \
  "stopped" "stops on" "stop of" "its stop" "hands" "handed" "ends on" "left by" "prints" "printed"
carries_each "the new tickets are numbered after the feature's last one" \
  "number" -- \
  "after" "follow" "next" "continu" "onward" "above" "on from" -- \
  "last" "highest" "greatest" "largest"
carries_each "the criterion moves out of the stopped ticket into the new one" \
  "criteri" -- \
  "${moved_out[@]}" -- \
  "new ticket" "new one" "new file" "ticket that takes it" "ticket taking it" "added ticket"
carries_each "the stopped ticket gets the blocked by edge" \
  "blocked by" -- \
  "${edge_added[@]}"
carries_each "no existing ticket is renumbered" \
  "renumber" -- \
  "${never[@]}"
carries_each "and none is deleted" \
  "${deleted[@]}" -- \
  "${never[@]}"

echo "# docs/tickets.md: a declined addition"
for word in "${declined[@]}"; do paragraph_with "$tmp/page.md" "$word" all; done |
  sort -u >"$tmp/declines.txt"
grep -F -f <(printf '%s\n' "${on_open_tickets[@]}") "$tmp/declines.txt" >"$tmp/addition-declined.txt"
flat="$(tr '\n' ' ' <"$tmp/addition-declined.txt" | tr -s ' ')"
expect "the page says what a no does on a feature with open tickets" test -n "${flat// /}"
carries_any "a declined addition publishes nothing" "${nothing_published[@]}"
# The finding may be given a paragraph of its own beside the no.
flat="$flat $(paragraph_with "$tmp/page.md" "finding" all | tr '\n' ' ' | tr -s ' ')"
carries_each "the finding stays in the spec" \
  "finding" -- \
  "spec" -- \
  "${finding_kept[@]}"
carries_each "for a later run to cut from" \
  "finding" -- \
  "${later_run[@]}"

echo "# docs/tickets.md / ## Common questions: the answer on existing tickets"
flat="$(tr '\n' ' ' <"$tmp/questions.md" | tr -s ' ')"
expect "the page answers common questions" test -n "${flat// /}"
carries_each "the stop it names is the open tickets covering the whole spec" \
  "${open_tickets[@]}" -- \
  "cover" -- \
  "${whole_spec[@]}"
stop_lists_key_on_coverage "no answer lists tickets as a stop without what they cover" "$tmp/questions.md"

echo "# skills/tickets/evals/README.md: the rows of the additive cases and of the stop"
tr '[:upper:]' '[:lower:]' <"$evals" >"$tmp/evals.md" 2>/dev/null
flat="$(checks_of adds-only-the-missing-tickets)"
expect "adds-only-the-missing-tickets has a row" test -n "${flat// /}"
carries_each "which says the breakdown holds the new tickets for what no open ticket covers" \
  "uncovered" "not covered" "covers" "missing" "finding" -- \
  "new ticket" "ticket it adds" "tickets it adds" "added ticket" "04"
flat="$(checks_of auto-adds-the-missing-tickets)"
expect "auto-adds-the-missing-tickets has a row" test -n "${flat// /}"
carries_each "which says the new ticket is published and the stopped one edited" \
  "publish" "written" "writes" "wrote" -- \
  "new ticket" "numbered" "04" -- \
  "criteri" "blocked by"
flat="$(checks_of auto-declined-addition-publishes-nothing)"
expect "auto-declined-addition-publishes-nothing has a row" test -n "${flat// /}"
carries_each "which says nothing is published and the finding stays" \
  "${nothing_published[@]}" "no ticket file" "no new ticket" "no file" -- \
  "finding"
flat="$(checks_of existing-tickets-stop)"
expect "existing-tickets-stop has a row" test -n "${flat// /}"
carries_each "which describes the stop on open tickets covering the whole spec" \
  "cover" -- \
  "${whole_spec[@]}"

exit $((fails > 0))
