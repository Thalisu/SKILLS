#!/usr/bin/env bash
# context-band.sh: the contract of .agents/scripts/context-band.sh, the one executable form of the
# thresholds ADR 0016 gives for putting a context figure in its band.
# Run: bash scripts/tests/context-band.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/lib.sh"
script="$here/../../.agents/scripts/context-band.sh"
fails=0

run() { # $1.. the script's arguments: its output in $out, its exit in $rc
  rc=0
  # shellcheck disable=SC2034  # lib.sh's same reads $out
  out="$(bash "$script" "$@" 2>&1)" || rc=$?
}

# A figure sits in its band at the thresholds ADR 0016 gives: medium runs from 150000 to 200000,
# both ends included, and the band line is the whole of what a caller reads.
while read -r tokens want; do
  run "$tokens"
  expect "$tokens exits 0" test "$rc" = 0
  same "$tokens prints the single line band=$want" "band=$want"
done <<'EOF'
149999 small
150000 medium
200000 medium
200001 large
EOF

# A caller takes the band from stdout and tells a refusal by the exit code and the empty stdout, so
# a call that cannot be put in a band prints nothing there.
usage="usage: context-band.sh <tokens>"
refuses "a call with no figure is refused with the usage" opens "$usage"
same "a call with no figure prints nothing on stdout" ""
refuses "a call with a second argument is refused with the usage" opens "$usage" 150000 200000
same "a call with a second argument prints nothing on stdout" ""
refuses "an empty figure is refused with the usage" opens "$usage" ""
same "an empty figure prints nothing on stdout" ""
refuses "a figure that is not a number is refused with the usage" opens "$usage" 150k
same "a figure that is not a number prints nothing on stdout" ""
refuses "a negative figure is refused with the usage" opens "$usage" -1
same "a negative figure prints nothing on stdout" ""

if [ "$fails" = 0 ]; then echo "PASS"; else
  echo "$fails failing"
  exit 1
fi
