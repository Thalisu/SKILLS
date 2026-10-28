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

exit "$((fails > 0))"
