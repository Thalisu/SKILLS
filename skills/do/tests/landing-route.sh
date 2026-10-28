#!/usr/bin/env bash
# landing-route.sh: the contract of scripts/landing-route.sh, the route a run takes on a
# landing-order.sh record at one of its three sites, the record read on stdin.
# Run: bash skills/do/tests/landing-route.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/landing-route.sh"
fails=0

route() { # $1 site, stdin the record: the script's stdout in $out, its exit in $rc
  rc=0
  # shellcheck disable=SC2034  # lib.sh's same reads $out
  out="$(bash "$script" "$1" 2>/dev/null)" || rc=$?
}

record() { # $1 verdict, $2 repositories (default 2), $3 next_landing (default api): a landing-order.sh record
  printf '%s\n' \
    "ticket=/home/dev/app/.scratch/20261001-feature/issues/02-consumer.md" \
    "repositories=${2:-2}" \
    "repository=api" "repository_location=/home/dev/api" "repository_here=no" \
    "repository_state=landed" "repository_ticket=01-provider.md" \
    "repository=app" "repository_location=/home/dev/app" "repository_here=yes" \
    "repository_state=unlanded" "repository_ticket=02-consumer.md" \
    "own=app" "next_landing=${3:-app}" "next_landing_location=/home/dev/app" \
    "next_landing_ticket=02-consumer.md" "verdict=$1"
}

route final < <(record land)
expect "at the final site, verdict land exits 0" [ "$rc" = 0 ]
same "at the final site, verdict land routes the run to the claim" "route=claim"

route final < <(record wait)
expect "at the final site, verdict wait exits 0" [ "$rc" = 0 ]
same "at the final site, verdict wait routes the run to the skip that waits for its provider" "route=skip-waits"

for blocked in ambiguous unordered no-spec; do
  route final < <(record "$blocked" 0)
  expect "at the final site, verdict $blocked exits 0" [ "$rc" = 0 ]
  same "at the final site, verdict $blocked routes the run to its own blocked stop" "route=blocked-$blocked"
done

for skip in landed:skip-landed elsewhere:skip-elsewhere incomplete:skip-open; do
  route final < <(record "${skip%%:*}")
  expect "at the final site, verdict ${skip%%:*} exits 0" [ "$rc" = 0 ]
  same "at the final site, verdict ${skip%%:*} routes the run to its own skip" "route=${skip#*:}"
done

route resume < <(record land)
expect "at the resume site, verdict land exits 0" [ "$rc" = 0 ]
same "at the resume site, verdict land routes the run to the claim" "route=claim"

route resume < <(record wait)
expect "at the resume site, verdict wait exits 0" [ "$rc" = 0 ]
same "at the resume site, verdict wait routes the run to the out-of-order stop" "route=out-of-order"

for other in ambiguous:blocked-ambiguous unordered:blocked-unordered no-spec:blocked-no-spec \
  landed:skip-landed elsewhere:skip-elsewhere incomplete:skip-open; do
  route resume < <(record "${other%%:*}")
  expect "at the resume site, verdict ${other%%:*} exits 0" [ "$rc" = 0 ]
  same "at the resume site, verdict ${other%%:*} routes the run as the final site routes it" "route=${other#*:}"
done

route door < <(record landed 2 api)
expect "at the door site, a landed record of two repositories with a next landing exits 0" [ "$rc" = 0 ]
same "at the door site, a record of more than one repository reading verdict landed with a next landing that is not done routes the run to the already-landed stop" "route=already-landed"

exit "$fails"
