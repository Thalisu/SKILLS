#!/usr/bin/env bash
# typed-location-docs.sh: what docs/tickets.md tells a developer who reads it after a stopped `do`
# run that could name a repository and not its location. The command they type carries the
# repository and its location after the spec, and `tickets` writes that location into the spec's
# Repositories list, so no file is edited by hand. A location that is owed and was not typed stops
# the run on one message naming the repository, with nothing written. A typed location that is
# missing on this machine or is not a git repository is written all the same, stops nothing, and is
# named in the close in a line of its own saying which of the two it is.
# The developer acts on the page: one that shows `/tickets <spec>` alone has them edit the Spec by
# hand, be surprised by a run that ends on a stop, or miss that what they typed cannot be built in.
# The page is prose a person reads, which no script carries, so each outcome is proven over the
# passages that carry it.
# Run: bash skills/tickets/tests/typed-location-docs.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
doc="$here/../../../docs/tickets.md"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

mapfile -t pair_form < <(pair_form_phrasings)
mapfile -t owed_location < <(owed_location_phrasings)
mapfile -t none_typed < <(none_typed_phrasings)
mapfile -t location_missing < <(location_missing_phrasings)
mapfile -t not_there < <(not_there_phrasings)
mapfile -t not_git < <(not_git_phrasings)
mapfile -t written_all_the_same < <(written_all_the_same_phrasings)
mapfile -t does_not_stop < <(does_not_stop_phrasings)
mapfile -t own_line < <(own_line_phrasings)
mapfile -t nothing_written < <(nothing_written_phrasings)

# Every phrasing is matched in lower case, since the prose may write Spec and Repositories.
tr '[:upper:]' '[:lower:]' <"$doc" >"$tmp/page.md" 2>/dev/null
passage_of "$tmp/page.md" "## when to reach for it" "## " >"$tmp/commands.md"
passage_of "$tmp/page.md" "## path, slice, stop" "## " >"$tmp/stops.md"
passage_of "$tmp/page.md" "## the additive run" "## " >"$tmp/additive.md"

# A table row is one thing the section says, and so is a paragraph outside its tables: a guarantee
# has to sit in the units that speak of it, never in a neighbour that speaks of something else.
units_with() { # $1 a lowercased section, $2 a fixed string: its table rows and its paragraphs carrying it, on one line
  {
    grep '^|' "$1"
    paragraph_with "$1" "$2" all | grep -v '^|'
  } | grep -F -- "$2" | tr '\n' ' ' | tr -s ' '
}

echo "# docs/tickets.md / ## When to reach for it: the command a stopped do run hands over"
# The rows of the command table that speak of a `/do` run: the other rows cut a spec from scratch or
# name another skill, and cannot answer for what is typed after a stop.
flat="$(grep '^|' "$tmp/commands.md" | grep -F -- "/tickets" | grep -F -e "/do" -e "\`do\`" | tr '\n' ' ' | tr -s ' ')"
expect "a row of the command table is the run a stopped do hands over" test -n "${flat// /}"
carries_any "its command carries the repository and its location after the spec" "${pair_form[@]}"
carries_each "the location is the repository's own on this machine" \
  "location" -- \
  "absolute" "this machine" "your machine" "on disk"

echo "# docs/tickets.md / ## Path, slice, stop: the stop row on a location nobody typed"
# The stop rows whose condition names a location, read cell by cell: the other rows stop on the
# verdict, the journey or the open tickets, and a sentence of theirs cannot answer for this one.
# The section holds other tables, and the one on the verdict has a row on a location too: the stops
# are the rows under the header whose first cell is the condition.
rows="$(awk -F'|' '
  /^\| *condition *\|/ { on = 1; next }
  on && !/^\|/ { on = 0 }
  on && $2 ~ /location/
' "$tmp/stops.md")"
condition="$(awk -F'|' '{ print $2 }' <<<"$rows" | tr '\n' ' ' | tr -s ' ')"
message="$(awk -F'|' '{ print $3 }' <<<"$rows" | tr '\n' ' ' | tr -s ' ')"
flat="$condition"
expect "a stop row of the section is conditioned on a location" test -n "${flat// /}"
carries_any "the condition is a location that is owed" "${owed_location[@]}"
carries_each "and that the command did not carry" \
  "${none_typed[@]}" -- \
  "typed" "the command" "pair" "/tickets"
flat="$message"
carries_each "the message names the repository whose location is missing" \
  "repositor" -- \
  "location" -- \
  "${location_missing[@]}"
# The sentence above the table speaks for every stop, so nothing written may be said there or in the
# row itself. It answers for this stop only once the table holds its row.
flat="$(paragraph_with "$tmp/stops.md" "stop" all | grep -v '^|' | tr '\n' ' ' | tr -s ' ') $message"
if [ -n "${rows// /}" ]; then
  carries_any "the stop writes nothing" "${nothing_written[@]}" "before anything is explored or written"
else
  fail "the stop writes nothing (no stop row is conditioned on a location)"
fi

echo "# docs/tickets.md / ## The additive run: the location typed with the command"
flat="$(units_with "$tmp/additive.md" "location")"
expect "the additive run speaks of a location" test -n "${flat// /}"
carries_each "the location comes typed with the command" \
  "typed" "with the command" "on the command" "after the spec" -- \
  "${pair_form[@]}" "/tickets"
carries_each "it is written into the spec's repositories list" \
  "writ" "adds" "added" "append" -- \
  "repositories"
carries_any "and the developer edits no file by hand" \
  "by hand" "manually" "yourself" "you edit no" "nothing to edit" "no file to edit" "no edit of yours"

echo "# docs/tickets.md / ## The additive run: a typed location that cannot be built in"
flat="$(units_with "$tmp/additive.md" "git repositor")"
expect "the additive run speaks of a location that is not a git repository" test -n "${flat// /}"
carries_any "a location that is missing or not a git repository is written all the same" \
  "${written_all_the_same[@]}"
carries_any "the run does not stop on it" "${does_not_stop[@]}"
carries_each "the close names it in a line of its own" \
  "close" "closing" -- \
  "${own_line[@]}" "warn"
carries_each "the line says which of the two it is, missing or not a git repository" \
  "${not_there[@]}" -- \
  "${not_git[@]}"

exit $((fails > 0))
