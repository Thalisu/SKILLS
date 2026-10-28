#!/usr/bin/env bash
# landing-route.sh: the route a run takes on a landing-order.sh record at one of its sites.
#
#   landing-route.sh <final|resume>   (the record on stdin, as landing-order.sh printed it)
#
# Prints one line, route=<value>.
#
# Exit codes: 0 routed.
set -uo pipefail

verdict=""
while IFS= read -r line; do
  case "$line" in
    verdict=*) verdict="${line#verdict=}" ;;
  esac
done

case "$1:$verdict" in
  resume:wait) echo "route=out-of-order" ;;
  *:land) echo "route=claim" ;;
  *:wait) echo "route=skip-waits" ;;
  *:ambiguous | *:unordered | *:no-spec) echo "route=blocked-$verdict" ;;
  *:landed | *:elsewhere) echo "route=skip-$verdict" ;;
  *:incomplete) echo "route=skip-open" ;;
esac
