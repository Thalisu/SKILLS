#!/usr/bin/env bash
# guard-reply.sh: prints the Reply's one Guard: line from the lines harness-hooks.sh printed.
#
#   harness-hooks.sh | guard-reply.sh
#
# Reads harness-hooks.sh's key=value lines on stdin, the last value of a key winning.
# Exit codes: 0 pattern-and-header · 1 header-only, or no guard= line on stdin (the probe failed):
# the Reply lists the line under Pending debt too · 2 usage: any argument, nothing printed.
set -uo pipefail

[ "$#" = 0 ] || {
  echo "guard-reply.sh: takes no argument" >&2
  exit 2
}

declare -A key
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    *=*) key["${line%%=*}"]="${line#*=}" ;;
  esac
done

if [ -z "${key[guard]:-}" ]; then
  echo "Guard: no verdict: the guard probe printed none; the header check alone, the whole guard."
  exit 1
fi

reading="harness=${key[harness]:-}, hooks=${key[hooks]:-}"
if [ "${key[guard]}" = pattern-and-header ]; then
  echo "Guard: guard=pattern-and-header ($reading): the pattern guard beside the header check."
  exit 0
fi
case "${key[disabled_by]:-none}" in
  none) ;;
  *) reading="$reading, disabled_by=${key[disabled_by]}" ;;
esac
echo "Guard: guard=${key[guard]} ($reading): the header check alone, the whole guard."
exit 1
