#!/usr/bin/env bash
# estimate.sh: the arithmetic of a ticket's estimate, so the tickets session reads a figure and a
# band off a line instead of computing them itself. Run from anywhere.
#
#   estimate.sh calibrate <resolved ticket file>...
#   estimate.sh size <fixed load> <per-criterion cost> <criteria> [<crossing tokens>]
#
# calibrate reads each file's `Context: grounded <tokens>, peak <tokens>, <band>` line and counts its
# checkbox lines as the criteria, then prints key=value lines in tokens: fixed_load=<tokens>, the
# median of the grounded figures; per_criterion=<tokens>, the median across those tickets of peak
# minus grounded over the criteria count; measured=<n>, the tickets whose line carried figures; and
# calibrated=yes. A file whose line reads `Context: not measured` is left out. A median over an even
# count is the mean of the two middle values, and every division rounds down. With no measured
# ticket, no file included, it prints the defaults, 40000 and 15000, with measured=0 and
# calibrated=no.
# size prints estimate=<tokens>, the fixed load plus the per-criterion cost times the criteria plus
# what the slice crosses, then band=<small|medium|large>, where the estimate falls (small under
# 150k, medium up to 200k, large beyond), the bands ADR 0016 gives a ticket and the ones `do` reads
# a measured peak against.
# Exit codes: 0 · 2 usage: no or an unknown subcommand, a size figure missing or not a non-negative
# integer, or a ticket file that does not exist, named on stderr; nothing is printed on stdout then
set -euo pipefail

# ADR 0016's stated defaults, cut on until the project has a measured ticket.
default_fixed_load=40000
default_per_criterion=15000

usage() {
  echo "usage: estimate.sh calibrate <resolved ticket file>... | size <fixed load> <per-criterion cost> <criteria> [<crossing tokens>]" >&2
  exit 2
}

median() { # stdin: one integer per line
  sort -n | awk '{ v[NR] = $1 } END { print (NR % 2) ? v[(NR + 1) / 2] : int((v[NR / 2] + v[NR / 2 + 1]) / 2) }'
}

calibrate() {
  local figures file
  for file in "$@"; do
    [ -f "$file" ] || { echo "no ticket file at $file" >&2; exit 2; }
  done
  figures="$(
    for file in "$@"; do
      awk '
        /^- \[[ xX]\] / { criteria++ }
        /^Context: grounded [0-9]+, peak [0-9]+/ { grounded = $3 + 0; peak = $5 + 0; measured = 1 }
        END { if (measured && criteria > 0) print grounded, int((peak - grounded) / criteria) }
      ' "$file"
    done
  )"
  if [ -z "$figures" ]; then
    printf 'fixed_load=%s\nper_criterion=%s\nmeasured=0\ncalibrated=no\n' "$default_fixed_load" "$default_per_criterion"
    return
  fi
  printf 'fixed_load=%s\nper_criterion=%s\nmeasured=%s\ncalibrated=yes\n' \
    "$(cut -d' ' -f1 <<<"$figures" | median)" "$(cut -d' ' -f2 <<<"$figures" | median)" "$(wc -l <<<"$figures" | tr -d ' ')"
}

size() {
  local figure
  [ "$#" -ge 3 ] && [ "$#" -le 4 ] || usage
  for figure in "$@"; do
    case "$figure" in "" | *[!0-9]*) usage ;; esac
  done
  local fixed_load="$1" per_criterion="$2" criteria="$3" crossing="${4:-0}" estimate band
  estimate=$((10#$fixed_load + 10#$per_criterion * 10#$criteria + 10#$crossing))
  if [ "$estimate" -lt 150000 ]; then band=small; elif [ "$estimate" -le 200000 ]; then band=medium; else band=large; fi
  printf 'estimate=%s\nband=%s\n' "$estimate" "$band"
}

[ "$#" -ge 1 ] || usage
command="$1"
shift
case "$command" in
  calibrate | size) "$command" "$@" ;;
  *) usage ;;
esac
