#!/usr/bin/env bash
# debt-evaluator.sh: the frontmatter contract of skills/debt/agents/debt-evaluator.md, the read-only
# fork the debt skill hands the pending debt of a feature to judge. The installer link is covered by
# scripts/tests/link-skills.sh, which fails on any agent definition left unlinked.
# Run: bash skills/debt/tests/debt-evaluator.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
agent="$here/../agents/debt-evaluator.md"
fails=0

echo "# skills/debt/agents/debt-evaluator.md: a read-only evaluator the debt skill forks"
expect "the debt skill ships an evaluator agent at agents/debt-evaluator.md" test -f "$agent"

rc=0
# shellcheck disable=SC2034  # lib.sh's check_lines reads $out
out="$(frontmatter "$agent" 2>/dev/null)" || rc=$?

check_lines "the evaluator's frontmatter names it debt-evaluator, the name the debt skill forks it by" 0 "$rc" \
  "name: debt-evaluator"
# link-skills.sh links the definition under its file name while the harness dispatches on the
# frontmatter `name`, so a disagreement leaves an agent nothing can fork.
expect "the evaluator's file name and its frontmatter name agree" \
  test "$(field name)" = "$(basename "$agent" .md)"
check_lines "the evaluator runs on opus at high effort by its own definition" 0 "$rc" \
  "model: opus" "effort: high"
# The whole line: an evaluator must never edit the developer's project, so its tool list has no
# Write and no Edit.
check_lines "the evaluator's tools are the read and run ones, with no write and no edit tool" 0 "$rc" \
  "tools: Bash, Read, Glob, Grep"

# The definitions quote their description in YAML, so the closing quote is not part of its end.
desc="$(field description)"
desc="${desc%[\"\']}"
expect "the evaluator's description names the debt skill as its only caller" \
  grep -qF "Forked only by the debt skill" <<<"$desc"
expect "the evaluator's description ends by refusing invocation on its own initiative" \
  bash -c '[[ "$1" == *"Never on your own initiative." ]]' _ "$desc"

echo "# the return's ending: the composer debt-review.sh places an item by it alone"
expect "the evaluator's description promises one of the three endings, with no file list in its test of small" \
  test "${desc#[\"\']}" = "Judges one item of a feature''s Pending debt: walks or runs its failure, a proof only in a temporary directory of its own, and never edits the project. Returns the Rung it reached, its evidence and one ending: the fix and whether it is small (one behaviour, one test, one commit, no Design fork), what refuted the item, or what settles it outside the code, written whole to the return file its brief names. Forked only by the debt skill with a brief, one per gathered item. Never on your own initiative."

block="$(blocks_of "$agent" "## The return file")"
expect "the return-file block gives the evaluator all three endings to write: Fix: with Small:, Refuted by:, Outside code:" \
  bash -c 'for k in "Fix:" "Small:" "Refuted by:" "Outside code:"; do grep -q "^$k" <<<"$1" || exit 1; done' _ "$block"

flat="$(paragraph_with "$agent" "Refuted by:" all | tr -s ' ')"
carries_any "Refuted by: applies when the failure was walked or run and does not occur" \
  "does not occur" "did not occur" "does not happen" "did not happen"
flat="$(paragraph_with "$agent" "Outside code:" all | tr -s ' ')"
carries_any "Outside code: applies when the item is real and only something no commit does settles it" \
  "no commit" "not a commit" "no code change"
# The paragraphs that name the endings, so a stray "otherwise" elsewhere in the body never answers.
# shellcheck disable=SC2034  # lib.sh's carries_any reads $flat
flat="$({
  paragraph_with "$agent" "Refuted by:" all
  paragraph_with "$agent" "Outside code:" all
} | tr -s ' ')"
carries_any "Fix: with Small: is the ending for every other item" "otherwise" "Otherwise"
carries_any "the return carries exactly one of the three endings" \
  "exactly one of" "only one of" "Exactly one of"

# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$(cat "$agent")"
check_absent "the evaluator's test of small no longer asks for the files named in Fix:" 0 0 \
  "files named in Fix:"
check_absent "the evaluator's file names no Bucket, which the composer decides" 0 0 \
  "Act on" "Consider" "Noted" "Cleared"

exit $((fails > 0))
