#!/usr/bin/env bash
# kinds-never-fold.sh: what SKILL.md has the session do with a small Logic ticket whose only edge
# ties it to its Front-end ticket: the fold is refused, since the two tickets of a fold are of the
# same kind, and the folds line of the breakdown names the ticket left unfolded with that rule.
# The fold is decided by the session from the estimates and the edge graph, which no script
# carries, so the decision is proven over the two passages that carry it.
# Run: bash skills/tickets/tests/kinds-never-fold.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/../SKILL.md"
fails=0

never_joined=(
  "never joined" "never folded" "never fold" "never merged" "never merge" "never join"
  "are not joined" "are not folded" "is never folded into"
)

echo "# SKILL.md / ## 3: a fold joins two tickets of the same kind only"
fold="$(item_holding <(passage_of "$skill" "**Splits, folds and placements**" "**Wide refactors") \
  '[0-9]+\.' "**Fold**")"

# The conditions only, the marker line and the bullets under it: a sentence past the list would
# read as a remark on the merged ticket, not as something that must hold for the fold to happen.
flat="$(printf '%s\n' "$fold" | awk 'NF == 0 { exit } 1' | tr '\n' ' ' | tr -s ' ')"
expect "SKILL.md carries the Fold conditions" test -n "$flat"
carries_any "the two tickets being of the same kind is one of the conditions that must hold" \
  "of the same kind" "the same kind" "share a kind" "share one kind" "of one kind" "same Kind"

flat="$(printf '%s\n' "$fold" | tr '\n' ' ' | tr -s ' ')"
carries_each "a Logic ticket and a Front-end ticket are never joined" \
  "Logic ticket" -- \
  "Front-end ticket" -- \
  "${never_joined[@]}"

echo "# SKILL.md / ## 4: the folds line names a small ticket its other kind kept unfolded"
flat="$(item_holding <(passage_of "$skill" "After the list:" "One shape the message can take") \
  '[0-9]+\.' "folds" | tr '\n' ' ' | tr -s ' ')"
expect "SKILL.md carries the folds line of the breakdown's closing parts" test -n "$flat"
carries_any "the line covers a small ticket that was left unfolded" \
  "left unfolded" "stays unfolded" "kept unfolded" "stayed unfolded" "not folded" \
  "left as cut" "went unfolded" "could not fold" "cannot fold"
carries_any "the reason is that its only edge ties it to a ticket of the other kind" \
  "the other kind" "other kind" "a different kind" "its Front-end ticket" "its Logic ticket"
carries_any "that ticket is named on the line, not passed over under none" \
  "is named" "are named" "is listed" "are listed" "is stated" "is said" "says so" "names it"
carries_any "the line gives the rule: the two kinds are never joined" "${never_joined[@]}"

exit $((fails > 0))
