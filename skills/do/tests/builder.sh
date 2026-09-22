#!/usr/bin/env bash
# builder.sh: the `ticket` Playbook's build step forks the Builder instead of building in the
# developer's own window, per ADR 0047. Two things have to hold together. The step names the fork
# `do` ships, `do-builder`, and the contract that fork is handed, references/builder.md: a step that
# names neither has nothing to dispatch. And no step of the Playbook keeps an imperative that has
# the session write the production code, dispatch a test author or read a test author's report,
# read over the whole file so a build left behind in a neighbouring step is caught too: a Playbook
# that forks the Builder and still has the session build pays for the loop twice, and the window
# grows with the Ticket exactly as before, which is the one cost the fork exists to remove.
# The second subject is who does the forking: the Builder is the session's own fork and never the
# Planner's, so a test author it dispatches sits two layers below the session and never three.
# Run: bash skills/do/tests/builder.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
playbook="$here/../references/ticket.md"
agent="$here/../agents/do-builder.md"
planner="$here/../agents/do-planner.md"
fails=0

echo "# skills/do/references/ticket.md: the build step forks the Builder and the session stops building"

# The whole file on one line: the references hard-wrap their prose, so a phrase sits across two
# lines as often as not and no fixed string would match it on either.
whole="$(tr '\n' ' ' <"$playbook" | tr -s ' ')"
flat="$whole"
carries "the Playbook names the Builder fork \`do\` ships" "do-builder"

# Scoped to the step that names the fork, taken from its `**<n>.` marker to the next one: the steps
# are renumbered by every change that absorbs one into another, so the number, the title and the
# order anchor nothing. The scope is what keeps a mention anywhere else in the file from answering
# for the step that has to do the forking.
flat="$(item_holding "$playbook" '\*\*[0-9]+\.' "do-builder" | tr '\n' ' ' | tr -s ' ')"
expect "a step of the Playbook hands the build to that fork" test -n "$flat"

# A fork dispatched with no contract knows no loop, no test authors and no report to write back:
# the Builder's side of the handover is builder.md, the way the Planner's is plan.md.
carries "the step names the contract the Builder is handed" "builder.md"

# The session stops writing code. The three imperatives below are what an inline build is made of:
# the session reading the build loop and running it, dispatching once per behaviour, and reading
# the verdict a test author came back with. None of them may survive anywhere in the file, since a
# step that keeps one has the developer paying for the loop a second time and nothing downstream
# would catch it: the run still builds, still gates and still lands.
# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$whole"
check_absent "no step has the session run the build loop in its own window" 0 0 \
  "The build loop in [mechanics.md](mechanics.md)" \
  "one behaviour per dispatch" \
  "\`RED_AS_EXPECTED\`"

echo "# skills/do/agents/do-builder.md: the session forks the Builder, and nobody else does"

# Who forks the Builder decides how deep a test author it dispatches sits. Forked by the session,
# the Builder is one layer down and its test author is two; chained under the Planner it is two and
# the test author three, and on the harness default the Agent tool is withheld at the third layer
# whatever the frontmatter says, so the Builder loses the delegation entirely on the tightest
# machine. That is the shape ADR 0047 rejected by name. Two things carry the guarantee: the
# Builder's own description, which names the Playbook as its only caller the way every agent `do`
# ships does, and the Planner's own Agent hook, run live below.
expect "the do skill ships a building agent at agents/do-builder.md" test -f "$agent"

# shellcheck disable=SC2034  # lib.sh's field reads $out
out="$(frontmatter "$agent" 2>/dev/null)" || out=""

# link-skills.sh links the definition under its file name while the harness dispatches on the
# frontmatter `name`, and the Playbook step above dispatches `do-builder`: a disagreement leaves
# the step naming a fork nothing can hand the Ticket to.
expect "the building agent's file name and its frontmatter name agree" \
  test "$(field name)" = "$(basename "$agent" .md)"

flat="$(field description)"
expect "the building agent carries a description the harness shows its callers" test -n "$flat"

# The description is the whole of what a model deciding whether to fork this agent reads. One that
# names no caller, or names the do skill without naming the Playbook, leaves the Planner free to
# fork the Builder under itself, which is the three-layer chain.
carries_any "the building agent's description names the do skill's ticket Playbook as its only caller" \
  "Forked only by the do skill's ticket Playbook" \
  "Forked only by the \`do\` skill's ticket Playbook" \
  "Dispatched only by the do skill's ticket Playbook" \
  "Dispatched only by the \`do\` skill's ticket Playbook" \
  "Forked only by the ticket Playbook" "Dispatched only by the ticket Playbook" \
  "Forked by the do skill's ticket Playbook alone" \
  "Dispatched by the do skill's ticket Playbook alone" \
  "the do skill's ticket Playbook and nobody else" \
  "the do skill's ticket Playbook and no one else"

# Naming a caller says who may fork it; this says nobody else may, on their own reading of the
# description. Every agent `do` ships closes on this line.
carries_any "the building agent's description refuses a fork on anyone's own initiative" \
  "Never on your own initiative" "Never on its own initiative"

echo "# skills/do/agents/do-planner.md: the Planner's own Agent hook denies forking the Builder"

# The Builder's description is prose, and the Planner reads a Ticket and a Digest that may carry a
# stranger's text: the hook is the guarantee that survives a line telling the Planner to fork the
# Builder anyway. Run live, the way the harness runs it before the Planner's Agent call.
# Without jq the command's fail-closed path denies before it ever reads the payload, and the case
# below would pass on a hook that never looked at `do-builder` at all.
expect "jq is on PATH so the extracted hook runs its own logic, not its fail-closed exit" \
  bash -c 'command -v jq >/dev/null 2>&1'

planner_hook_cmd="$(hook_command "$planner" Agent)"
expect "the planning agent's Agent-matcher PreToolUse hook carries a command to extract" \
  test -n "$planner_hook_cmd"

builder_fork_out="$(printf '{"tool_input": {"subagent_type": "do-builder"}}' |
  sh -c "$planner_hook_cmd" 2>/dev/null)"
expect "the Planner's own hook denies it forking the Builder, so the fork stays the session's" \
  bash -c 'grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$builder_fork_out"

exit $((fails > 0))
