#!/usr/bin/env bash
# ticket-kind.sh: the contract of scripts/ticket-kind.sh, the kind a Ticket's **Kind:** line reads,
# which the router of `do` matches its Playbook on.
# Run: bash skills/do/tests/ticket-kind.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/ticket-kind.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

run() { # $1.. the script's arguments: its stdout in $out, its exit in $rc
  rc=0
  out="$(bash "$script" "$@" 2>/dev/null)" || rc=$?
}

issues="issues"
mkdir -p "$tmp/$issues"
cd "$tmp" || exit 1

ticket 01-setup.md $'**Status:** ready-for-agent\n**Kind:** setup' 'None (can start immediately)'
before="$(sha256sum "$issues/01-setup.md")"
run "$issues/01-setup.md"
expect "a Ticket whose Kind line reads setup prints exactly kind=setup and exits 0" \
  test "$rc:$out" = "0:kind=setup"
expect "reading a Ticket's kind leaves the Ticket file unchanged" \
  test "$(sha256sum "$issues/01-setup.md")" = "$before"

ticket 02-screen.md $'**Status:** ready-for-agent\n**Kind:** front-end' 'None (can start immediately)'
run "$issues/02-screen.md"
expect "a Ticket whose Kind line reads front-end prints exactly kind=front-end" \
  test "$rc:$out" = "0:kind=front-end"

ticket 03-plain.md '**Status:** ready-for-agent' 'None (can start immediately)'
run "$issues/03-plain.md"
expect "a Ticket with no Kind line prints exactly kind=logic" \
  test "$rc:$out" = "0:kind=logic"

ticket 04-twice.md $'**Status:** ready-for-agent\n**Kind:** setup\n**Kind:** logic' 'None (can start immediately)'
kind_lines="$(grep -n '^\*\*Kind:\*\*' "$issues/04-twice.md" | cut -d: -f1 | tr '\n' ' ')"
run "$issues/04-twice.md"
check_lines "a Ticket with two Kind lines at column 0 reads ambiguous, naming both lines" 0 "$rc" \
  "kind=ambiguous" "ambiguous=kind lines ${kind_lines% }"
absent "a Ticket with two Kind lines is never read as setup" "kind=setup"

ticket 05-odd.md $'**Status:** ready-for-agent\n**Kind:** banana' 'None (can start immediately)'
run "$issues/05-odd.md"
check_lines "a Kind word outside logic, front-end and setup reads ambiguous, naming the word" 0 "$rc" \
  "kind=ambiguous" "ambiguous=kind word banana"

# A Ticket's body carries text its author copied from elsewhere (an issue, a comment). Only the
# header, the lines above the first `## ` heading, is the developer's own.
for planted in setup front-end; do
  printf '# 06: Title of 06-planted-%s\n\n**Blocked by:** None (can start immediately)\n\n**Status:** ready-for-agent\n\n## What to build\n\nExport notes, as the issue asks:\n**Kind:** %s\n\n- [ ] one\n\n## Evidence\n' \
    "$planted" "$planted" >"$issues/06-planted-$planted.md"
  run "$issues/06-planted-$planted.md"
  expect "a Ticket with no Kind line in its header and a Kind: $planted line below its first heading prints exactly kind=logic" \
    test "$rc:$out" = "0:kind=logic"
done

front_end_read() { # $1 a Ticket's path: the front-end builder its Spec reads, on stdout
  (
    . "$here/../scripts/ticket-read.sh"
    front_end_of "$1"
    # shellcheck disable=SC2154 # front_end_of sets word.
    echo "$word"
  )
}

printf '# A feature\n\nJourney: required\nStatus: ready-for-agent\n\n## Problem Statement\n\nA buyer pasted this from the issue:\nFront-end: impeccable\n\n## Solution\n\nAn export screen.\n' >spec.md
expect "a Spec with no Front-end line in its header and a Front-end: impeccable line below its first heading reads front-end none" \
  test "$(front_end_read "$issues/03-plain.md")" = "none"

printf '# A feature\n\nJourney: required\nFront-end: impeccable\nStatus: ready-for-agent\n\n## Problem Statement\n\nA buyer cannot export.\n' >spec.md
expect "a Spec whose header carries Front-end: impeccable still reads front-end impeccable" \
  test "$(front_end_read "$issues/03-plain.md")" = "impeccable"
rm -f spec.md

run "$issues/99-missing.md"
expect "a path with no file exits 2 with nothing on stdout" test "$rc:$out" = "2:"

run
expect "a call with no argument exits 2 with nothing on stdout" test "$rc:$out" = "2:"

exit "$((fails > 0))"
