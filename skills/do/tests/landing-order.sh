#!/usr/bin/env bash
# landing-order.sh: the contract of scripts/landing-order.sh, the order a complete feature's
# repositories land in, exercised in two sibling throwaway git repositories.
# Run: bash skills/do/tests/landing-order.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/landing-order.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT
export HOME="$tmp/home"
mkdir -p "$HOME"

run() { # $1.. the script's arguments: its output in $out, its exit in $rc
  rc=0
  out="$(bash "$script" "$@" 2>&1)" || rc=$?
}
groups() { # the repository groups the caller left in $out, without their repository_here line, in their order, on stdout
  grep -E '^(repository|repository_location|repository_state|repository_ticket)=' <<<"$out"
}

# The consumer holds the lowest-numbered Ticket and is listed first in the Spec, so neither the
# Ticket numbers nor the list order puts the provider ahead of it: only the Blocked by edge does.
sibling_repos land-web land-api 20261001-export
# shellcheck disable=SC2154 # lib.sh's sibling_repos assigns $home, $build and $issues
repositories_spec "$home/.scratch/20261001-export" "- land-web (Home repository): $home" "- land-api: $build"
ticket 01-web-screen.md $'**Status:** resolved\n\n**Build repository:** land-web' 'None (can start immediately)'
ticket 02-api-model.md $'**Status:** resolved\n\n**Build repository:** land-api' 'None (can start immediately)'
ticket 03-api-export.md $'**Status:** resolved\n\n**Build repository:** land-api' '02, Title of 02-api-model'
ticket 04-web-download.md $'**Status:** resolved\n\n**Build repository:** land-web' '03, Title of 03-api-export'
for repo in "$home" "$build"; do
  (cd "$repo" && g branch -q --track spec/export main && spec_commit spec/export) ||
    echo "FAIL  fixture: the unlanded Spec branch of $repo could not be built"
done

cd "$build" || exit 1
# shellcheck disable=SC2154
run "$issues/03-api-export.md"
check_lines "the landing record of a complete feature across two sibling repositories counts both, with exit 0" 0 "$rc" \
  "repositories=2"
want="repository=land-api
repository_location=$build
repository_state=unlanded
repository_ticket=$issues/03-api-export.md
repository=land-web
repository_location=$home
repository_state=unlanded
repository_ticket=$issues/04-web-download.md"
if [ "$(groups)" = "$want" ]; then
  ok "the provider's group is printed before the group of the repository whose Ticket it blocks, each with its listed location, its unlanded state and its highest-numbered Ticket"
else
  fail "the provider's group is printed before the group of the repository whose Ticket it blocks, each with its listed location, its unlanded state and its highest-numbered Ticket"
  dump_out
fi

after_groups() { # the lines the caller's $out carries past its last repository group, in their order, on stdout
  awk '/^repository(_[a-z]+)?=/ { tail = ""; next } { tail = tail $0 "\n" } END { printf "%s", tail }' <<<"$out"
}
lands() { # $1 label, $2 the repository the record is read from, $3 its name, $4 the argument Ticket's file name, $5 the file name of its highest-numbered Ticket
  local want_tail="own=$3
waits_for=none
next_landing=$3
next_landing_location=$2
next_landing_ticket=$issues/$5
verdict=land"
  cd "$2" || exit 1
  run "$issues/$4"
  if [ "$rc" = 0 ] && [ "$(after_groups)" = "$want_tail" ]; then ok "$1"; else
    fail "$1 (exit $rc, wanted 0 and, past the groups: ${want_tail//$'\n'/ · })"
    dump_out
  fi
}
lands "from the provider, with both repositories unlanded, the record closes on its own repository waiting for none, named as the next landing with its location and highest-numbered Ticket, and the verdict land" \
  "$build" land-api 02-api-model.md 03-api-export.md

# Both Spec branches are still unlanded here: the cases below are the ones that move the refs.
want_tail="own=land-web
waits_for=land-api
waits_for_location=$build
next_landing=land-api
next_landing_location=$build
next_landing_ticket=$issues/03-api-export.md
verdict=wait"
cd "$home" || exit 1
run "$issues/01-web-screen.md"
label="from the consumer, with its provider unlanded, the record closes on its own repository waiting for the provider at its listed location, the provider's highest-numbered Ticket as the next landing, and the verdict wait"
if [ "$rc" = 0 ] && [ "$(after_groups)" = "$want_tail" ]; then ok "$label"; else
  fail "$label (exit $rc, wanted 0 and, past the groups: ${want_tail//$'\n'/ · })"
  dump_out
fi

