#!/usr/bin/env bash
# landing-route.sh: the route a run takes on a landing-order.sh record at one of its sites.
#
#   landing-route.sh <door|final|resume>   (the record on stdin, as landing-order.sh printed it)
#
# Prints one line, route=<value>.
#
# Exit codes: 0 routed.
set -uo pipefail

verdict="" repositories=0 next_landing=""
while IFS= read -r line; do
  case "$line" in
    verdict=*) verdict="${line#verdict=}" ;;
    repositories=*) repositories="${line#repositories=}" ;;
    next_landing=*) next_landing="${line#next_landing=}" ;;
  esac
done

if [ "$1" = door ]; then
  if [ "$repositories" -gt 1 ] && [ "$verdict" = landed ] && [ "$next_landing" != done ]; then
    echo "route=already-landed"
  fi
  exit 0
fi

case "$1:$verdict" in
  resume:wait) echo "route=out-of-order" ;;
  *:land) echo "route=claim" ;;
  *:wait) echo "route=skip-waits" ;;
  *:ambiguous | *:unordered | *:no-spec) echo "route=blocked-$verdict" ;;
  *:landed | *:elsewhere) echo "route=skip-$verdict" ;;
  *:incomplete) echo "route=skip-open" ;;
esac
