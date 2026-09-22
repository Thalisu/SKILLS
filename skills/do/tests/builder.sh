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

echo "# skills/do/agents/do-builder.md: the tools the loop runs on, and the hooks that scope them"

# shellcheck disable=SC2034  # lib.sh's field reads $out
out="$(frontmatter "$agent" 2>/dev/null)" || out=""
tools="$(field tools)"
expect "the building agent's frontmatter grants it tools" test -n "$tools"

# Every tool one turn of the build loop takes: it reads the Plan and the code around a behaviour
# (Read, Glob, Grep), runs the test and commits the behaviour (Bash), writes the production code the
# test needs (Write, Edit), dispatches the test author that proves it (Agent) and reaches the
# skills the contract has it call (Skill). A missing Bash is the whole delegation dying on the first
# cycle: a fork that cannot run a command cannot turn a single test green, and nothing downstream
# recovers from it. The list is read with its separators turned to spaces and padded, so a
# `NotebookEdit` on the line never answers for `Edit`.
flat=" $(tr ',' ' ' <<<"$tools" | tr -s ' ') "
carries "the building agent holds every tool one turn of the build loop takes" \
  " Read " " Glob " " Grep " " Bash " " Write " " Edit " " Agent " " Skill "

# The Builder holds `Agent` because the loop's proof step is a dispatch, and holds it with no scope
# of its own: the Plan, the Ticket and the Digest may carry text a stranger appended to a tracker
# issue, so which agents that tool reaches is a hook-level guarantee and never prose the fork could
# be talked out of. Run live, the way the harness runs it before the Builder's Agent call.
builder_agent_hook="$(hook_command "$agent" Agent)"
expect "the building agent's Agent-matcher PreToolUse hook carries a command to extract" \
  test -n "$builder_agent_hook"

# The four test authors the policy names: a project one and a global one, per suite. A hook that
# denies any of them leaves the behaviour it covers with no test to turn green, and the loop stops
# at the first cycle that needs it.
for author in unit-test-author e2e-test-author global-unit-test-author global-e2e-test-author; do
  author_out="$(printf '{"tool_input": {"subagent_type": "%s"}}' "$author" |
    sh -c "$builder_agent_hook" 2>/dev/null)"
  expect "the hook lets the Builder dispatch $author to prove a behaviour" \
    bash -c '! grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$author_out"
done

# `choice-taker` rules a Design fork and writes the Ruling into the Spec. Forked from here it would
# rule from two layers below the session, against a Spec this fork never read, and the next Ticket
# of the same feature would be free to rule the same fork the other way: two Rulings, one Spec, and
# nothing in the run comparing them. `general-purpose` is the way around every other line of this
# hook, since it holds the tools to fork anything itself.
for forbidden in choice-taker general-purpose; do
  forbidden_out="$(printf '{"tool_input": {"subagent_type": "%s"}}' "$forbidden" |
    sh -c "$builder_agent_hook" 2>/dev/null)"
  expect "the hook denies the Builder forking $forbidden" \
    bash -c 'grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$forbidden_out"
done

# The Builder writes production code and test files, and the session's own artifacts are none of
# its business: the Plan was verified by hash before the fork and the Digest is what that hash was
# computed over, so a Builder that could write either would be rewriting the very grounding the door
# vouched for, with the session still holding the hashes it checked. Everything under a `.scratch/`
# component goes the same way: the run's state lives there and the fork reports back on its return
# line, never by editing what the session reads. Both tools are asked for by name, so the guarantee
# holds whether the block scopes them in one entry or two.
builder_write_hook="$(hook_command "$agent" Write)"
builder_edit_hook="$(hook_command "$agent" Edit)"
expect "a PreToolUse hook scopes the building agent's Write" test -n "$builder_write_hook"
expect "a PreToolUse hook scopes the building agent's Edit too" test -n "$builder_edit_hook"

for tool in Write Edit; do
  case "$tool" in
    Write) tool_hook="$builder_write_hook" ;;
    *) tool_hook="$builder_edit_hook" ;;
  esac
  for artifact in ".scratch/features/02-export/02-export.md" \
    "/home/dev/proj/.claude/worktrees/do-export/.scratch/probes/build.log" \
    "docs/02-export.plan.md" "src/export/02-export.digest.md"; do
    artifact_out="$(printf '{"tool_input": {"file_path": "%s"}}' "$artifact" |
      sh -c "$tool_hook" 2>/dev/null)"
    expect "the hook denies the Builder's $tool at $artifact, an artifact the session owns" \
      bash -c 'grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$artifact_out"
  done
  # The other half of the same hook: the code the Ticket's behaviours change is what this fork
  # exists to write, and a guard that denied it would leave the Builder unable to turn any test
  # green, which is the same dead loop as a missing Bash.
  source_out="$(printf '{"tool_input": {"file_path": "%s"}}' "src/export/notes.ts" |
    sh -c "$tool_hook" 2>/dev/null)"
  expect "the hook lets the Builder's $tool through at the source path a behaviour changes" \
    bash -c '! grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$source_out"
done

# A machine with no `jq`: a guard that reads its payload with jq and exits 0 when jq is missing is a
# guard the harness reads as allow, so on that machine every line above silently stops holding and
# nothing says so. Both hooks are asked with the input they would otherwise let through, since a
# deny there can only come from the blind path. lib.sh's path_without builds the PATH this runs on.
no_jq_dir="$(path_without jq)"
for blind in "Write $builder_write_hook" "Edit $builder_edit_hook"; do
  blind_tool="${blind%% *}"
  blind_hook="${blind#* }"
  blind_rc=0
  blind_out="$(printf '{"tool_input": {"file_path": "%s"}}' "src/export/notes.ts" |
    PATH="$no_jq_dir" sh -c "$blind_hook" 2>"$no_jq_dir/.err")" || blind_rc=$?
  blind_err="$(cat "$no_jq_dir/.err" 2>/dev/null)"
  expect "the hook on the Builder's $blind_tool fails closed when jq is absent from PATH, instead of exiting 0 silently" \
    bash -c '{ [ "$1" -ne 0 ] && [ -n "$2" ]; } || grep -qF "\"permissionDecision\": \"deny\"" <<<"$3"' \
    _ "$blind_rc" "$blind_err" "$blind_out"
done

blind_agent_rc=0
blind_agent_out="$(printf '{"tool_input": {"subagent_type": "unit-test-author"}}' |
  PATH="$no_jq_dir" sh -c "$builder_agent_hook" 2>"$no_jq_dir/.err")" || blind_agent_rc=$?
blind_agent_err="$(cat "$no_jq_dir/.err" 2>/dev/null)"
expect "the hook on the Builder's Agent fails closed when jq is absent from PATH, instead of exiting 0 silently" \
  bash -c '{ [ "$1" -ne 0 ] && [ -n "$2" ]; } || grep -qF "\"permissionDecision\": \"deny\"" <<<"$3"' \
  _ "$blind_agent_rc" "$blind_agent_err" "$blind_agent_out"
rm -rf "$no_jq_dir"

exit $((fails > 0))
