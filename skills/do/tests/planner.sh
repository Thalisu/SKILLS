#!/usr/bin/env bash
# planner.sh: the two guarantees the Planner fork at skills/do/agents/do-planner.md owes the session
# that forks it. It holds `Write` and no `Bash`: the header check the door runs compares the Plan's
# `## Sources` lines against hashes it computed itself before the fork, and that comparison only
# proves anything while the fork cannot hash anything of its own. And its body hands the session a
# path, never the Plan's text, which is the whole point of forking the grounding out of the window.
# Run: bash skills/do/tests/planner.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
agent="$here/../agents/do-planner.md"
fails=0

echo "# skills/do/agents/do-planner.md: the fork writes the Plan and cannot hash it"
expect "the do skill ships a planning agent at agents/do-planner.md" test -f "$agent"

# shellcheck disable=SC2034  # lib.sh's field reads $out
out="$(frontmatter "$agent" 2>/dev/null)" || out=""
tools="$(field tools)"

# The Plan is the fork's one output and it leaves as a file, so the tool that writes a file has to
# be on the list: without it the fork has no way to put the Plan anywhere but its return.
expect "the planning agent holds the tool it writes the Plan with" \
  bash -c '[ -n "$1" ] && grep -qE "\bWrite\b" <<<"$1"' _ "$tools"

# The door hashes the Plan's sources before forking and the session compares those hashes against
# the `## Sources` lines the fork wrote. A `Bash` on this list lets the fork compute the same hashes,
# and the check silently becomes the fork vouching for its own grounding.
expect "the planning agent holds no tool that could compute a hash of its own" \
  bash -c '[ -n "$1" ] && ! grep -qE "\bBash\b" <<<"$1"' _ "$tools"

# The body, flattened: the definition hard-wraps its prose, so a phrase sits across two lines as
# often as not. The frontmatter is dropped so its `description` never answers for the write step.
flat="$(awk 'NR == 1 && $0 == "---" { fm = 1; next } fm && $0 == "---" { fm = 0; next } !fm' "$agent" |
  tr '\n' ' ' | tr -s ' ')"
expect "the planning agent carries a body below its frontmatter" test -n "$flat"

# The session never reads the Plan, so the only way it finds one is at the path it named itself: a
# fork that picks its own path writes a Plan nothing downstream opens.
carries_any "the write step writes the Plan at the path the brief's \`Plan:\` key names" \
  "the path the brief's \`Plan:\`" "the brief's \`Plan:\` path" "the brief's \`Plan:\` key" \
  "the brief's \`Plan:\`" "the \`Plan:\` path the brief" "the \`Plan:\` key the brief" \
  "\`Plan:\` key names" "\`Plan:\` names" "the \`Plan:\` path" "the \`Plan:\` key"

carries_any "the fork returns that path" \
  "returns the path" "return the path" "Return the path" "returns that path" "return that path" \
  "Return that path" "returns only the path" "return only the path" "Return only the path" \
  "returns the Plan's path" "return the Plan's path"

# Criterion 2 of the Ticket: the Plan's text never passes through the session. A fork that returns
# its Plan inline puts the whole grounding back in the window, which is the one cost the fork exists
# to remove, and nothing else in the run would catch it.
carries_any "the fork never returns the Plan's text" \
  "never the Plan's text" "never the Plan text" "never the text of the Plan" "never its text" \
  "never the text" "not the text" "never the Plan itself" "never the Plan's body" \
  "never paste the Plan" "never pastes the Plan" "never the Plan's contents"

exit $((fails > 0))
