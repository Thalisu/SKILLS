#!/usr/bin/env bash
# typed-location.sh: what SKILL.md's `## 1. Ground` has the session do with a location typed after
# the spec (`/tickets <spec> <repository>: <its absolute location on this machine>`, the last line
# of a stopped `do` Reply): it writes that location into the Spec's Repositories list, as the entry
# of the repository a finding marked ` Location not known.`, before the code is explored or any
# slice is drafted. With no location typed for a repository a finding still owes one for, the run
# stops on one message naming that repository and writes nothing.
# The session takes this from what it read of the arguments and of the Spec, which no script
# carries, so the decision is proven over the passages that carry it.
# Run: bash skills/tickets/tests/typed-location.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/../SKILL.md"
fails=0

mapfile -t pair_form < <(pair_form_phrasings)
mapfile -t owed_location < <(owed_location_phrasings)
mapfile -t none_typed < <(none_typed_phrasings)
mapfile -t location_missing < <(location_missing_phrasings)
mapfile -t not_there < <(not_there_phrasings)
mapfile -t not_git < <(not_git_phrasings)
mapfile -t written_all_the_same < <(written_all_the_same_phrasings)
mapfile -t does_not_stop < <(does_not_stop_phrasings)
mapfile -t own_line < <(own_line_phrasings)
no_entry=(
  "no entry" "no such entry" "holds none" "lacks" "without an entry" "not listed" "not among"
  "missing from" "does not hold" "does not list" "has no" "names no" "no line for"
)

echo "# SKILL.md / frontmatter: the hint shows what may be typed after the spec"
# shellcheck disable=SC2034 # field reads the frontmatter the caller left in $out
out="$(frontmatter "$skill" 2>/dev/null)"
# shellcheck disable=SC2034 # the carries_* assertions read $flat
flat="$(field argument-hint)"
flat="${flat,,}"
carries "the hint still names the spec" "spec"
carries_each "the hint names a repository and its location" \
  "repositor" -- \
  "location" "path"

echo "# SKILL.md / ## 1: \$ARGUMENTS may carry a repository and its location after the spec"
# Every paragraph of the ground step that reads $ARGUMENTS, the table of its forms included: the
# bullets on the Spec's own Repositories section speak of locations too, and cannot answer for what
# is typed.
ground="$(passage_of "$skill" "## 1. Ground" "## 2. Explore the code")"
flat="$(paragraph_with <(printf '%s\n' "$ground") "\$ARGUMENTS" all | tr '\n' ' ' | tr -s ' ')"
flat="${flat,,}"
expect "the ground step reads \$ARGUMENTS" test -n "${flat// /}"
carries_each "a repository and its location on this machine are read off the arguments" \
  "repositor" -- \
  "location"
carries_any "in the form the stopped do reply hands over, the name, a colon, the location" \
  "${pair_form[@]}"

echo "# SKILL.md / ## 1: the typed location becomes the entry of the repository a finding left unlocated"
# Every paragraph of the passage that speaks of a finding line ending in ` Location not known.`,
# matched in lower case.
passage="$(passage_of "$skill" "**Open tickets and what they cover.**" "## 2. Explore the code")"
flat="$(paragraph_with <(printf '%s\n' "${passage,,}") "location not known" all | tr '\n' ' ' | tr -s ' ')"
expect "the ground step reads a finding line that ends in Location not known" test -n "${flat// /}"
carries_each "the location is owed when Repositories holds no entry for the repository the line names" \
  "repositories" -- \
  "${no_entry[@]}"
carries_each "the location typed with the command is written as that repository's entry of Repositories" \
  "typed" "\$arguments" "arguments" "with the command" "on the command" -- \
  "writ" "add" "append" -- \
  "entry" -- \
  "repositories"
carries_any "the entry takes the shape the spec format fixes" \
  "${pair_form[@]}" "spec-format.md" "spec format"
carries_each "the entry is written before the code is explored and before any slice is drafted" \
  "before" "ahead of" "prior to" -- \
  "explor" "step 2" "steps 2" -- \
  "slice" "draft" "is cut" "step 3" "steps 2 and 3"

