#!/usr/bin/env bash
# misread-path-recut.sh: what SKILL.md's `## 4. Put the breakdown to the user` has the session do
# when the developer answers the approval question by naming a Path read wrongly, as having a screen
# or as having none: the Path is recut the other way, the estimates and edges are redone, and the
# breakdown is shown again with the same one question, never published on that message.
# The input is the developer's second message of a live session, which no script reads and the eval
# runner never sends, so the decision is proven over the passage that carries it.
# Run: bash skills/tickets/tests/misread-path-recut.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/../SKILL.md"
fails=0

# The correction rule only: step 4 names the paths cut in two in its list and its example, and the
# `--auto` section below has rules of its own on what is published, so neither answers for it.
whole="$(passage_of "$skill" "Granularity, edges, folds and splits are never asked" "### Under" |
  tr '\n' ' ' | tr -s ' ')"
flat="$whole"

echo "# SKILL.md / ## 4: a Path named as read wrongly is recut and the breakdown shown again"
expect "SKILL.md carries the correction rule of the approval step" test -n "$flat"

misread=(
  "read wrongly" "wrongly read" "read the wrong way" "misread" "read in error"
  "was read wrong" "is read wrong" "read as having a screen when" "read as having none when"
)
carries_any "a Path the developer names as read wrongly is a correction the rule answers" "${misread[@]}"

# What the session does with that correction is read from where the rule first names it on, so the
# sentence on corrections in general, which sits above it, cannot answer for the recut.
m="$(first_at "${misread[@]}")"
flat="${whole:$((m > 0 ? m - 1 : ${#whole}))}"

carries_any "the misread Path is recut the other way" \
  "recut" "cut again" "cut the other way" "cut anew" "re-cut"
carries_any "a Path wrongly read as having a screen goes back to one Logic ticket" \
  "become one Logic ticket" "becomes one Logic ticket" "become a single Logic ticket" \
  "becomes a single Logic ticket" "become a Logic ticket alone" "becomes a Logic ticket alone" \
  "merge into one Logic ticket" "merged into one Logic ticket" "back into one Logic ticket" \
  "collapse into one Logic ticket" "into a single Logic ticket"
carries_any "a Path wrongly read as having no screen gains a Front-end ticket blocked by its Logic ticket" \
  "Front-end ticket blocked by it" "Front-end ticket blocked by the Logic ticket" \
  "Front-end ticket blocked by that Logic ticket" "Front-end ticket that it blocks" \
  "Front-end ticket the Logic ticket blocks" "Front-end ticket built on it"
carries_each "the estimates and the edges of the recut breakdown are redone" \
  "estimates" "estimate" -- \
  "edges" "edge graph" "Blocked by" -- \
  "redone" "done again" "recomputed" "computed again" "reworked" "worked out again" \
  "redrawn" "drawn again" "re-estimated" "run again"

shown=(
  "shown again" "showed again" "shows the breakdown again" "show the breakdown again"
  "put to the user again" "put again to the user" "presented again" "is shown once more"
)
carries_any "the recut breakdown is shown to the developer again" "${shown[@]}"
carries_any "it comes back with the same one question, not as an approval taken for granted" \
  "same one question" "same single question" "the same question" "the one question again" \
  "asked again"

flat="$whole"
carries_any "the correction publishes nothing: only the yes does" \
  "Nothing is published before the yes" "nothing is published before the yes" \
  "Nothing is published until the yes" "nothing is published until the yes" \
  "published only on the yes" "published only after the yes"

exit $((fails > 0))
