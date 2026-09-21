#!/usr/bin/env bash
# gate-no-line.sh: `## The Gate` refuses to land, never falls through silently, when a `fix` call
# gets no `command=` line at all and the project carries no Testing Policy Project facts. This is
# the state a `do` fix call reaches on a resumed run that skips its own gate (ticket.md's
# `verdict=land` resume, bug-fix.md's resume onto a Review that counts): `do` forks no reviewer for
# that call (fix.md's own "## The door" and "## The Act on list" say so), so "the tests the
# reviewers ran" the section falls back to on a plain call is never populated on a `do` call either.
# Today's text names only the two-tier fallback, Project facts else the tests the reviewers ran,
# with no case for neither existing, which lands an unchecked tree behind an always-green Gate.
# Run: bash skills/do-code-review/tests/gate-no-line.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
refs="$here/../references"
fails=0

flat="$(flat_section "$refs/fix.md" "## The Gate")"
expect "fix.md carries a ## The Gate section" test -n "$flat"

# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$flat"

carries "the section still names the two-tier fallback, Project facts else the tests the reviewers ran" \
  "the tests the reviewers ran"

# The refusal the section must carry once no command= line and no Project facts exist: a
# `not landed: ...` line, the same shape as the section's other two bullets
# (`not landed: gate red, ...` and `not landed: gate blocked, ...`), naming that a `do` call forks
# no reviewer so there is nothing to fall back to either.
no_gate_to_run=(
  "not landed: no gate to run"
  "not landed: no gate to check with"
  "not landed: no Testing Policy"
  "not landed: no Project facts"
  "not landed: nothing to gate with"
  "not landed: no command"
)
carries_any "the section refuses to land when no command= line and no Project facts exist, instead of falling through to tests the reviewers never ran" \
  "${no_gate_to_run[@]}"

exit $((fails > 0))
