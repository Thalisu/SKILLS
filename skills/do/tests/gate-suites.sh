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

facts 'none: the per-change tier is the whole gate, the change'"'"'s own test scripts'
run "$issues/02-b.md"
check_lines "gate-suites.sh prints full_unit=no and full_e2e=no when the Post-feature gate reads none, an explanation after a colon included" 0 "$rc" \
  "last=yes" "facts=none" "full_unit=no" "full_e2e=no"

ticket 03-c.md '**Status:** ready-for-agent' '02'
facts 'both'
run "$issues/02-b.md"
check_lines "gate-suites.sh adds no full suite for a Ticket that is not its feature's last" 0 "$rc" \
  "last=no" "full_unit=no" "full_e2e=no"
rm "$issues/03-c.md"

printf '# Project\n\n### Project facts\n\n- **Unit**: `bash run-tests.sh`\n' >CLAUDE.md
run "$issues/02-b.md"
check_lines "gate-suites.sh prints full_unit=yes on the feature's last Ticket when the project's facts carry no Post-feature gate line" 0 "$rc" \
  "last=yes" "facts=missing" "full_unit=yes" "full_e2e=no"
ticket 03-c.md '**Status:** ready-for-agent' '02'
run "$issues/02-b.md"
check_lines "gate-suites.sh prints full_unit=yes on a Ticket that is not the last when the project's facts carry no Post-feature gate line" 0 "$rc" \
  "last=no" "facts=missing" "full_unit=yes" "full_e2e=no"

facts 'full E2E suite'
run
check_lines "gate-suites.sh run with no Ticket path takes the run as the feature's last and prints last=yes" 0 "$rc" \
  "last=yes" "facts=full E2E suite" "full_unit=no" "full_e2e=yes"
rm "$issues/03-c.md"

# The Playbooks' gate steps and the Final integration take the suites off the script, so the rule
# has one home: every passage that adds the full suites names gate-suites.sh, and the gate section
# no longer maps the facts value to the suites itself.
refs="$here/../references"
for doc in mechanics.md ticket.md bug-fix.md refactoring.md; do
  bare="$(tr '\n' ' ' <"$refs/$doc" | tr -s ' ' | grep -oE '([^.]|\.[^ ])*full suites([^.]|\.[^ ])*' | grep -vF 'gate-suites.sh')"
  if [ -n "$(grep -F 'full suites' "$refs/$doc")" ] && [ -z "$bare" ]; then
    ok "$doc takes every full suite it adds from gate-suites.sh"
  else
    fail "$doc takes every full suite it adds from gate-suites.sh (left: $bare)"
  fi
done
gate="$(flat_section "$refs/mechanics.md" "## The gate")"
expect "mechanics.md carries its gate section" test -n "$gate"
if grep -qE '`full unit suite` or `both`|`none` adds nothing|no \*\*Post-feature gate\*\* line run' <<<"$gate"; then
  fail "mechanics.md states the Post-feature gate rule as prose no more"
else ok "mechanics.md states the Post-feature gate rule as prose no more"; fi

[ "$fails" = 0 ]
