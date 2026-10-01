#!/usr/bin/env bash
# shape-fork.sh: the bug-fix and refactoring Playbooks shape boundary-crossing work by forking the
# `sketch` agent through the Agent tool, never by calling the `architect` skill. A session does what
# its Playbook's shape step says: sent to a skill, it explores the rivals in its own window, the one
# the fork exists to protect, and the Reply's Hand-over, Shaped-by and Sketch lines, written only
# when the shape step forked `sketch`, never reach the developer.
# Run: bash skills/do/tests/shape-fork.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
bugfix="$here/../references/bug-fix.md"
refactoring="$here/../references/refactoring.md"
fails=0

echo "# the shape step of the bug-fix and refactoring Playbooks forks sketch"

# The steps are flattened before the read: the Playbooks hard-wrap, and the fork's name may sit
# across a line break.
flat="$(item_holding "$bugfix" '\*\*[0-9]+\.' "crosses a function boundary" | tr '\n' ' ' | tr -s ' ')"
expect "bug-fix.md carries the step that plans a fix crossing a function boundary" test -n "$flat"
carries "bug-fix.md's shape step forks the sketch agent through the Agent tool" \
  "Agent tool" "subagent_type: sketch"

flat="$(passage_of "$refactoring" "### 4. Structure" "### 5." | tr '\n' ' ' | tr -s ' ')"
expect "refactoring.md carries step 4, Structure" test -n "$flat"
carries "refactoring.md's shape step forks the sketch agent through the Agent tool" \
  "Agent tool" "subagent_type: sketch"

out="$(cat "$bugfix")"
expect "bug-fix.md is read" test -n "$out"
absent "bug-fix.md sends no step, and no checklist line, to the architect skill" "architect"

out="$(cat "$refactoring")"
expect "refactoring.md is read" test -n "$out"
absent "refactoring.md sends no step to the architect skill" "architect"

[ "$fails" -eq 0 ] && exit 0
exit 1
