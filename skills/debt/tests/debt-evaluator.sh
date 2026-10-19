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

exit $((fails > 0))
