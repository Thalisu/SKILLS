#!/usr/bin/env bash
# usage: stretch-budget.sh <began-epoch-seconds> [<now-epoch-seconds>]
# Prints stretch=<continue|stop>: continue while the time elapsed since the Stretch began is
# under the budget, stop from the budget on. <now> defaults to the clock; a caller that holds
# its own reading hands it in. Writes nothing.
# Exit 0 when the verdict was read, 2 on usage.
set -uo pipefail

# The one place the budget is written: short enough that a Stretch returns before the session's
# cache expires (ADR 0085).
budget_minutes=40

usage() {
  echo "usage: stretch-budget.sh <began-epoch-seconds> [<now-epoch-seconds>]" >&2
  exit 2
}

[ "$#" = 1 ] || [ "$#" = 2 ] || usage
for moment in "$@"; do
  [[ "$moment" =~ ^[0-9]+$ ]] || usage
done

began="$((10#$1))"
now="$((10#${2:-$(date +%s)}))"
[ "$began" -le "$now" ] || usage

if [ "$((now - began))" -lt "$((budget_minutes * 60))" ]; then
  echo "stretch=continue"
else
  echo "stretch=stop"
fi
