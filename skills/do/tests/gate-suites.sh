#!/usr/bin/env bash
# gate-suites.sh: the contract of scripts/gate-suites.sh, the full suites the Post-feature gate adds
# to a run, read off the main checkout's Project facts line and completion-check.sh's last=, in a
# throwaway git repository.
# Run: bash skills/do/tests/gate-suites.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/gate-suites.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT
export HOME="$tmp/home"
mkdir -p "$HOME"

run() {
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines reads $out
  out="$(bash "$script" "$@" 2>&1)" || rc=$?
}
facts() { # $1 the Post-feature gate line's value: the main checkout's CLAUDE.md Project facts
  printf '# Project\n\n### Project facts\n\n- **Unit**: `bash run-tests.sh`\n- **Post-feature gate**: %s\n' "$1" >CLAUDE.md
}

fresh main
printf '.scratch/\n' >.gitignore
printf 'one\n' >notes.txt
commit fixture
g branch spec/x
issues=".scratch/20260930-x/issues"
mkdir -p "$issues"
printf '# Spec: x\n\nSomething to build.\n' >.scratch/20260930-x/spec.md
ticket 01-a.md '**Status:** resolved' 'None (can start immediately)'
ticket 02-b.md '**Status:** claimed' 'None (can start immediately)'

facts 'full unit suite'
run "$issues/02-b.md"
check_lines "gate-suites.sh prints full_unit=yes and full_e2e=no for the feature's last Ticket when the Post-feature gate reads full unit suite" 0 "$rc" \
  "last=yes" "full_unit=yes" "full_e2e=no"

facts 'full E2E suite'
run "$issues/02-b.md"
check_lines "gate-suites.sh prints full_unit=no and full_e2e=yes for the feature's last Ticket when the Post-feature gate reads full E2E suite" 0 "$rc" \
  "last=yes" "full_unit=no" "full_e2e=yes"

facts 'both'
run "$issues/02-b.md"
check_lines "gate-suites.sh prints full_unit=yes and full_e2e=yes for the feature's last Ticket when the Post-feature gate reads both" 0 "$rc" \
  "last=yes" "full_unit=yes" "full_e2e=yes"

[ "$fails" = 0 ]
