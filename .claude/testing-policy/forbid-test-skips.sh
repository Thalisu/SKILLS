#!/usr/bin/env bash
# forbid-test-skips.sh: Claude Code PreToolUse hook (matcher: Edit|Write|MultiEdit).
# Blocks an edit that INTRODUCES a skip/only/todo/optional marker into a test file; edits that keep
# or remove existing markers pass. Only Claude's edits go through hooks; a deliberate skip is
# applied by the user in their editor. Installed by the testing-policy skill into
# <project>/.claude/testing-policy/ next to skip-patterns.sh (the single source of the markers and
# of which files count as tests) and wired in .claude/settings.json as:
#   {"matcher":"Edit|Write|MultiEdit","hooks":[{"type":"command",
#     "command":"bash \"$CLAUDE_PROJECT_DIR\"/.claude/testing-policy/forbid-test-skips.sh"}]}
# Requires jq. Exit 2 blocks the tool call (message on stderr); exit 0 lets it through; exit 1 lets
# it through but surfaces the stderr message; the guard is degraded, never silently off.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
degraded() { echo "testing-policy: $*; the skip guard is inactive until this is fixed" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || degraded "jq not found"
[ -f "$here/skip-patterns.sh" ] || degraded "skip-patterns.sh missing next to forbid-test-skips.sh"
. "$here/skip-patterns.sh"

input="$(cat)"
tool="$(jq -r '.tool_name // empty' <<<"$input")"
path="$(jq -r '.tool_input.file_path // empty' <<<"$input")"
[ -n "$path" ] || exit 0
skip_pattern_for "$path"
[ -n "$SKIP_PAT" ] || exit 0

count() { grep -oE "$SKIP_PAT" <<<"$1" | wc -l | tr -d ' '; }

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

if [ "$(count "$new")" -gt "$(count "$old")" ]; then
  cat >&2 <<MSG
testing-policy: blocked. This edit introduces a ${SKIP_KIND} marker in a test file (${path}).
The Testing Policy forbids skipping, narrowing or marking optional a failing test: a failing test is presumed to expose a product bug. Fix the product, or take the assertion back to the test author with a contract-level reason.
If the skip is deliberate and approved, the user applies it by hand.
MSG
  exit 2
fi
exit 0
