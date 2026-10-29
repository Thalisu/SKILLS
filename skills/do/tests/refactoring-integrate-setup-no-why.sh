#!/usr/bin/env bash
# refactoring-integrate-setup-no-why.sh: the refactoring, integrate and setup references a /do run
# loads carry instructions only. The why of a rule lives in the ADRs alone, so no why beside a rule
# is paid for on every run that loads one. One section per reference.
# Run: bash skills/do/tests/refactoring-integrate-setup-no-why.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
refs="$here/../references"
refactoring="$refs/refactoring.md"
integrate="$refs/integrate.md"
setup="$refs/setup.md"
fails=0

echo "# refactoring.md: instructions only, no why beside a rule"
# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$(tr '\n' ' ' <"$refactoring" | tr -s ' ')"
absent "refactoring.md keeps no why for tolerating the target-interface red" "since it fails by design"

echo "# integrate.md: instructions only, no why beside a rule"
# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$(tr '\n' ' ' <"$integrate" | tr -s ' ')"
absent "integrate.md keeps no why for resolving in the same turn" "since the loop asks the developer nothing"
absent "integrate.md keeps no why for no undo and no push on the no-op" "since nothing moved"

echo "# setup.md: instructions only, no why beside a rule"
# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$(tr '\n' ' ' <"$setup" | tr -s ' ')"
absent "setup.md keeps no why for showing no step" "since none was proven"

exit $((fails > 0))
