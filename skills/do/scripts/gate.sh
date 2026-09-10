#!/usr/bin/env bash
# gate.sh: the gate of a do run, every check the run names run once in the directory the script
# runs in, so the developer reruns the line it prints first and gets the same answer.
#
#   gate.sh <key>=<command>...    each check a key, its name in the output, and the command line
#                                 it stands for, run with bash -c in the order given
#
# Prints key=value lines, in this order: command, the line that reruns this gate as it was called;
# one <key>=green per check that exits 0; then verdict.
#
# Exit codes: 0 green · 2 usage.
set -uo pipefail

gate_here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

usage() { echo "usage: gate.sh <key>=<command>..." >&2; exit 2; }
[ "$#" -gt 0 ] || usage
for pair in "$@"; do
  [[ "$pair" =~ ^[A-Za-z0-9_.:/-]+= ]] || usage
done

printf 'command=bash %q' "$gate_here/gate.sh"; printf ' %q' "$@"; echo
verdict=green
for pair in "$@"; do
  key="${pair%%=*}"
  if bash -c "${pair#*=}" >/dev/null 2>&1; then echo "$key=green"; else echo "$key=red"; verdict=red; fi
done
echo "verdict=$verdict"
[ "$verdict" = green ]
