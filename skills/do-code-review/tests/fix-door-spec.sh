#!/usr/bin/env bash
# fix-door-spec.sh: `## The door` tells a `fix` call on a Review whose header reads `Spec: <path>` to
# hand the door script that path as `--spec`, beside the short sha. The Review written beside a
# handed Spec is untracked, and the door script only reads it as the run's own file when it is told
# where the Spec sits: without the flag its `dirty=` line reads `yes` and every `fix` call on such a
# Review is refused with `working tree has uncommitted changes`. What `--spec` does to that line is
# fixed-point.sh's own test; this one holds the instruction the run follows to pass it.
# Run: bash skills/do-code-review/tests/fix-door-spec.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
refs="$here/../references"
fails=0

flat="$(flat_section "$refs/fix.md" "## The door")"
expect "fix.md carries a ## The door section" test -n "$flat"

carries "a fix call on a Review whose header reads Spec: <path> runs the door script with --spec <that path> beside the short sha" \
  "--spec" "Spec:"

exit $((fails > 0))
