#!/usr/bin/env bash
# callers.sh: the debt skill's fix step reaches do-code-review through the Skill tool with a Debt
# review, and the agent's description gates who may reach it (.agents/invocation.md): both the
# description and the contract's row name debt among its callers.
# Run: bash skills/do-code-review/tests/callers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
fails=0

repo="$(cd "$here/../../.." && pwd -P)"
# debt, `debt` or /debt as a word of its own: debt-evaluator and the capitalised "Debt review" are
# not the skill's name.
names_debt='(^|[^[:alnum:]_-])`?/?debt`?([^[:alnum:]_-]|$)'

echo "# skills/do-code-review/AGENT.md"
# shellcheck disable=SC2034  # lib.sh's field reads $out
out="$(frontmatter "$here/../AGENT.md" 2>/dev/null)"
description="$(field description)"
expect "the agent's description admits the debt skill as a caller" \
  grep -qE -- "$names_debt" <<<"$description"

echo "# .agents/invocation.md"
row="$(grep -E '^\| `do-code-review` \| model-invoked \|' "$repo/.agents/invocation.md")"
expect "the contract's do-code-review row names the debt skill as a caller" \
  grep -qE -- "$names_debt" <<<"$row"

[ "$fails" = 0 ]
