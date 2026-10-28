#!/usr/bin/env bash
# final-stopped-readers.sh: final-stopped.md is read by the readers its opening names, each on the
# condition that sends it, so a maintainer finds in one place when a run must read the stop's steps.
# Run: bash skills/do/tests/final-stopped-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
do_dir="$(cd "$here/.." && pwd -P)"
final_stopped="$do_dir/references/final-stopped.md"
fails=0

readers=("the Door" "The Door"
  -- "the Final integration" "The Final integration" "a Final integration" "A Final integration")
conditions=("verdict=resume-final" -- "stops")

echo "# final-stopped.md: its opening names every reader that reaches it and the condition that sends each"
expect "final-stopped.md exists" test -f "$final_stopped"
flat="$(awk '/^## /{exit} !/^# / {print}' "$final_stopped" 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
expect "final-stopped.md has an opening before its first section" grep -q '[a-z]' <<<"$flat"
carries_each "the opening names the Door and the Final integration" "${readers[@]}"
carries_each "the opening names each condition: the door printing verdict=resume-final, the Final integration when it stops" \
  "${conditions[@]}"

exit $((fails > 0))
