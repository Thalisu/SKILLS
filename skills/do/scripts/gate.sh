#!/usr/bin/env bash
# gate.sh: the gate of a do run, every check the run names run once in the directory the script
# runs in, so the developer reruns the line it prints first and gets the same answer.
#
#   gate.sh <key>=<command>...    each check a key, its name in the output, and the command line
#                                 it stands for, run with bash -c in the order given
#
# Prints key=value lines, in this order: command, the line that reruns this gate as it was called;
# one line per check, <key>=green when it exits 0, otherwise <key>=red exit=<n> log=<file>, the
# file holding its full output, followed by its failing block: the output's last 20 lines, each
# indented two spaces, under a [capped: ...] line when there were more; then verdict. Every check
# runs whatever the one before it returned, so one gate puts every failing block in front of the
# run at once. The logs are written under $TMPDIR, never in the tree the gate checks.
#
# verdict: red (a check exited non-zero) · green.
#
# Exit codes: 0 green · 1 red · 2 usage.
set -uo pipefail

gate_here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
cap=20

usage() { echo "usage: gate.sh <key>=<command>..." >&2; exit 2; }
[ "$#" -gt 0 ] || usage
for pair in "$@"; do
  [[ "$pair" =~ ^[A-Za-z0-9_.:/-]+= ]] || usage
done

printf 'command=bash %q' "$gate_here/gate.sh"; printf ' %q' "$@"; echo
logs="$(mktemp -d "${TMPDIR:-/tmp}/do-gate.XXXXXX")" || { echo "cannot create a log directory" >&2; exit 2; }
verdict=green n=0
for pair in "$@"; do
  key="${pair%%=*}" n=$((n + 1))
  log="$logs/$n-${key//\//_}.log"
  rc=0; bash -c "${pair#*=}" >"$log" 2>&1 || rc=$?
  if [ "$rc" = 0 ]; then echo "$key=green"; rm -f "$log"; continue; fi
  verdict=red
  echo "$key=red exit=$rc log=$log"
  lines="$(wc -l <"$log")"
  [ "$lines" -gt "$cap" ] && echo "  [capped: the last $cap of $lines lines]"
  tail -n "$cap" "$log" | sed 's/^/  /'
done
rmdir "$logs" 2>/dev/null
echo "verdict=$verdict"
[ "$verdict" = green ]
