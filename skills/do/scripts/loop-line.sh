#!/usr/bin/env bash
# loop-line.sh: the loop line of a ticket run, quoted as Reply item 4, its first line copied as the
# Builder's and do-impeccable's `Loop:` key. Run from anywhere.
#
#   loop-line.sh loop=<policy|global|fallback> agent=<available|withheld>
#
# loop= is the door's line verbatim; agent= says whether this session holds the Agent tool.
# Prints `Loop: <word>`, then for the global loop the line naming its unit test author.
# Exit codes: 0 printed.
set -euo pipefail
loop=""
for arg in "$@"; do
  case "$arg" in loop=*) loop="${arg#loop=}" ;; esac
done
echo "Loop: $loop"
[ "$loop" = global ] && echo "Unit test author: global-unit-test-author"
exit 0
