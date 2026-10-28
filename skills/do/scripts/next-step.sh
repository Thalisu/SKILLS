#!/usr/bin/env bash
# next-step.sh: prints the body of a do Reply's `## Next step` section from the key=value lines a run
# holds, so the same lines on stdin print the same Next step.
#
#   <key=value lines> | next-step.sh
#
# Reads key=value lines on stdin, the last value of a key winning and keys no route reads ignored,
# so a script's output is piped whole. outcome= names the route.
# Exit codes: 0 printed · 2 usage: an argument, or a key the route needs missing; nothing on stdout.
set -uo pipefail

declare -A key

usage() {
  echo "next-step.sh: $1" >&2
  exit 2
}

read_keys() {
  local line
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      *=*) key["${line%%=*}"]="${line#*=}" ;;
    esac
  done
}

need() { # $@ the keys the route reads: exits 2 naming the first one missing
  local name
  for name in "$@"; do
    [ -n "${key[$name]:-}" ] || usage "missing $name="
  done
}

push_line() {
  need branch
  echo "git push origin ${key[branch]}"
}

main() {
  [ "$#" = 0 ] || usage "takes no argument"
  read_keys
  need outcome
  case "${key[outcome]}" in
    landed) push_line ;;
  esac
}

main "$@"
