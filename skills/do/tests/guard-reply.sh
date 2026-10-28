#!/usr/bin/env bash
# guard-reply.sh: the contract of scripts/guard-reply.sh, the printer of the Reply's Guard: line,
# fed the lines scripts/harness-hooks.sh prints on its stdin.
# Run: bash skills/do/tests/guard-reply.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/guard-reply.sh"
fails=0

run() { # $1.. the probe's lines piped on stdin: stdout, then an `exit <rc>` line, in $out
  rc=0
  out="$(printf '%s\n' "$@" | bash "$script" 2>/dev/null)" || rc=$?
  out="$out"$'\n'"exit $rc"
}

run harness=claude-code hooks=run disabled_by=none guard=pattern-and-header
same "a pattern-and-header verdict prints the pattern guard beside the header check and exits 0" \
  "$(printf '%s\n' 'Guard: guard=pattern-and-header (harness=claude-code, hooks=run): the pattern guard beside the header check.' 'exit 0')"

run harness=claude-code hooks=disabled disabled_by=/home/dev/notes/.claude/settings.json:disableAllHooks guard=header-only
same "a header-only verdict prints the header check alone with the disabled_by= file the probe named, and exits 1" \
  "$(printf '%s\n' 'Guard: guard=header-only (harness=claude-code, hooks=disabled, disabled_by=/home/dev/notes/.claude/settings.json:disableAllHooks): the header check alone, the whole guard.' 'exit 1')"

run harness=other hooks=none disabled_by=none guard=header-only
same "a header-only verdict with no disabled_by= file prints the header check alone and exits 1" \
  "$(printf '%s\n' 'Guard: guard=header-only (harness=other, hooks=none): the header check alone, the whole guard.' 'exit 1')"

rc=0
out="$(bash "$script" </dev/null 2>/dev/null)" || rc=$?
out="$out"$'\n'"exit $rc"
same "an empty input, a probe that failed, prints a line saying the probe printed no verdict, and exits 1" \
  "$(printf '%s\n' 'Guard: no verdict: the guard probe printed none; the header check alone, the whole guard.' 'exit 1')"

exit "$((fails > 0))"