state_of() { # $1 repository name: the repository_state of its group in the caller's $out, on stdout
  awk -v r="repository=$1" '$0 == r { on = 1; next } /^repository=/ { on = 0 } on && sub(/^repository_state=/, "")' <<<"$out"
}
touched=""
reads() { # $1 label, $2 the repository the record is read from, $3 the state wanted of land-api, $4 the state wanted of land-web
  # appends the label to $touched when the call changed a ref or a working file of either repository
  local before
  before="$(cd "$home" && both_states "$build")"
  cd "$2" || exit 1
  run "$issues/03-api-export.md"
  if [ "$rc" = 0 ] && [ "$(state_of land-api)" = "$3" ] && [ "$(state_of land-web)" = "$4" ]; then ok "$1"; else
    fail "$1 (exit $rc, wanted land-api $3 and land-web $4)"
    dump_out
  fi
  [ "$(cd "$home" && both_states "$build")" = "$before" ] || touched="$touched; $1"
}
# The landed state has to come from land-web's refs alone, so the case fails on a Feature folder
# holding anything an earlier landing attempt would have left beside the Spec and its Tickets.
feature_files="./issues/01-web-screen.md
./issues/02-api-model.md
./issues/03-api-export.md
./issues/04-web-download.md
./spec.md"
landed_here() { # $1 label: the record read from land-web on one of its own Tickets, with land-web landed and land-api unlanded
  local found
  found="$(cd "$home/.scratch/20261001-export" && find . -type f | sort)"
  cd "$home" || exit 1
  run "$issues/04-web-download.md"
  if [ "$found" != "$feature_files" ]; then
    fail "$1 (fixture: the Feature folder holds more than the Spec and its Tickets: ${found//$'\n'/ · })"
    return
  fi
  if [ "$(state_of land-web)" != landed ] || [ "$(state_of land-api)" != unlanded ]; then
    fail "$1 (exit $rc, wanted land-web landed and land-api unlanded)"
    dump_out
    return
  fi
  check_lines "$1" 0 "$rc" \
    "own=land-web" \
    "next_landing=land-api" \
    "next_landing_location=$build" \
    "next_landing_ticket=$issues/03-api-export.md" \
    "verdict=landed"
}

# Each state is moved with plain git between two identical calls, and the two repositories never
# share one, so a record kept from an earlier call or read off the session's repository alone
# answers wrong for one of them.
g -C "$home" merge -q --ff-only spec/export ||
  echo "FAIL  fixture: the upstream of land-web's Spec branch could not be fast-forwarded to its tip"
reads "from the unlanded repository, a sibling whose Spec branch tip reached its upstream reads landed" \
  "$build" unlanded landed
reads "from the repository whose Spec branch tip reached its upstream, a sibling whose Spec branch holds a commit its upstream lacks reads unlanded" \
  "$home" unlanded landed
landed_here "from the repository whose Spec branch tip reached its upstream, with its sibling unlanded, the record reads its own group landed, the sibling as the next landing with its location and highest-numbered Ticket, and the verdict landed"
g -C "$home" branch -q -D spec/export ||
  echo "FAIL  fixture: land-web's Spec branch could not be removed"
reads "from the unlanded repository, a sibling whose Spec branch was already removed reads landed" \
  "$build" unlanded landed
reads "from the repository whose Spec branch was already removed, it reads landed and its unlanded sibling unlanded" \
  "$home" unlanded landed
landed_here "from the repository whose Spec branch was already removed, with its sibling unlanded, the record reads the same: its own group landed, the sibling as the next landing, and the verdict landed"
g -C "$build" merge -q --ff-only spec/export ||
  echo "FAIL  fixture: the upstream of land-api's Spec branch could not be fast-forwarded to its tip"
reads "the same call, once the sibling's upstream reached its Spec branch tip, reads that sibling landed" \
  "$home" landed landed
g -C "$build" branch -q -D spec/export ||
  echo "FAIL  fixture: land-api's Spec branch could not be removed"
reads "the same call, once the sibling's Spec branch is removed too, still reads both repositories landed" \
  "$home" landed landed
reads "from the sibling, with both Spec branches removed, both repositories read landed" \
  "$build" landed landed
expect "no reading of the record changes a ref or a file of either repository or of the Home feature folder${touched:+ (changed by:${touched#;})}" \
  test -z "$touched"

# The cases above end with both Spec branches removed, so the consumer's is rebuilt here: the
# provider stays landed and the consumer is the one repository left to land.
(cd "$home" && g branch -q --track spec/export main && spec_commit spec/export) ||
  echo "FAIL  fixture: the unlanded Spec branch of land-web could not be rebuilt"
lands "from the consumer, once its provider has landed, the record closes on its own repository waiting for none, named as the next landing with its location and highest-numbered Ticket, and the verdict land" \
  "$home" land-web 01-web-screen.md 04-web-download.md

