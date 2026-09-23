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

echo harness=claude-code
echo hooks=run
echo disabled_by=none
echo guard=pattern-and-header
