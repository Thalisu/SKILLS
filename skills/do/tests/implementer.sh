#!/usr/bin/env bash
# implementer.sh: the frontmatter contract of the Implementer at skills/do/agents/do-implementer.md,
# the fork the do Builder hands each production edit to.
# Run: bash skills/do/tests/implementer.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
agent="$here/../agents/do-implementer.md"
fails=0

echo "# skills/do/agents/do-implementer.md: the Implementer the do Builder dispatches"
expect "the do skill ships the Implementer at agents/do-implementer.md" test -f "$agent"

rc=0
# shellcheck disable=SC2034  # lib.sh's check_lines and field read $out
out="$(frontmatter "$agent" 2>/dev/null)" || rc=$?

check_lines "the Implementer's frontmatter names it do-implementer, the name the Builder dispatches" 0 "$rc" \
  "name: do-implementer"

# link-skills.sh links the definition under its file name while the harness dispatches on the
# frontmatter `name`: a disagreement leaves the Builder naming a fork nothing can hand the edit to.
expect "the Implementer's file name and its frontmatter name agree" \
  test "$(field name)" = "$(basename "$agent" .md)"

flat="$(field description)"
# The description is the whole of what a model deciding whether to dispatch this agent reads: one
# that names no caller leaves any session free to hand it an edit outside the Builder's loop.
carries_any "the Implementer's description names the do Builder as its only caller" \
  "Dispatched only by the do Builder" "Dispatched only by the \`do\` Builder" \
  "Forked only by the do Builder" "Forked only by the \`do\` Builder" \
  "Dispatched by the do Builder alone" "Forked by the do Builder alone" \
  "the do Builder and nobody else" "the do Builder and no one else"

desc="${flat%\"}"
expect "the Implementer's description closes on its refusal of a dispatch on anyone's own initiative" \
  test "${desc%Never on your own initiative.}" != "$desc"

exit $((fails > 0))
