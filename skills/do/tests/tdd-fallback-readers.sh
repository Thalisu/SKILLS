#!/usr/bin/env bash
# tdd-fallback-readers.sh: every step that sends a run to tdd-fallback.md (the loop line reading
# `Loop: fallback`, or a test author `BLOCKED` on a run command the project map lacks) points at it in
# one shape, `Read [tdd-fallback.md](tdd-fallback.md) when <condition>`, so a maintainer finds each
# way in by its shape when the fallback's ways in change.
# Run: bash skills/do/tests/tdd-fallback-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
fails=0

echo "# every pointer to tdd-fallback.md reads \`Read [tdd-fallback.md](tdd-fallback.md) when <condition>\`"
pointers_shaped "every pointer to tdd-fallback.md has the \`Read <file> when <condition>\` shape" \
  "$(cd "$here/.." && pwd -P)" tdd-fallback.md 6

[ "$fails" -eq 0 ] && exit 0
exit 1
