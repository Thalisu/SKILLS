#!/usr/bin/env bash
# landing-route.sh: the route a run takes on a landing-order.sh record at one of its sites.
#
#   landing-route.sh <door|final|resume>   (the record on stdin, as landing-order.sh printed it)
#
# Prints one line, route=<value>:
#   final:  claim · skip-waits · skip-landed · skip-elsewhere · skip-open · blocked-ambiguous ·
#           blocked-unordered · blocked-no-spec
#   resume: the final routes, with out-of-order in place of skip-waits
#   door:   already-landed · resolved
#
# Exit codes: 0 routed · 2 usage or unroutable record (nothing on stdout, one line on stderr).
set -uo pipefail

usage() {
  echo "usage: landing-route.sh <door|final|resume>" >&2
  exit 2
}

unroutable() {
  echo "landing-route.sh: $1" >&2
  exit 2
}

read_record() {
  local line verdicts=0
  verdict="" repositories=0 next_landing="" has_next=0
  while IFS= read -r line; do
    case "$line" in
      verdict=*)
        verdict="${line#verdict=}"
        verdicts=$((verdicts + 1))
        ;;
      repositories=*) repositories="${line#repositories=}" ;;
      next_landing=*)
        next_landing="${line#next_landing=}"
        has_next=1
        ;;
    esac
  done
  [ "$verdicts" = 1 ] || unroutable "the record carries $verdicts verdict= lines, wanted 1"
  case "$verdict" in
    land | wait | ambiguous | unordered | landed | elsewhere | incomplete | no-spec) ;;
    *) unroutable "unknown verdict: $verdict" ;;
  esac
}

route_for() {
  if [ "$1" = door ]; then
    [[ "$repositories" =~ ^[0-9]+$ ]] || unroutable "repositories= is no integer: $repositories"
    if [ "$repositories" -gt 1 ] && [ "$verdict" = landed ]; then
      [ "$has_next" = 1 ] || unroutable "a landed record of $repositories repositories carries no next_landing= line"
      if [ "$next_landing" != done ]; then
        echo "route=already-landed"
        return
      fi
    fi
    echo "route=resolved"
    return
  fi
  case "$1:$verdict" in
    resume:wait) echo "route=out-of-order" ;;
    *:land) echo "route=claim" ;;
    *:wait) echo "route=skip-waits" ;;
    *:ambiguous | *:unordered | *:no-spec) echo "route=blocked-$verdict" ;;
    *:landed | *:elsewhere) echo "route=skip-$verdict" ;;
    *:incomplete) echo "route=skip-open" ;;
  esac
}

[ "$#" -eq 1 ] || usage
case "$1" in
  door | final | resume) ;;
  *) usage ;;
esac
read_record
route_for "$1"
