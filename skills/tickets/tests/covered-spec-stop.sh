#!/usr/bin/env bash
# covered-spec-stop.sh: what SKILL.md's `## 1. Ground` has the session do on a feature whose open
# Tickets cover the whole Spec: the run writes nothing and ends on one message saying nothing was
# cut because the open Tickets cover the whole Spec, listing each existing Ticket with its status,
# saying that whoever wants a recut closes or deletes them first, with no next command.
# The stop is taken by the session from what it read of the feature folder, which no script
# carries, so the decision is proven over the stop row that carries it. The eval case
# existing-tickets-stop grades the stop on a live run: its grader has to ask for that same message,
# and its fixture has to be a Spec its Tickets cover whole, or the run it grades is another one.
# Run: bash skills/tickets/tests/covered-spec-stop.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/../SKILL.md"
case_dir="$here/../evals/existing-tickets-stop"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

whole_spec=(
  "whole spec" "entire spec" "all of the spec" "all the spec" "spec whole" "spec in full"
  "the spec entirely" "everything the spec" "everything in the spec" "every path" "each path"
  "every story" "nothing the spec holds" "nothing in the spec" "left uncovered" "nothing uncovered"
  "leaves nothing" "leave nothing"
)
nothing_cut=(
  "nothing was cut" "nothing is cut" "nothing cut" "nothing new was cut" "nothing new is cut"
  "nothing to cut" "no ticket was cut" "no ticket is cut" "no new ticket" "cut nothing"
  "cuts nothing"
)
with_status=(
  "its status" "their status" "status of each" "status of every" "with status" "the status"
  "own status"
)
recut=("recut" "re-cut" "cut again" "new cut")
no_next_command=(
  "no next command" "no command follows" "no next step" "without a next command" "no \`/do\`"
  "no /do" "names no command" "no next-step" "no command to run" "no next line"
  "suggests no command" "offers no command" "no follow-up command" "no command after"
  "not name a next command" "no command is named" "no command was named"
)

# The stop rows whose condition names tickets, read cell by cell: the other rows stop on the verdict
# or the journey, and a sentence of theirs cannot answer for this one. Every phrasing is matched in
# lower case, since the prose may write Ticket and Spec.
stops="$(passage_of "$skill" "**Stops.**" "## 2. Explore the code")"
rows="$(awk -F'|' '/^\|/ && tolower($2) ~ /ticket/' <<<"$stops")"
condition="$(awk -F'|' '{ print $2 }' <<<"$rows" | tr '\n' ' ' | tr -s ' ')"
condition="${condition,,}"
message="$(awk -F'|' '{ print $3 }' <<<"$rows" | tr '\n' ' ' | tr -s ' ')"
message="${message,,}"

echo "# SKILL.md / ## 1: the stop is taken when the open Tickets cover the whole Spec"
flat="$condition"
expect "a stop row of the ground step is conditioned on tickets" test -n "${flat// /}"
carries_each "the condition is the open tickets covering the whole spec, not tickets merely existing" \
  "open ticket" "tickets still open" "tickets that are open" -- \
  "cover" -- \
  "${whole_spec[@]}"

echo "# SKILL.md / ## 1: the message of that stop"
flat="$message"
carries_any "the message says nothing was cut" "${nothing_cut[@]}"
carries_each "because the open tickets cover the whole spec" \
  "cover" -- \
  "${whole_spec[@]}"
carries_each "each existing ticket is listed with its status" \
  "each" "every" -- \
  "ticket" -- \
  "${with_status[@]}"
carries_each "whoever wants a recut closes or deletes them first" \
  "close" -- \
  "delete" -- \
  "${recut[@]}"
carries_any "no next command follows" "${no_next_command[@]}"

# The paragraph above the table speaks for every stop, so nothing written may be said there or in
# the row itself.
flat="$(paragraph_with <(printf '%s\n' "$stops") "**Stops.**") $message"
flat="${flat,,}"
carries_any "the stop writes nothing" \
  "before anything is written" "nothing is written" "nothing written" "writes nothing" \
  "nothing was written" "no file is written" "without writing"

echo "# evals/existing-tickets-stop: the grader asks for the same message"
grader="$case_dir/graders/stops-lists-existing.md"
expect "the case holds the stops-lists-existing grader" test -f "$grader"
# shellcheck disable=SC2034 # field reads the frontmatter the caller left in $out
out="$(frontmatter "$grader" 2>/dev/null)"
flat="$(field criteria | tr '\n' ' ' | tr -s ' ')"
flat="${flat,,}"
expect "the grader carries its criteria" test -n "${flat// /}"
carries_any "the run's message says nothing was cut" "${nothing_cut[@]}"
carries_each "because the open tickets cover the whole spec" \
  "cover" -- \
  "${whole_spec[@]}"
carries_each "each existing ticket is listed with its status" \
  "each" "every" "listing" "lists" "listed" -- \
  "${with_status[@]}" "status"
carries_each "they are closed or deleted before a recut" \
  "close" -- \
  "delete" -- \
  "${recut[@]}"
carries_any "the message carries no next command" "${no_next_command[@]}"
carries_each "no file was created, and no existing ticket was edited or renumbered" \
  "no new file" "no file was created" "no file created" "created no file" "nothing was written" \
  "no new ticket file" -- \
  "edited" "changed" "modified" "rewritten" -- \
  "renumber"

echo "# evals/existing-tickets-stop: the fixture's Tickets cover every Path of its Journey"
# Laid the way scripts/run-eval.sh lays it. A ticket of a journey names the path it realises
# (.agents/formats/ticket-format.md), and a fold names every one of its paths, so a path no ticket
# names is a path left uncovered.
fixture="$tmp/fixture"
mkdir "$fixture"
scaffold_rc=0
lay_scaffold "$case_dir/case.yaml" "$fixture" || scaffold_rc=$?
expect "the scaffold lays the fixture" test "$scaffold_rc" = 0

journey="$(find "$fixture/.scratch" -name journey.md 2>/dev/null | head -n 1)"
issues="$(dirname "${journey:-$fixture/none/journey.md}")/issues"
mapfile -t paths < <(sed -n 's/^## Path [0-9]*: *//p' "${journey:-/dev/null}")
mapfile -t tickets < <(find "$issues" -maxdepth 1 -name '*.md' 2>/dev/null | sort)
expect "the fixture's journey walks at least one path" test "${#paths[@]}" -gt 0
expect "the fixture holds at least one published ticket" test "${#tickets[@]}" -gt 0
for name in "${paths[@]}"; do
  label="a published ticket names the path \"$name\""
  if [ "${#tickets[@]}" -gt 0 ] && grep -qiF -- "$name" "${tickets[@]}"; then ok "$label"; else fail "$label"; fi
done
for file in "${tickets[@]}"; do
  expect "$(basename "$file") carries a status line" grep -qE '^\*\*Status:\*\* *[a-z]' "$file"
done

exit $((fails > 0))