echo "# SKILL.md / ## 1: a finding that owes a location stops the run when none was typed"
# The stop rows whose condition names a location, read cell by cell: the other rows stop on the
# verdict, the journey or the open tickets, and a sentence of theirs cannot answer for this one.
mapfile -t nothing_written < <(nothing_written_phrasings)
stops="$(passage_of "$skill" "**Stops.**" "## 2. Explore the code")"
rows="$(awk -F'|' '/^\|/ && tolower($2) ~ /location/' <<<"$stops")"
condition="$(awk -F'|' '{ print $2 }' <<<"$rows" | tr '\n' ' ' | tr -s ' ')"
message="$(awk -F'|' '{ print $3 }' <<<"$rows" | tr '\n' ' ' | tr -s ' ')"

flat="${condition,,}"
expect "a stop row of the ground step is conditioned on a location" test -n "${flat// /}"
carries_each "the condition is a finding that owes a location" \
  "finding" -- \
  "${owed_location[@]}"
carries_each "while the command carried no location for that repository" \
  "${none_typed[@]}" -- \
  "typed" "\$arguments" "arguments" "the command" "pair"

flat="${message,,}"
carries_each "the message names the repository whose location is missing" \
  "repositor" -- \
  "location" -- \
  "${location_missing[@]}"

# The paragraph above the table speaks for every stop, so nothing written may be said there or in
# the row itself. The paragraph answers for this stop only once the table holds its row.
flat="$(paragraph_with <(printf '%s\n' "$stops") "**Stops.**") $message"
flat="${flat,,}"
if [ -n "${rows// /}" ]; then
  carries_any "the stop writes nothing" "${nothing_written[@]}"
else
  fail "the stop writes nothing (no stop row is conditioned on a location)"
fi

echo "# SKILL.md / ## 1: a typed location that is missing or not a git repository is written all the same"
# The paragraphs of the passage that speak of a git repository, matched in lower case: the rest of it
# says where the entry goes and what else in the Spec stays, and cannot answer for a bad location.
passage="$(passage_of "$skill" "**A finding that owes a location.**" "## 2. Explore the code")"
flat="$(paragraph_with <(printf '%s\n' "${passage,,}") "git repositor" all | tr '\n' ' ' | tr -s ' ')"
expect "the ground step checks the typed location for a git repository" test -n "${flat// /}"
carries_each "the typed location is checked for a directory there and for a git repository" \
  "${not_there[@]}" -- \
  "git repositor"
affirms "a location failing either check is written all the same" \
  "entry" "location" -- \
  "${written_all_the_same[@]}"
affirms "the run does not stop on it and asks nothing about it" \
  "${does_not_stop[@]}" -- \
  "asks nothing" "ask nothing" "no question" "without asking" "not ask" "never ask" "nor asks" \
  "nothing is asked" "is not asked"

echo "# SKILL.md / ## 6: the close names a bad typed location in a line of its own"
# Each bullet of the close, and each paragraph outside its lists, is one thing the close carries:
# the ones that speak of a git repository, matched in lower case.
close_step="$(passage_of "$skill" "## 6. Close" "## Hard rules")"
close_step="${close_step,,}"
flat="$({
  bullets_opening_on <(printf '%s\n' "$close_step") "- "
  paragraph_with <(printf '%s\n' "$close_step") "git repositor" all | grep -v '^ *- '
} | grep -F "git repositor" | tr '\n' ' ' | tr -s ' ')"
expect "the close speaks of a location that is not a git repository" test -n "${flat// /}"
carries_any "the bad location gets a line of its own" \
  "${own_line[@]}"
carries_each "the line names the location as it was written" \
  "location" -- \
  "as written" "as it was written" "as typed" "as it was typed" "as the entry" "entry carries" \
  "entry gives" "entry holds" "section carries" "spec carries" "as it stands" "verbatim" \
  "written" "typed"
carries_each "the line says which of the two it is, missing or not a git repository" \
  "${not_there[@]}" -- \
  "${not_git[@]}"

exit $((fails > 0))
