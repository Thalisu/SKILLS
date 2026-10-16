#!/usr/bin/env bash
# group-waves.sh: the grouping core of a Wave floor, so the Waves a parallel fix run forks on are a
# script's output and the same for every caller. ADR 0053, ADR 0088.
#
#   group-waves.sh < records
#
# Reads one record per line on stdin, `<n>` TAB `<path>[ <path>]...`, and prints one line per Wave:
#   wave=<w> numbers=<n>[,<n>]...
# Never knows what a number names, never opens a file, never decides what a path is.
set -uo pipefail

main() {
  awk -F'\t' '
    { members = (members == "") ? $1 : members "," $1 }
    END { print "wave=1 numbers=" members }
  '
}

main "$@"
