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
    function meets(a, b,   i, j, x, y, na, nb) {
      na = split(a, x, " "); nb = split(b, y, " ")
      for (i = 1; i <= na; i++) for (j = 1; j <= nb; j++) if (x[i] == y[j]) return 1
      return 0
    }
    {
      n = $1; files = $2
      placed = 0
      for (w = 1; w <= waves; w++) {
        if (meets(union[w], files)) continue
        members[w] = members[w] "," n
        union[w] = union[w] " " files
        placed = 1
        break
      }
      if (!placed) {
        waves++
        members[waves] = n
        union[waves] = files
      }
    }
    END { for (w = 1; w <= waves; w++) print "wave=" w " numbers=" members[w] }
  '
}

main "$@"
