#!/usr/bin/env bash
# guard-reply.sh: prints the Reply's one Guard: line from the lines harness-hooks.sh printed.
#
#   harness-hooks.sh | guard-reply.sh
#
# Reads harness-hooks.sh's key=value lines on stdin, the last value of a key winning.
# Exit codes: 0 pattern-and-header · 2 usage: any argument, nothing printed.
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

echo "Guard: guard=${key[guard]} (harness=${key[harness]}, hooks=${key[hooks]}): the pattern guard beside the header check."
