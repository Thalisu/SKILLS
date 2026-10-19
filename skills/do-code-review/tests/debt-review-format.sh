#!/usr/bin/env bash
# debt-review-format.sh: what `.agents/formats/review-format.md` says of a Debt review, the Review
# the debt skill writes and a `fix` run reads. The fix door hands the header's `Spec:` path as
# `--spec` and the file as `--review` to `scripts/fixed-point.sh`: a Debt review under another name,
# or without that `Spec:` line, reads as uncommitted work and every `fix` call on it is refused.
# The cases pin the essential terms where the format carries them, never its sentences.
# Run: bash skills/do-code-review/tests/debt-review-format.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
format="$here/../../../.agents/formats/review-format.md"
fails=0

# The format hard-wraps, and one section holds the rules of every kind of Review, so a Debt review's
# rule is read in the unit that states it: a paragraph, a top-level bullet or a table row.
units_of() { # stdin a passage: each paragraph, top-level bullet and table row flattened onto its own line, on stdout
  awk '
    function flush() { if (u != "") print u; u = "" }
    /^ *$/ { flush(); next }
    /^- / || /^\|/ { flush() }
    { u = u " " $0 }
    /^\|/ { flush() }
    END { flush() }
  ' | tr -s ' '
}

echo "# review-format.md / ## Where it lives: a Debt review sits beside its Spec as <Spec stem>.debt.review.md"
flat="$(flat_section "$format" "## Where it lives")"
expect "the format carries where a Review lives" test -n "$flat"
carries "the section names a Debt review and its file name" "Debt review" "debt.review.md"
flat="$(passage_of "$format" "## Where it lives" "## " | units_of | grep -F "debt.review.md" | tr '\n' ' ')"
expect "a rule names the debt.review.md file" test -n "$flat"
carries "and places it beside the Spec it is named for" "Spec"

echo "# review-format.md / ## Header: a Debt review opens on Spec: and its Fixed point is the branch's tip"
header="$(passage_of "$format" "## Header" "## " | units_of)"
expect "the format carries the header" test -n "$header"
flat="$(grep -F "Debt review" <<<"$header" | tr '\n' ' ')"
expect "the header says what a Debt review's header carries" test -n "$flat"
carries "a Debt review's header carries the Spec: line" "Spec:"
carries_any "as its first line" "first" "opens" "opening"
flat="$(grep -F "Debt review" <<<"$header" | grep -F "Fixed point" | tr '\n' ' ')"
expect "the header says what a Debt review's Fixed point: is" test -n "$flat"
carries_any "it is the tip of a branch" "tip of the branch" "branch's tip" "branch tip"
carries_any "the branch the developer was on when the debt was judged" \
  "the developer was on" "the developer is on" "checked out" "current branch"

echo "# review-format.md: a Debt review is written by the judgment of the feature's Pending debt, never a reviewer reading a diff"
flat="$(units_of <"$format" | grep -F "Debt review" |
  grep -iE "written by|writes|wrote|author|produced by|comes from" | tr '\n' ' ')"
expect "the format says who writes a Debt review" test -n "$flat"
carries "its author judged the feature's Pending debt" "Pending debt"
carries_any "as a judgment of that debt" "judgment" "judges" "judged" "judging"
carries_each "and not a reviewer reading a diff" \
  "never a reviewer" "not a reviewer" "no reviewer" "never by a reviewer" "not by a reviewer" -- "diff"

echo "# review-format.md / ## Findings, by Bucket: every Finding of a Debt review names its Source:, the Debt file's item or the Review's Finding"
flat="$(passage_of "$format" "## Findings, by Bucket" "## " | units_of | grep -F "Source:" | tr '\n' ' ')"
expect "the Finding block notes say what a Finding's Source: line is" test -n "$flat"
carries "the line belongs to a Debt review" "Debt review"
carries_any "and every Finding of one carries it" "every Finding" "each Finding" "Every Finding" "Each Finding"
carries_each "naming the Debt file and its item" "Debt file" -- "item"
carries_each "or the Review and its Finding number" "Review" -- \
  "Finding number" "Finding's number" "its number" "the number"

exit $((fails > 0))
