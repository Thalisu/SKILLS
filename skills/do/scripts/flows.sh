#!/usr/bin/env bash
# flows.sh: the affected flows of a do run, each run from the main checkout through the project's
# single-flow command, so the verification is a line the developer reruns rather than a run's
# account of it. Run from anywhere inside the project, the main checkout or a worktree of it.
#
#   flows.sh [--infra <pattern>]... <single-flow command> <flow>...
#                                 the single-flow command of the project's facts, the first {} in
#                                 it marking where a flow goes and the flow appended when it has
#                                 none; each flow a path or a name that command takes, and its key
#                                 in the output; --infra as gate.sh takes it
#
# Prints key=value lines, in this order: command, the line that reruns these flows as they were
# called; one line per flow in the shape gate.sh prints a check in, keyed by the flow; then
# verdict. It asks nothing: a full suite or a remote run is the session's question, put to the
# developer before this script runs.
#
# verdict, first match wins: blocked · red · green, as gate.sh reads them.
#
# Exit codes: 0 green · 1 red · 3 blocked · 2 usage, or not a git repository.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=gate.sh
source "$here/gate.sh"

usage() { echo "usage: flows.sh [--infra <pattern>]... <single-flow command> <flow>..." >&2; exit 2; }
args=("$@")
infra=()
while [ "${1:-}" = --infra ]; do
  [ "$#" -ge 2 ] || usage
  infra+=(--infra "$2"); shift 2
done
[ "$#" -ge 2 ] || usage
template="$1"; shift
pairs=()
for flow in "$@"; do
  # A flow is a name the run passes in, so it reaches the command line quoted and never as text.
  quoted="$(printf %q "$flow")"
  if [[ "$template" == *"{}"* ]]; then cmd="${template%%\{\}*}$quoted${template#*\{\}}"; else cmd="$template $quoted"; fi
  pairs+=("$flow=$cmd")
done
gate_parse "${infra[@]}" "${pairs[@]}" || usage

top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not a git repository" >&2; exit 2; }
# A bare main worktree has no working tree to anchor on, and git lists it first all the same.
main="$(git worktree list --porcelain 2>/dev/null |
  awk '/^$/ { exit } /^worktree /{ p = substr($0, 10) } /^bare$/ { p = "" } END { print p }')"
[ -n "$main" ] && [ -d "$main" ] || main="$top"

printf 'command=bash %q' "$here/flows.sh"; printf ' %q' "${args[@]}"; echo
cd "$main" || exit 2
gate_run
