#!/usr/bin/env bash
# harness-hooks.sh: whether the harness this session runs under runs the PreToolUse hooks an agent's
# own definition declares, so the ticket run can say which mechanism guarded its forks: the pattern
# guard beside the Plan's `## Sources` header check, or the header check alone.
#
#   harness-hooks.sh
#
# Prints four key=value lines, in this order: harness=claude-code|other, hooks=run|disabled|none,
# disabled_by=none|<settings file>:<key>, guard=pattern-and-header|header-only.
set -uo pipefail

if [ "${CLAUDECODE:-}" = 1 ] || [ -n "${CLAUDE_CODE_SESSION_ID:-}" ]; then
  printf '%s\n' harness=claude-code hooks=run disabled_by=none guard=pattern-and-header
else
  printf '%s\n' harness=other hooks=none disabled_by=none guard=header-only
fi
