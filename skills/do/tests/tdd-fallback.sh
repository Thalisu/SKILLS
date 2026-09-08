#!/usr/bin/env bash
# tdd-fallback.sh: the contract of references/tdd-fallback.md, the TDD fallback the ticket
# Playbook reads when the project has no unit test author, and of the lines that point at it.
# Run: bash skills/do/tests/tdd-fallback.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
skill="$here/.."
ref="$skill/references/tdd-fallback.md"
mechanics="$skill/references/mechanics.md"
ticket="$skill/references/ticket.md"
skillfile="$skill/SKILL.md"
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

# The reference: pstack's tdd skill adapted, attributed in the vendor form, one rule for both cases
if [ -f "$ref" ]; then ok "the reference exists"; else fail "the reference exists at $ref"; fi
if [ "$(head -1 "$ref" 2>/dev/null)" != "---" ]; then ok "the frontmatter is stripped"; else fail "the frontmatter is stripped"; fi
has "the attribution names pstack" "$ref" "https://github.com/cursor/plugins/tree/main/pstack"
has "the attribution names the upstream commit" "$ref" "7314f723a487ec406b6369fe5865ba034cfed166"
has "the attribution names the MIT licence" "$ref" "MIT"
has "the attribution links the licence file" "$ref" "PSTACK-LICENSE"
has "the reference is read only without the unit test author" "$ref" ".claude/agents/unit-test-author.md"
has "the run writes the failing test itself" "$ref" "writes the failing test itself"
has "else the closest executable check with the reason stated" "$ref" "closest executable check"
has "the feature case follows the bug case's rule" "$ref" "feature case"
has "no test author is dispatched" "$ref" "no test author is dispatched"
has "the reference links the build loop" "$ref" "](mechanics.md)"
lacks "no em-dash in the reference" "$ref" "$emdash"

# The build loop's fallback paragraph points at the reference
has "the build loop links the reference" "$mechanics" "](tdd-fallback.md)"
lacks "no em-dash in the mechanics" "$mechanics" "$emdash"

# The loop line: fallback without the author names the read, policy never reads it, Links lists it
has "the loop line reads fallback without the unit test author" "$ticket" '`Loop: fallback` otherwise'
has "the loop line names the reference read under fallback" "$ticket" "](tdd-fallback.md)"
has "the reference is never read under policy" "$ticket" "never read"
has "the skill file lists the reference under Links" "$skillfile" "[tdd-fallback.md](references/tdd-fallback.md)"
lacks "no em-dash in the ticket reference" "$ticket" "$emdash"

if [ "$fails" = 0 ]; then echo "all ok"; else echo "$fails failing"; exit 1; fi
