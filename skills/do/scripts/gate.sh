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
#
# Sourced, it defines gate_parse and gate_run and runs nothing: flows.sh runs its flows through
# them, so a flow's line reads exactly as a check's.
set -uo pipefail

gate_here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
gate_cap=20
gate_infra=('connection refused' 'ECONNREFUSED' '(could not|cannot|unable to) connect' 'service unavailable'
  'name or service not known' 'temporary failure in name resolution' 'no such host')

gate_parse() { # [--infra <pattern>]... <key>=<command>...: sets gate_checks and gate_patterns, 1 on bad arguments
  local p
  gate_checks=()
  while [ "${1:-}" = --infra ]; do
    [ "$#" -ge 2 ] || return 1
    gate_infra+=("$2"); shift 2
  done
  [ "$#" -gt 0 ] || return 1
  for p in "$@"; do
    [[ "$p" =~ ^[A-Za-z0-9_.:/-]+= ]] || return 1
    gate_checks+=("$p")
  done
  gate_patterns=()
  for p in "${gate_infra[@]}"; do gate_patterns+=(-e "$p"); done
}

gate_run() { # runs gate_checks in the current directory, one line per check, then the verdict; returns its exit code
  local logs verdict=green n=0 pair key log rc cause lines
  logs="$(mktemp -d "${TMPDIR:-/tmp}/do-gate.XXXXXX")" || { echo "cannot create a log directory" >&2; return 2; }
  for pair in "${gate_checks[@]}"; do
    key="${pair%%=*}" n=$((n + 1))
    log="$logs/$n-${key//\//_}.log"
    # stdin is /dev/null so a check reads the same in a terminal as in the agent's tool, which has no tty.
    rc=0; bash -c "${pair#*=}" </dev/null >"$log" 2>&1 || rc=$?
    if [ "$rc" = 0 ]; then echo "$key=green"; rm -f "$log"; continue; fi
    case "$rc" in
      126 | 127) cause="runner cannot start" ;;
      *) cause="$(grep -iE -m1 "${gate_patterns[@]}" "$log" | sed 's/^[[:space:]]*//')" ;;
    esac
    if [ -n "$cause" ]; then
      echo "$key=blocked exit=$rc log=$log cause=$cause"; verdict=blocked
    else
      echo "$key=red exit=$rc log=$log"; [ "$verdict" = blocked ] || verdict=red
    fi
    lines="$(wc -l <"$log")"
    [ "$lines" -gt "$gate_cap" ] && echo "  [capped: the last $gate_cap of $lines lines]"
    # awk ends every line it prints, where sed keeps a last line's missing newline and glues the next key onto it.
    tail -n "$gate_cap" "$log" | awk '{ print "  " $0 }'
  done
  rmdir "$logs" 2>/dev/null
  echo "verdict=$verdict"
  case "$verdict" in green) return 0 ;; red) return 1 ;; blocked) return 3 ;; esac
}

[ "${BASH_SOURCE[0]}" = "$0" ] || return 0

usage() { echo "usage: gate.sh [--infra <pattern>]... <key>=<command>..." >&2; exit 2; }
gate_parse "$@" || usage
printf 'command=bash %q' "$gate_here/gate.sh"; printf ' %q' "$@"; echo
gate_run
