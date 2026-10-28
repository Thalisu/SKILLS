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

exit "$fails"
