#!/usr/bin/env bash
# refactoring.sh: the contract of references/refactoring.md, the Playbook do matches a
# behaviour-preserving reshape to, and of the lines that point at it.
# Run: bash skills/do/tests/refactoring.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
skill="$here/.."
ref="$skill/references/refactoring.md"
mechanics="$skill/references/mechanics.md"
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
before() { # $1 label, $2 file, $3 fixed string that must come first, $4 the one that must follow
  local a b
  a="$(grep -nF -- "$3" "$2" 2>/dev/null | head -1 | cut -d: -f1 || true)"
  b="$(grep -nF -- "$4" "$2" 2>/dev/null | head -1 | cut -d: -f1 || true)"
  if [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ]; then ok "$1"; else fail "$1"; fi
}

# 1. The match and the opening: the router line, the reference under Links, the door, the first
# message and the worktree
if [ -f "$ref" ]; then ok "the reference exists"; else fail "the reference exists at $ref"; fi
has "the router matches a reshape in words" "$skillfile" "\`refactoring\`"
has "the router line names the reshape verbs" "$skillfile" "extract"
before "the trivial line sits above the refactoring line" "$skillfile" "| a change in words that no test could tell" "| a reshape of existing code"
has "the skill file lists the reference under Links" "$skillfile" "[refactoring.md](references/refactoring.md)"
has "the first line names the Playbook" "$ref" "Playbook: refactoring"
has "the first message carries the loop line" "$ref" "Loop: policy"
has "the first message carries the protected-branch warning" "$ref" "protected"
has "the checklist is copied verbatim" "$ref" "Copied verbatim into the run"
has "the door refuses a behaviour change" "$ref" "/discuss"
has "the worktree is the shared one" "$ref" "](mechanics.md)"
lacks "no em-dash in the reference" "$ref" "$emdash"
lacks "no em-dash in the skill file" "$skillfile" "$emdash"
lacks "no em-dash in the mechanics" "$mechanics" "$emdash"

if [ "$fails" = 0 ]; then echo "all ok"; else echo "$fails failing"; exit 1; fi
