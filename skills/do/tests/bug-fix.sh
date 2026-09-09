#!/usr/bin/env bash
# bug-fix.sh: the contract of references/bug-fix.md, the Playbook a bug outside the chain runs,
# and of the lines that point at it. Run: bash skills/do/tests/bug-fix.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
skill="$here/.."
ref="$skill/references/bug-fix.md"
ticket="$skill/references/ticket.md"
skillfile="$skill/SKILL.md"
evals="$skill/evals"
emdash=$'\xe2\x80\x94'
fails=0

ok() { echo "ok    $1"; }
fail() { echo "FAIL  $1"; fails=$((fails + 1)); }
has() { # $1 label, $2 file, $3 fixed string that must appear in it
  if grep -qF -- "$3" "$2" 2>/dev/null; then ok "$1"; else fail "$1"; fi
}
lacks() { # $1 label, $2 file, $3 fixed string that must not appear in it
  if grep -qF -- "$3" "$2" 2>/dev/null; then fail "$1 (found: $3)"; else ok "$1"; fi
}
line_of() { grep -n -- "$2" "$1" | head -1 | cut -d: -f1; }

# The router sends a bug in words to bug-fix, and the reference is linked under Links
if [ -f "$ref" ]; then ok "the reference exists"; else fail "the reference exists at $ref"; fi
has "the router carries a bug-fix row" "$skillfile" "| \`bug-fix\` |"
has "the row reads the bug in words" "$skillfile" "what happened, where, and the error"
has "Links carries the reference" "$skillfile" "[bug-fix.md](references/bug-fix.md)"
bugline="$(line_of "$skillfile" '| `bug-fix` |' || true)"
trivline="$(line_of "$skillfile" '| `trivial` |' || true)"
if [ -n "$bugline" ] && [ -n "$trivline" ] && [ "$bugline" -lt "$trivline" ]; then
  ok "the bug-fix row sits above the trivial row"
else
  fail "the bug-fix row sits above the trivial row (bug-fix $bugline, trivial $trivline)"
fi
lacks "no em-dash in the reference" "$ref" "$emdash"
lacks "no em-dash in the skill file" "$skillfile" "$emdash"

[ "$fails" = 0 ] || { echo; echo "$fails failed"; exit 1; }
echo; echo "all passed"
