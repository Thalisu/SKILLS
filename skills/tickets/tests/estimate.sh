#!/usr/bin/env bash
# estimate.sh: the contract of scripts/estimate.sh, the arithmetic the tickets session sizes a
# slice with: the token estimate and the band that decides a fold, a keep or a split (ADR 0016).
# Run: bash skills/tickets/tests/estimate.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/estimate.sh"
fails=0

run() { # $1.. the script's arguments: its output in $out, its exit in $rc
  rc=0
  out="$(bash "$script" "$@" 2>&1)" || rc=$?
}

run size 40000 15000 5
check_lines "the estimate is the fixed load plus the per-criterion cost times the criteria, and under 150000 it is small" 0 "$rc" \
  "estimate=115000" "band=small"

run size 40000 15000 6 30000
check_lines "the crossing tokens are added to the estimate, which moves this slice into medium" 0 "$rc" \
  "estimate=160000" "band=medium"

run size 49999 20000 5
check_lines "149999 is the last small estimate" 0 "$rc" \
  "estimate=149999" "band=small"

run size 50000 20000 5
check_lines "150000 is the first medium estimate" 0 "$rc" \
  "estimate=150000" "band=medium"

run size 50000 25000 6
check_lines "200000 is the last medium estimate" 0 "$rc" \
  "estimate=200000" "band=medium"

run size 50000 25000 6 1
check_lines "200001 is the first large estimate" 0 "$rc" \
  "estimate=200001" "band=large"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
issues="$tmp/issues"
mkdir -p "$issues"
resolved='**Status:** resolved'

ticket 01-two.md "$resolved" None $'- [x] one\n- [x] two' \
  $'Context: grounded 41000, peak 97000, small\nForks: 0'
ticket 02-four.md "$resolved" None $'- [x] one\n- [x] two\n- [ ] three\n- [x] four' \
  $'Context: grounded 35000, peak 95000, small\nForks: 0'
ticket 03-five.md "$resolved" None $'- [x] one\n- [x] two\n- [x] three\n- [x] four\n- [x] five' \
  $'Context: grounded 50000, peak 160000, medium\nForks: 0'
ticket 04-unmeasured.md "$resolved" None $'- [x] one\n- [x] two\n- [x] three' \
  $'Context: not measured, no transcript\nForks: not measured, no transcript'

run calibrate "$issues/01-two.md"
check_lines "one measured ticket calibrates on its own figures: its grounded load, and its peak minus grounded over its criteria" 0 "$rc" \
  "fixed_load=41000" "per_criterion=28000" "measured=1" "calibrated=yes"

run calibrate "$issues/01-two.md" "$issues/02-four.md" "$issues/03-five.md" "$issues/04-unmeasured.md"
check_lines "several tickets calibrate on the medians of the measured ones, a ticket whose context was not measured left out" 0 "$rc" \
  "fixed_load=41000" "per_criterion=22000" "measured=3" "calibrated=yes"

run calibrate "$issues/01-two.md" "$issues/02-four.md"
check_lines "an even number of measured tickets takes the mean of the two middle values, rounded down" 0 "$rc" \
  "fixed_load=38000" "per_criterion=21500" "measured=2" "calibrated=yes"

run calibrate
check_lines "with no ticket to read, the cut runs on the stated defaults and says it is not calibrated" 0 "$rc" \
  "fixed_load=40000" "per_criterion=15000" "measured=0" "calibrated=no"

run calibrate "$issues/04-unmeasured.md"
check_lines "with only tickets whose context was not measured, the cut runs on the stated defaults and says it is not calibrated" 0 "$rc" \
  "fixed_load=40000" "per_criterion=15000" "measured=0" "calibrated=no"

# The session acts on the lines it reads, so a call the script cannot compute prints none of them.
refuses() { # $1 label, $2 opens|names, $3 the fixed string a stderr line must open with or name, $4.. the script's arguments
  local label="$1" how="$2" key="$3" why="" err
  shift 3
  rc=0
  out="$(bash "$script" "$@" 2>"$tmp/err")" || rc=$?
  err="$(cat "$tmp/err")"
  [ "$rc" = 2 ] || why="exit $rc, wanted 2"
  if grep -qE '^[a-z_]+=' <<<"$out"; then why="$why; stdout carries a key=value line"; fi
  awk -v k="$key" -v how="$how" '
    { at = index($0, k); if (how == "opens" ? at == 1 : at > 0) found = 1 }
    END { exit !found }
  ' <<<"$err" || why="$why; no stderr line $how $key"
  if [ -z "$why" ]; then ok "$label"; else
    fail "$label (${why#; })"
    dump_out
    echo "      stderr: ${err//$'\n'/$'\n'      }"
  fi
}

missing="$issues/09-missing.md"

refuses "a call with no subcommand is refused with the usage and no figure" opens "usage:"
refuses "an unknown subcommand is refused with the usage and no figure" opens "usage:" \
  measure 40000 15000 5
refuses "size with two figures is refused with the usage and no estimate" opens "usage:" \
  size 40000 15000
refuses "size with a figure that is not a number is refused with the usage and no estimate" opens "usage:" \
  size 40k 15000 5
refuses "size with a negative figure is refused with the usage and no estimate" opens "usage:" \
  size 40000 15000 -1
refuses "size with a negative crossing figure is refused with the usage and no estimate" opens "usage:" \
  size 40000 15000 5 -3
refuses "calibrate on a ticket file that does not exist is refused naming the path, with no figure" names "$missing" \
  calibrate "$missing"
refuses "calibrate on a measured ticket and a file that does not exist is refused naming the path, with no figure" names "$missing" \
  calibrate "$issues/01-two.md" "$missing"

exit "$((fails > 0))"
