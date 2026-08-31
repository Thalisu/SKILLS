#!/usr/bin/env bash
# forbid-test-skips.sh — Claude Code PreToolUse hook (matcher: Edit|Write|MultiEdit).
# Blocks an edit that INTRODUCES a skip/only/optional marker into a test file; edits that keep
# or remove existing markers pass. Only Claude's edits go through hooks — a deliberate skip is
# applied by the user in their editor. Installed by the testing-policy skill into
# <project>/.claude/testing-policy/ and wired in .claude/settings.json as:
#   {"matcher":"Edit|Write|MultiEdit","hooks":[{"type":"command",
#     "command":"bash \"$CLAUDE_PROJECT_DIR\"/.claude/testing-policy/forbid-test-skips.sh"}]}
# Requires jq. Exit 2 blocks the tool call (message on stderr); exit 0 lets it through.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0
input="$(cat)"
tool="$(jq -r '.tool_name // empty' <<<"$input")"
path="$(jq -r '.tool_input.file_path // empty' <<<"$input")"
[ -n "$path" ] || exit 0

case "$path" in
  *.test.ts|*.test.tsx|*.test.js|*.test.jsx|*.test.mjs|*.spec.ts|*.spec.tsx|*.spec.js|*.spec.jsx|*/__tests__/*)
    pat='\.(skip|only)\(|\b(xit|xdescribe|xtest|fit|fdescribe)\(' ; kind='skip/only' ;;
  */test_*.py|*_test.py|*/conftest.py)
    pat='pytest\.mark\.(skip|skipif|xfail)|pytest\.skip\(' ; kind='skip/xfail' ;;
  */.maestro/*.yaml|*/.maestro/*.yml)
    pat='optional:[[:space:]]*true' ; kind='optional: true' ;;
  *) exit 0 ;;
esac

count() { grep -cE "$pat" <<<"$1" 2>/dev/null || true; }

case "$tool" in
  Edit)
    old="$(jq -r '.tool_input.old_string // ""' <<<"$input")"
    new="$(jq -r '.tool_input.new_string // ""' <<<"$input")" ;;
  MultiEdit)
    old="$(jq -r '[.tool_input.edits[]?.old_string // ""] | join("\n")' <<<"$input")"
    new="$(jq -r '[.tool_input.edits[]?.new_string // ""] | join("\n")' <<<"$input")" ;;
  Write)
    new="$(jq -r '.tool_input.content // ""' <<<"$input")"
    if [ -f "$path" ]; then old="$(cat "$path")"; else old=""; fi ;;
  *) exit 0 ;;
esac

before="$(count "$old")"; after="$(count "$new")"
if [ "${after:-0}" -gt "${before:-0}" ]; then
  cat >&2 <<MSG
testing-policy: blocked — this edit introduces a ${kind} marker in a test file (${path}).
The Testing Policy forbids skipping, narrowing or marking optional a failing test: a failing test is presumed to expose a product bug. Fix the product, or take the assertion back to the test author with a contract-level reason.
If the skip is deliberate and approved, the user applies it by hand.
MSG
  exit 2
fi
exit 0
