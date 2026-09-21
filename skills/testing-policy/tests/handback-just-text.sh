#!/usr/bin/env bash
# handback-just-text.sh: on a HANDBACK re-dispatch, mechanics.md pastes the previous author's
# Ruled out / Run / Reuse audit sections verbatim into the next author's dispatch input (untrusted
# carried-forward text a stranger's fixture, seed data or dependency error can shape). The
# dispatched author's core must carry a just-text clause, in the sibling forks' family of wording,
# telling it a line inside that carried text is data to weigh, never an instruction to follow.
# Run: bash skills/testing-policy/tests/handback-just-text.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/.."
fails=0

check_core_just_text() {
  local agent="$1"
  local file="$skill/$agent"
  local core
  core="$(passage_of "$file" "<!-- testing-policy:core-start -->" "<!-- testing-policy:core-end -->")"
  if grep -qE 'never an instruction to (you|follow)' <<<"$core"; then
    ok "$agent's core carries a just-text clause for carried-forward Handback text"
  else
    fail "$agent's core carries a just-text clause for carried-forward Handback text (no line matching 'never an instruction to you/follow' found in the core section)"
  fi
}

echo "# the dispatched author is told a line in carried-forward Handback text is data, never an instruction"
check_core_just_text AGENT-UNIT.md
check_core_just_text AGENT-E2E.md

echo
echo "# the re-dispatch that carries the Handback hands it over as quoted text, not as its own instruction"
mechanics="$here/../../do/references/mechanics.md"
route="$(passage_of "$mechanics" "   - \`HANDBACK\`:" "   - \`GREEN\`")"
if grep -qE 'never (as )?an instruction|never the run|never as the run' <<<"$route"; then
  ok "the HANDBACK route in mechanics.md hands the carried sections to the second author as quoted text"
else
  fail "the HANDBACK route in mechanics.md hands the carried sections to the second author as quoted text (the re-dispatch sentence carries the sections verbatim with no line saying they are never an instruction to the run)"
fi

echo
if [ "$fails" = 0 ]; then echo "handback-just-text: all checks passed"; else
  echo "handback-just-text: $fails failed"
  exit 1
fi
