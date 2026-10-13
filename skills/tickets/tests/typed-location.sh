#!/usr/bin/env bash
# typed-location.sh: what SKILL.md's `## 1. Ground` has the session do with a location typed after
# the spec (`/tickets <spec> <repository>: <its absolute location on this machine>`, the last line
# of a stopped `do` Reply): it writes that location into the Spec's Repositories list, as the entry
# of the repository a finding marked ` Location not known.`, before the code is explored or any
# slice is drafted.
# The session takes this from what it read of the arguments and of the Spec, which no script
# carries, so the decision is proven over the passages that carry it.
# Run: bash skills/tickets/tests/typed-location.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/../SKILL.md"
fails=0

pair_form=(
  "<repository>: <" "<name>: <" "{repository}: {" "{name}: {" "repository>: <" "name>: <"
)
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

exit $((fails > 0))
