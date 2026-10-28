#!/usr/bin/env bash
# evidence-lines.sh: the contract of scripts/evidence-lines.sh, the Context and Forks evidence lines
# printed from the session's two context readings, fed as key=value lines on stdin.
# Run: bash skills/do/tests/evidence-lines.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/evidence-lines.sh"
fails=0

run() { # $@ the key=value lines fed on stdin
  rc=0
  # shellcheck disable=SC2034  # lib.sh's same reads $out
  out="$(printf '%s\n' "$@" | bash "$script" 2>&1)" || rc=$?
}

run grounded=48210 resumed=no current=171332 peak=171332 messages=212 band=medium forks=3 \
  'fork_kinds=Explore 1, do-code-review 2'
same "evidence-lines.sh prints Context: grounded <g>, peak <p>, <band> then Forks: <n> (<kinds>) from a measured ground reading and a measured close reading" \
  "Context: grounded 48210, peak 171332, medium
Forks: 3 (Explore 1, do-code-review 2)"
[ "$rc" = 0 ] || fail "a measured pair exits 0 (exit $rc)"

run grounded=48210 resumed=no peak=98411 band=small forks=0 fork_kinds=
check_lines "evidence-lines.sh prints Forks: 0 when the close reading counted no fork" 0 "$rc" \
  "Forks: 0"

run grounded=51004 resumed=yes peak=98411 band=small forks=2 'fork_kinds=Explore 1, do-builder 1'
check_lines "evidence-lines.sh ends a resumed run's counted Forks line with , this session only (resumed run)" 0 "$rc" \
  "Forks: 2 (Explore 1, do-builder 1), this session only (resumed run)"
run grounded=51004 resumed=yes peak=98411 band=small forks=0 fork_kinds=
check_lines "evidence-lines.sh ends a resumed run's zero Forks line with , this session only (resumed run)" 0 "$rc" \
  "Forks: 0, this session only (resumed run)"

[ "$fails" = 0 ]
