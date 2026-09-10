#!/usr/bin/env bash
# returns.sh: the wait the do-code-review orchestrator runs on its reviewers' return files, so a
# retry forks only the reviewer whose file never landed and a return already in hand is never
# waited on again.
#
#   returns.sh <window in seconds> <return file>...
#
# Waits until every file is there and not empty, or until the window closes, whichever comes
# first, looking once a second. Prints one line per file, in the order given: returned=<file> when
# it is there and not empty, else missing=<file>.
#
# Exit codes: 0 every file returned · 1 a file is missing · 2 usage.
set -uo pipefail

usage() { echo "usage: returns.sh <window in seconds> <return file>..." >&2; exit 2; }
[ "$#" -ge 2 ] || usage
window="$1"; shift
[[ "$window" =~ ^[0-9]+$ ]] || usage

all_there() { local f; for f in "$@"; do [ -s "$f" ] || return 1; done; }
deadline=$(( $(date +%s) + window ))
until all_there "$@" || [ "$(date +%s)" -ge "$deadline" ]; do sleep 1; done

rc=0
for f in "$@"; do
  if [ -s "$f" ]; then echo "returned=$f"; else echo "missing=$f"; rc=1; fi
done
exit "$rc"