incomplete() { # $1 label, $2 the repository the record is read from, $3 the argument Ticket's file name, $4 the ticket= value wanted
  # the whole of stdout must be the three lines of an incomplete feature, with exit 0; stderr is read apart and only shown on a red
  local want_out="ticket=$4
repositories=0
verdict=incomplete"
  cd "$2" || exit 1
  rc=0
  out="$(bash "$script" "$issues/$3" 2>"$tmp/incomplete.err")" || rc=$?
  if [ "$rc" = 0 ] && [ "$out" = "$want_out" ]; then ok "$1"; else
    fail "$1 (exit $rc, wanted 0 and the whole of stdout: ${want_out//$'\n'/ · })"
    dump_out
    echo "      stderr: $(cat "$tmp/incomplete.err")"
  fi
}

# These cases come last: they reopen Tickets and, in the end, repoint the Spec's Repositories list.
ticket 04-web-download.md $'**Status:** claimed\n\n**Build repository:** land-web' '03, Title of 03-api-export'
incomplete "from a repository whose own Tickets are resolved, while a Ticket built in the other repository reads claimed, the record is the Ticket, no repository and the verdict incomplete, with no group, own, waits_for or next_landing line" \
  "$build" 03-api-export.md "$issues/03-api-export.md"
ticket 04-web-download.md $'**Status:** ready-for-agent\n\n**Build repository:** land-web' '03, Title of 03-api-export'
incomplete "the record is the same three lines while that Ticket reads ready-for-agent" \
  "$build" 03-api-export.md "$issues/03-api-export.md"
ticket 04-web-download.md $'**Status:** resolved\n\n**Build repository:** land-web' '03, Title of 03-api-export'
ticket 03-api-export.md $'**Status:** claimed\n\n**Build repository:** land-api' '02, Title of 02-api-model'
incomplete "from the Home repository, with the open Ticket built in the provider instead, the record is the same three lines and names the Ticket relative to the main checkout" \
  "$home" 01-web-screen.md ".scratch/20261001-export/issues/01-web-screen.md"
ticket 03-api-export.md $'**Status:** resolved\n\n**Build repository:** land-api' '02, Title of 02-api-model'
ticket 04-web-download.md $'**Status:** claimed\n\n**Build repository:** land-web' '03, Title of 03-api-export'
# A record that probed the other repository would have to enter this folder, which does not exist.
repositories_spec "$home/.scratch/20261001-export" "- land-web (Home repository): $tmp/land-gone" "- land-api: $build"
incomplete "the record is the same three lines when the other repository's listed location cannot be entered, so no repository was probed" \
  "$build" 03-api-export.md "$issues/03-api-export.md"

# A feature of one repository, in a repository of its own: its Spec lists no repository and its
# Tickets name none, so the session's repository is the only one there is to land.
fresh land-solo
printf '.scratch/\n' >.gitignore
printf 'one\n' >notes.txt
commit fixture
solo="$(pwd -P)"
issues="$solo/.scratch/20261002-solo/issues"
mkdir -p "$issues"
printf '# Spec: one repository\n\n## User Stories\n\n1. As a developer, I want a note exported, so that I can share it.\n' >"$solo/.scratch/20261002-solo/spec.md"
ticket 01-solo-model.md '**Status:** resolved' 'None (can start immediately)'
ticket 02-solo-export.md '**Status:** resolved' '01, Title of 01-solo-model'
(g branch -q --track spec/solo main && spec_commit spec/solo) ||
  echo "FAIL  fixture: the unlanded Spec branch of land-solo could not be built"
want_out="ticket=.scratch/20261002-solo/issues/01-solo-model.md
repositories=1
repository=none
repository_location=$solo
repository_here=yes
repository_state=unlanded
repository_ticket=$issues/02-solo-export.md
own=none
waits_for=none
next_landing=none
next_landing_location=$solo
next_landing_ticket=$issues/02-solo-export.md
verdict=land"
rc=0
out="$(bash "$script" "$issues/01-solo-model.md" 2>"$tmp/solo.err")" || rc=$?
label="on a feature whose Tickets carry no Build repository line, the record is one group named none at the session's main checkout, here and unlanded, with the folder's highest-numbered Ticket, waiting for none, and the verdict land"
if [ "$rc" = 0 ] && [ "$out" = "$want_out" ]; then ok "$label"; else
  fail "$label (exit $rc, wanted 0 and the whole of stdout: ${want_out//$'\n'/ · })"
  dump_out
  echo "      stderr: $(cat "$tmp/solo.err")"
fi

exit "$((fails > 0))"
