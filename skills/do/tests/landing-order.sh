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

exit "$((fails > 0))"
