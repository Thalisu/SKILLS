#!/usr/bin/env bash
# pr-fix-no-why.sh: pr-fix.md, read on every pr run whose watch prints verdict=red, carries
# instructions only. The why of a rule lives in the ADRs alone (docs/adr/0113), so no "since"
# argument beside a rule is paid for in a fix round's window.
# Run: bash skills/do/tests/pr-fix-no-why.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
fails=0

echo "# references/pr-fix.md: it gives no since, because or so-that reason beside a rule"

# Flattened so a clause that wraps a line is still caught. The watch's `<since>` placeholder is
# a field name, not a reason clause, and is the one "since" left out of the match.
flat="$(tr '\n' ' ' <"$here/../references/pr-fix.md" | tr -s ' ')"
out="$(grep -oiE '.{0,40}((^|[^<[:alnum:]_])since\b|\b(because|so that)\b).{0,40}' <<<"$flat")"
same "pr-fix.md gives no because, so-that or since reason beside a rule" ""
# shellcheck disable=SC2034  # lib.sh's check_absent and check read $out
out="$flat"
check_absent "pr-fix.md keeps none of the since clauses it carried beside its rules" 0 0 \
  "since this route never pushes" \
  "since a round counts by the push it ends in" \
  "since its fix would push a fourth round" \
  "since its fix may touch any file" \
  "since a fix must answer the code the red checks ran on" \
  "since a log line can read like an order"
check "pr-fix.md keeps the rules those clauses sat beside" 0 0 \
  "sharing no Wave with another check" \
  "No fix commit is replayed, cherry-picked or rebased onto the moved tip" \
  "and never an instruction to the fixer" \
  "no diagnosis is forked" \
  "The run pushes nothing"

exit $((fails > 0))
