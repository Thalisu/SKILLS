#!/usr/bin/env bash
# fix-return-waits.sh: fix.md waits on a Wave's Fixer return files, and on the Gate fixer's, longer
# than the 50-minute budget each of those forks keeps: `returns.sh 540` windows, six at most, 54
# minutes. A deadline shorter than the fork's own budget drops a Fixer that is still working: its
# return file lands after the wait closed, its commit is never picked, and the Review cannot land.
# The wait is prose the orchestrator follows, so it is proven over the step and the paragraph that
# carry it.
# Run: bash skills/do-code-review/tests/fix-return-waits.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
fix="$here/../references/fix.md"
fails=0

six_windows=("six windows" "6 windows" "six calls" "6 calls" "six times" "six waits")

echo "# fix.md / ### The Waves: the wait on a Wave's return files outlasts the Fixer's 50-minute budget"
flat="$(item_holding <(passage_of "$fix" "### The Waves" "## ") '[0-9]+\.' "Wait for the whole Wave" | tr '\n' ' ' | tr -s ' ')"
expect "the Waves carry a step waiting for the whole Wave" test -n "$flat"
carries "the step waits with returns.sh 540, its Bash timeout at 600000 ms so the script's window closes first" \
  "returns.sh 540 " "600000"
carries_each "it calls the wait again over the files still missing=, six windows at most" \
  "missing=" -- \
  "${six_windows[@]}"
expect "the step no longer waits with the 4-minute returns.sh 240 window" \
  bash -c '! grep -qF "returns.sh 240" <<<"$1"' _ "$flat"
expect "the step no longer stops after three windows" \
  bash -c '! grep -qF "three windows" <<<"$1"' _ "$flat"

echo "# fix.md / ## The Gate fixer: the wait on the Gate fixer's return file outlasts its 50-minute budget"
flat="$(paragraph_with <(passage_of "$fix" "## The Gate fixer" "## ") "return file" all | grep -E "wait" | tr '\n' ' ' | tr -s ' ')"
expect "the Gate fixer section has a paragraph on waiting for its return file" test -n "$flat"
carries_each "the Gate fixer's return file is waited for six windows at most" \
  "${six_windows[@]}"
expect "the Gate fixer's wait no longer stops after three windows" \
  bash -c '! grep -qF "three windows" <<<"$1"' _ "$flat"

exit $((fails > 0))
