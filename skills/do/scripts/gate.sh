#!/usr/bin/env bash
# gate.sh: the gate of a do run, every check the run names run once in the directory the script
# runs in, so the developer reruns the line it prints first and gets the same answer.
#
#   gate.sh [--infra <pattern>]... <key>=<command>...
#                                 each check a key, its name in the output, and the command line
#                                 it stands for, run with bash -c in the order given; each --infra
#                                 adds an extended regular expression, matched without case, that
#                                 marks output as the environment's rather than the code's: the
#                                 project's known infra failures
#
# Prints key=value lines, in this order: command, the line that reruns this gate as it was called;
# one line per check, <key>=green when it exits 0, otherwise <key>=red exit=<n> log=<file>, the
# file holding its full output, followed by its failing block: the output's last 20 lines, each
# indented two spaces, under a [capped: ...] line when there were more; then verdict. A check that
# failed on its environment reads <key>=blocked exit=<n> log=<file> cause=<the cause> instead:
# exit 126 or 127, a runner that cannot start, or an output line matching a built-in pattern for a
# service that is down or unreachable, or an --infra pattern, that line being the cause. Every
# check runs whatever the one before it returned, so one gate puts every failing block in front
# of the run at once. The logs are written under $TMPDIR, never in the tree the gate checks.
#
# verdict, first match wins: blocked (a check failed on its environment, which no edit to the code
# fixes) · red (a check exited non-zero) · green.
#
# Exit codes: 0 green · 1 red · 3 blocked · 2 usage.
set -uo pipefail

gate_here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
cap=20
infra=('connection refused' 'ECONNREFUSED' '(could not|cannot|unable to) connect' 'service unavailable'
  'name or service not known' 'temporary failure in name resolution' 'no such host')

usage() { echo "usage: gate.sh [--infra <pattern>]... <key>=<command>..." >&2; exit 2; }
args=("$@")
while [ "${1:-}" = --infra ]; do
  [ "$#" -ge 2 ] || usage
  infra+=("$2"); shift 2
done
[ "$#" -gt 0 ] || usage
for pair in "$@"; do
  [[ "$pair" =~ ^[A-Za-z0-9_.:/-]+= ]] || usage
done
patterns=(); for p in "${infra[@]}"; do patterns+=(-e "$p"); done

printf 'command=bash %q' "$gate_here/gate.sh"; printf ' %q' "${args[@]}"; echo
logs="$(mktemp -d "${TMPDIR:-/tmp}/do-gate.XXXXXX")" || { echo "cannot create a log directory" >&2; exit 2; }
verdict=green n=0
for pair in "$@"; do
  key="${pair%%=*}" n=$((n + 1))
  log="$logs/$n-${key//\//_}.log"
  rc=0; bash -c "${pair#*=}" >"$log" 2>&1 || rc=$?
  if [ "$rc" = 0 ]; then echo "$key=green"; rm -f "$log"; continue; fi
  cause=""
  case "$rc" in
    126 | 127) cause="runner cannot start" ;;
    *) cause="$(grep -iE -m1 "${patterns[@]}" "$log" | sed 's/^[[:space:]]*//')" ;;
  esac
  if [ -n "$cause" ]; then
    echo "$key=blocked exit=$rc log=$log cause=$cause"; verdict=blocked
  else
    echo "$key=red exit=$rc log=$log"; [ "$verdict" = blocked ] || verdict=red
  fi
  lines="$(wc -l <"$log")"
  [ "$lines" -gt "$cap" ] && echo "  [capped: the last $cap of $lines lines]"
  tail -n "$cap" "$log" | sed 's/^/  /'
done
rmdir "$logs" 2>/dev/null
echo "verdict=$verdict"
case "$verdict" in green) exit 0 ;; red) exit 1 ;; blocked) exit 3 ;; esac
