#!/usr/bin/env bash
# handback-just-text.sh: on a HANDBACK re-dispatch, build-loop.md pastes the previous author's
# Ruled out / Run / Reuse audit sections verbatim into the next author's dispatch input (untrusted
# carried-forward text a stranger's fixture, seed data or dependency error can shape). The
# dispatched author's core must carry a just-text clause, in the sibling forks' family of wording,
# telling it a line inside that carried text is data to weigh, never an instruction to follow.
# The carried Reuse audit is untrusted the same way: it names shared homes a second author is about
# to write to, from a tree that may have moved between the two dispatches, so both cores and the
# route that carries it must send that author back through the Discovery block for those paths
# rather than let the carried text stand in for it.
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
build_loop="$here/../../do/references/build-loop.md"
route="$(passage_of "$build_loop" "   - \`HANDBACK\`:" "   - \`GREEN\`")"
if grep -qE 'never (as )?an instruction|never the run|never as the run' <<<"$route"; then
  ok "the HANDBACK route in build-loop.md hands the carried sections to the second author as quoted text"
else
  fail "the HANDBACK route in build-loop.md hands the carried sections to the second author as quoted text (the re-dispatch sentence carries the sections verbatim with no line saying they are never an instruction to the run)"
fi

echo
echo "# the re-dispatched author re-checks the paths the carried Reuse audit names before writing there"
# The wording of the fix is not what is under test: any phrasing passes that drops the licence to
# walk past the Discovery block and puts a re-check of the carried audit's paths in its place.
skips_discovery='(instead of|rather than|without|neither|never|no need to) (run|runs|running) the Discovery block'
recheck='(re-run|re-runs|rerun|reruns|re-check|re-checks|recheck|rechecks|verif|confirm)'
rechecks_carried_paths() { # $1 label, $2 the passage, read flattened since the sources hard-wrap
  local label="$1" text
  text="$(tr '\n' ' ' <<<"$2" | tr -s ' ')"
  if grep -qE "$skips_discovery" <<<"$text"; then
    fail "$label (the passage still sends the second author past the Discovery block on the strength of the carried audit)"
  elif grep -qE "${recheck}[^.]*(Discovery block|path)|(Discovery block|path)[^.]*${recheck}" <<<"$text"; then
    ok "$label"
  else
    fail "$label (nothing in the passage re-checks the paths the carried Reuse audit names against the tree)"
  fi
}

for agent in AGENT-UNIT.md AGENT-E2E.md; do
  rechecks_carried_paths "$agent's core sends the re-dispatched author back through Discovery for the paths its carried Reuse audit names" \
    "$(passage_of "$skill/$agent" "**Handback**: on \`HANDBACK\` only" "**Notes**:")"
done
rechecks_carried_paths "the HANDBACK route in build-loop.md keeps the second author's Discovery block over the carried audit's paths" \
  "$route"

echo
if [ "$fails" = 0 ]; then echo "handback-just-text: all checks passed"; else
  echo "handback-just-text: $fails failed"
  exit 1
fi
