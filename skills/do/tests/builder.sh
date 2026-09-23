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
# The third is the Design fork the build step meets now that the step is a fork's window:
# references/forks.md has to carry the Builder's half of it, the way it already carries the
# Planner's.
# Run: bash skills/do/tests/builder.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
playbook="$here/../references/ticket.md"
agent="$here/../agents/do-builder.md"
contract="$here/../references/builder.md"
planner="$here/../agents/do-planner.md"
reply="$here/../references/reply.md"
forks="$here/../references/forks.md"
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

echo "# skills/do/references/ticket.md: the build step checks the return against the branch"

# The session never reads the Plan and never reads the build: the fork's return lines are the whole
# of what it knows about the stretch, and they go into the Reply unchanged. A `behaviour:` line the
# fork invented, or one left over from a stretch it never finished, would tick a criterion nothing
# built and hand the reviewers a diff the run never looked at. The check is what stands between the
# two, and it is run against the branch, which is the one thing the fork cannot write a line about.
resume="$here/../scripts/resume-state.sh"
expect "the do skill ships the resume probe the check reads the branch through" test -f "$resume"

# The key names come off the probe itself, not out of this file: the step names `commit=`,
# `behaviour=` and `uncommitted=` to match on, so a rename in the probe has to go red here rather
# than leave the step matching on a key nothing prints any more.
resume_keys="$(grep -oE 'echo "[a-z_]+=' "$resume" | sed -E 's/^echo "//' | sort -u)"
for key in commit behaviour uncommitted; do
  expect "resume-state.sh prints a \`$key=\` line for the check to match on" \
    bash -c 'grep -qxF -- "$1=" <<<"$2"' _ "$key" "$resume_keys"
done

flat="$(item_holding "$playbook" '\*\*[0-9]+\.' "do-builder" | tr '\n' ' ' | tr -s ' ')"
expect "a step of the Playbook hands the build to the fork, to read its check off" test -n "$flat"

# The verdict decides everything that follows, and it is read off the one line the contract fixes it
# on. A step that went looking for it anywhere else routes on whatever prose the fork wrote last.
carries "the step reads the verdict off the return's first line" "first line"
carries "the step knows the three verdicts it may read there" \
  "\`built\`" "\`fork\`" "\`stopped\`"

# The check itself: the probe is run and its pairs are matched against the lines that came back, one
# for one. Matching loosely (some line matched something) is what lets a truncated return through
# with a criterion ticked and no commit behind it, so the pairing is the guarantee, not the lookup.
carries "the step runs the resume probe to read the branch, rather than trusting the return" \
  "resume-state.sh"
carries "the step matches the probe's pairs against the lines the fork returned" \
  "commit=" "behaviour=" "behaviour:"
carries_any "the match is one returned line per commit on the branch, not a loose lookup" \
  "one for one" "one-for-one" "one to one" "one-to-one" "line for line" "pair for pair"

# A `built` with work still in the worktree is a stretch the fork left half committed: the lines
# crossed back naming commits, and what the reviewers would read is not what the fork built.
carries "the step knows a build leaves nothing uncommitted behind it" "uncommitted="
carries_any "a \`built\` with uncommitted work left in the worktree does not pass the check" \
  "is empty" "empty on" "nothing uncommitted" "no \`uncommitted=\`" "no uncommitted"

# The whole point of checking. A return that fails is dropped, and the stretch is picked up from
# what the probe printed, which is the Resume section's own path: a step that checked and then
# carried on with the return anyway has bought nothing, and the fabricated line reaches the Reply.
carries_any "a return that fails either check is dropped instead of carried on with" \
  "drops the return" "drop the return" "the return is dropped" "discards the return" \
  "discard the return" "the return is discarded"
carries_any "the stretch is picked up from what the probe printed, the Resume section's own path" \
  "picks the stretch up from" "pick the stretch up from" "picks up the stretch from" \
  "picks the stretch back up from"
carries_any "the fallback is the Resume section's path, not a route invented here" \
  "the Resume section" "Resume section's own path" "the Resume section's path"

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

echo "# skills/do/references/builder.md: the brief's keys live here once, and the return is lines only"

# The Builder's side of the handover, the way plan.md is the Planner's. The Playbook's build step
# already links this file for both halves, so a missing file leaves the step naming a contract
# nothing can open and the fork filling in a brief and a return of its own invention.
expect "the do skill ships the Builder's contract at references/builder.md" test -f "$contract"

# The brief the session fills. Every key is one thing the fork cannot find for itself: where the
# Ticket and its Digest are, what the criteria say, which Plan to build from, what the developer
# already ruled, which checkout and which tree and which branch it works in, which test-author loop
# the door resolved, where the project map lives and which flow this is. A key that is not here is a
# fork guessing, or opening the session's own artifacts to guess from.
flat="$(blocks_of "$contract" "## The brief")"
carries "the brief fixes every key the fork cannot find for itself" \
  "Ticket:" "Criteria:" "Digest:" "Plan:" "Rulings:" "Repository root:" "Tree:" "Branch:" \
  "Loop:" "Project map:" "Flow:" "Agents folder:"

# Written here and nowhere else. A key list copied into a second file drifts from the brief the fork
# is actually handed: the session fills the copy, the fork reads the original, and a key that moved
# in one of them is a Builder dispatched without it, which is the reason plan.md already owns the
# Planner's keys alone. A key line is what the brief's own block writes, `<key>: <...>`, so a
# sentence naming one key in prose is not a copy of the list.
brief_keys='Ticket|Criteria|Digest|Plan|Rulings|Repository root|Tree|Branch|Loop|Project map|Flow|Agents folder'
key_lines() { # $1 the text to read; the brief key lines in it, with their line numbers, on stdout
  grep -nE "^[[:space:]]*[-*]?[[:space:]]*($brief_keys): " <<<"$1"
}

build_step="$(item_holding "$playbook" '\*\*[0-9]+\.' "do-builder")"
expect "a step of the Playbook hands the build to the fork, to read its keys off" test -n "$build_step"
step_copy="$(key_lines "$build_step")"
if [ -z "$step_copy" ]; then
  ok "the Playbook's build step keeps no second copy of the brief's keys"
else
  fail "the Playbook's build step keeps no second copy of the brief's keys (found: ${step_copy//$'\n'/; })"
fi

agent_copy="$(key_lines "$(cat "$agent")")"
if [ -z "$agent_copy" ]; then
  ok "the building agent's own definition keeps no second copy of the brief's keys"
else
  fail "the building agent's own definition keeps no second copy of the brief's keys (found: ${agent_copy//$'\n'/; })"
fi

# The return. The session routes on the first line alone and reads nothing else to decide, so the
# three terminal verdicts are what the contract has to fix: anything else coming back first is a
# return the step cannot route and the stretch is picked up from `resume-state.sh` instead.
flat="$(flat_section "$contract" "## The return")"
expect "the contract carries a section fixing what crosses back" test -n "$flat"
carries "the return's verdicts are the three the Playbook routes on" \
  "\`built\`" "\`fork\`" "\`stopped\`"
carries_any "the verdict is the return's first line, where the step reads it" \
  "first line" "opening line" "line one" "its first" "The first"

# What the Reply owes. The Behaviours list and the Build lines are copied out of these lines
# unchanged and never composed: a return that carries no `behaviour:` and `build:` pair per
# behaviour leaves the developer's reply with nothing to copy, and a session that went and read the
# diff to write it has put the build back in the window the fork exists to keep empty.
carries "the return carries a \`behaviour:\` and \`build:\` pair per behaviour" "behaviour:" "build:"
carries "the return carries the \`flow:\` line the Reply's Build lines need" "flow:"

# A Design fork is ruled in the session, against a Spec this fork never read: the report is the
# whole of what the session rules on, so it names both sides, which criterion loses and where the
# build stopped. A `fork` verdict with sides missing is a session forking the choice-taker on half a
# question.
carries "the fork report names both sides, the losing criterion and where the build stopped" \
  "fork:" "side A:" "side B:" "losing criterion:" "stopped at:"

# A stop the session can clear (a seam to change, a map slot to fill, a spent window) is cleared and
# the Builder forked again; one it cannot ends the run as blocked. Both routes read the reason off
# this line, and a `stopped` with no reason is a run blocked with nothing to act on.
carries "a stop comes back with its reason on a \`stopped:\` line" "stopped:"

# Observable criterion 1's second half, and the whole reason the fork is worth its dispatch: the
# build stays on the branch and the lines are all that cross. Nothing downstream catches a Builder
# that pastes its diff, its test output or a file back: the run still builds, still gates and still
# lands, and only the window the delegation exists to save is gone.
carries_each "nothing but those lines crosses back: no diff, no test output, no file content" \
  "never the diff" "not the diff" "no diff" "never a diff" "never the patch" "no patch" \
  -- \
  "never the test output" "not the test output" "no test output" "never test output" \
  "never the output of a test" "no test run's output" \
  -- \
  "never a file's contents" "never the file's contents" "not a file's contents" \
  "no file's contents" "never the contents of a file" "never file contents" "no file contents" \
  "never a file's content" "never the contents of any file" "never a line of a file"

echo "# skills/do/references/reply.md: the \`flow:\` lines the fork returns have a home in the Run list"

# Where a returned `flow:` line lands. The return above fixes it as one of the lines that cross
# back, and ADR 0039 makes the Reply the one place a line reaches the developer: a line with no
# numbered home in this list is a line the run reads off the return and drops on the floor. The
# home is found by what it says, not by its number, so folding it into the Build lines and giving
# it an entry of its own both count, the way gated-once.sh and reapply-step.sh find their items;
# `passage_of` keeps the search inside `## Run`, since the `## Sections` list names the flows too,
# under Evidence, and a Run line the developer never gets is not answered by an evidence line.
flow_item="$(item_holding <(passage_of "$reply" "## Run" "## Sections") '[0-9]+\.' "flow")"
expect "the Run list carries a home for the \`flow:\` lines the Builder returns" test -n "$flow_item"

# The half that costs the developer something. A flow the fork authored comes back with its commit
# and shows up in the diff either way; a criterion whose flow was skipped, for a map slot with no
# end-to-end command or for a reason the Digest gave, leaves the close's criterion unticked with
# nothing in the Reply saying why. The reason travels on the return and stops here, so the home has
# to take it.
flat="$(tr '\n' ' ' <<<"$flow_item" | tr -s ' ')"
carries_any "the home takes a criterion whose flow was skipped, with the reason it was" \
  "no flow" "not authored" "needs none" "needed none" "none is needed" "why none" \
  "the reason none" "its skip" "skipped" "the reason it was not" "the reason it did not" \
  "fallback:" "the \`fallback:\` line"

echo "# skills/do/agents/do-builder.md: the fork's own definition binds it to that same return"

# The fork reads its own definition and may never open the contract: a definition with nothing on
# what it returns leaves the fork to invent a shape, and the session's route on the first line is
# the first thing to go.
flat="$(flat_section "$agent" "## What you return")"
expect "the building agent's body says what it returns" test -n "$flat"

# It binds to the one place the set is written rather than restating it, so the fork and the session
# never read two lists that have drifted apart.
carries_any "it binds the fork to the return the contract fixes" \
  "builder.md" "references/builder.md" "the contract"

# The restatement that would drift: the fork report's own keys written out a second time here. The
# `## The return` case above is what fixes them, and this section points at it.
# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$flat"
check_absent "it restates none of the return's keys in a second place" 0 0 \
  "side A:" "side B:" "losing criterion:" "stopped at:"

echo "# skills/do/references/ticket.md: the Builder's diff is read and the tree gated before the review"

# What the session owes once the fork comes back. The Builder built the whole Ticket in a window
# nobody else saw, and the run that owns it still has to read the diff and write its own summary
# (SKILL.md's `## Non-negotiables`): a fork whose diff nothing reads hands the reviewers, forked at
# `xhigh`, work the run never looked at. And the tree they read has to have been gated first, in the
# worktree, since the review's own `fix` call is where the Gate stops being the run's from then on.
# Every anchor is a group of phrasings read with first_at, never a step's digit: the steps renumber
# whenever one is absorbed into another, which is exactly the change this case is about, and
# ground-before-claim.sh reads the same orders the same way.
build_anchor=("do-builder" "Fork the Builder" "fork the Builder" "Build.**" "Build the Ticket.**")
diff_read_anchor=(
  "reads the Builder's diff" "read the Builder's diff" "the Builder's diff is read"
  "reads the fork's diff" "read the fork's diff" "the fork's diff is read"
  "reads the diff the Builder" "reads the diff the fork" "reads the diff the build"
  "the session reads the diff" "the diff is read by the session" "the run reads the diff"
  "reads the delegate's diff" "the delegate's diff" "reads the branch's diff"
  "reads the diff on the branch" "reads the diff of the build" "git diff"
)
gate_anchor=("scripts/gate.sh" "Gate.**" "The gate in [mechanics.md](mechanics.md), in the worktree")
integration_anchor=(
  "Integration.**" "The integration in [mechanics.md](mechanics.md)"
  "the Loss ledger beside the Ticket in the main checkout"
)
review_anchor=("Review and landing.**" "git merge-base refs/heads/" "do-code-review")

steps="$(awk '/^## Steps/ { on = 1 } on' "$playbook" | tr '\n' ' ' | tr -s ' ')"
flat="$steps"
expect "the Playbook carries a \`## Steps\` section to read the order off" test -n "$flat"
b="$(first_at "${build_anchor[@]}")"
expect "a step of the Playbook forks the Builder, where the order below starts" test "$b" -gt 0

# Read from the build step on. Step 1 names the review and the diff for reasons of its own (the
# Plan's `## Map` is the subsystem before the diff, and the review is never handed it), and either
# would answer here for a step that does none of this.
flat="${steps:$((b - 1))}"
carries_any "a step has the session read the diff the Builder left on the branch" \
  "${diff_read_anchor[@]}"

d="$(first_at "${diff_read_anchor[@]}")"
g="$(first_at "${gate_anchor[@]}")"
i="$(first_at "${integration_anchor[@]}")"
r="$(first_at "${review_anchor[@]}")"

# The diff is read on the way from the fork to the Gate: read after the Gate, it is read after the
# run already spent the suite on a tree it had not looked at, and after the review it is read too
# late to be the reading the reviewers' work rests on.
expect "the diff is read after the Builder returns and before the Gate" \
  test "$d" -gt 0 -a "$g" -gt "$d"

# The Gate before the first review call is the one Gate that stays the run's own (gated-once.sh owns
# the twelve passages where a tree handed to the review's `fix` call runs none): reviewers forked
# over an ungated tree spend `xhigh` on work the suite would have refused.
expect "the Gate runs in the worktree before the integration" test "$g" -gt 0 -a "$i" -gt "$g"
expect "the integration runs before the review is called" test "$i" -gt 0 -a "$r" -gt "$i"

# The flows are the Builder's work now, authored inside its own window beside the behaviours they
# prove. A step of the session's own that still dispatches an E2E author, or still reads a report
# back, is the second loop the fork exists to remove: the window grows with the Ticket again, and
# the flows are authored twice over the same criteria.
# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="${flat:0:$((g - 1))}"
check_absent "no step between the build and the Gate dispatches an E2E author or reads its report" \
  0 0 "e2e-test-author" "E2E test author" "E2E author" "report's \`Run\` section" \
  "authored or extended"

echo "# skills/do/references/ticket.md: the todo list the run copies keeps no E2E authoring of its own"

# The `## Checklist` block is copied verbatim into the run as its todo list, so an item left there
# is an instruction the run works through whatever the steps say.
flat="$(blocks_of "$playbook" "## Checklist" | tr '\n' ' ' | tr -s ' ')"
expect "the Playbook's \`## Checklist\` carries the block the run copies" \
  bash -c '[ -n "$1" ] && grep -qF "Reply" <<<"$1"' _ "$flat"

cb="$(first_at "Build:" "the Builder forked" "Build from the Plan")"
cg="$(first_at "Gate in the worktree" "Gate:" "the Ticket's own tests, typecheck")"
expect "the todo list builds before it gates" test "$cb" -gt 0 -a "$cg" -gt "$cb"

# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="${flat:$((cb - 1)):$((cg - cb))}"
check_absent "the todo list carries no E2E flow of the session's own to author between the two" \
  0 0 "e2e-test-author" "E2E test author" "E2E flows authored" "authored or extended"

echo "# skills/do/references/forks.md: the Builder meets the build step's Design fork and rules on none"

# Since ADR 0047 the build step is the Builder's window, not the session's, so a Design fork met in
# the loop is met inside that fork. forks.md spells out the Planner's half alone, and a Builder that
# meets one mid-loop has no written route: the likeliest outcome is a commit on a design question
# nothing ruled on. The other half of the same gap is a Builder that forks the `choice-taker`
# itself. It would rule one layer deeper than anything that can write the Ruling, with the Spec's
# comments and the door's Rulings never in its hands, against criterion 4 of the Ticket and
# ADR 0036, whose own words are that the session writes the ruling. Read over the whole `## Forks`
# section, flattened: the reference hard-wraps, so its phrases sit across two lines as often as not
# and no fixed string would match on either ("in the\nbuild loop" is one of them today).
flat="$(flat_section "$forks" "## Forks")"
expect "forks.md carries the \`## Forks\` section the route is written in" test -n "$flat"

# The naming, on both axes the sentence has to settle: which fork meets it, and where. Either half
# alone leaves the run nothing to act on, so they are one case.
carries_each "the section names the Builder as a fork that meets a Design fork at the build step" \
  "the Builder" "a Builder" "do-builder" "the building fork" \
  -- "the build step" "the build loop" "at the build" "in the build"

# What the Builder does with the fork: both sides cross back on its return, the way the Planner's
# cross back in the Plan it returns. Every phrasing accepted here names the Builder, since the
# Planner's own sentence already carries "writes both sides" and would otherwise answer for a half
# nothing wrote.
carries_any "the Builder hands both sides back on its return" \
  "the Builder writes both sides" "the Builder writes the two sides" \
  "the Builder returns both sides" "the Builder returns the two sides" \
  "the Builder hands both sides" "the Builder hands the two sides" \
  "the Builder names both sides" "the Builder names the two sides" \
  "the Builder puts both sides" "the Builder's return names both sides" \
  "the Builder's return carries both sides" "both sides into the Builder's return" \
  "both sides in the Builder's return" "written into the Builder's return"

# And what it does not do. The three groups are the three things that have to stay together for the
# Ruling to land where ADR 0036 puts it: the fork is not the Builder's to make, the `choice-taker`
# is forked on the two sides, and the Ruling is written to the Spec. The last two groups already
# hold for the Planner's half, and the case keeps them so a rewrite that adds the Builder cannot
# drop them on the way through.
carries_each "the \`choice-taker\` fork and the Spec write stay the session's, never the Builder's" \
  "never the Builder" "not the Builder" "the Builder rules nothing" "the Builder never rules" \
  "no Builder forks" "never the fork that built" \
  -- "forks the \`choice-taker\`" "forks the choice-taker" "the session forks" \
  -- "writes the Ruling to the Spec" "writes the Ruling into the Spec" "the Ruling to the Spec"

echo "# skills/do/references/forks.md: an Extreme fork the Builder meets stops the run the same way"

# The Extreme stop is the one boundary never-block-on-the-human keeps for the human, and since
# ADR 0047 the build loop runs inside the Builder's window. The fork's own write guard denies every
# `.scratch/` path, so it can neither read a side as Extreme on the session's behalf nor write the
# sidecar: both are the session's, off the two sides the Builder's return carried. Said nowhere, a
# Builder that meets an Extreme fork mid-loop either commits on it or stops with no sidecar, and the
# next `/do` meets the same fork and stops again with nothing recorded. Scoped to the Extreme
# paragraphs alone, from the risk-class sentence to the `/discuss` shape: the Design fork's own
# sentence above already names the Builder and would otherwise answer for a half nothing wrote.
flat="$(passage_of "$forks" "A fork that touches a risk class" "The reply's last line is the \`/discuss\` command" |
  tr '\n' ' ' | tr -s ' ')"
expect "forks.md carries the Extreme paragraphs the stop is written in" test -n "$flat"

# Where the two sides come from when the build step found the fork. Every phrasing accepted names
# the Builder, since the sides at the Plan step come from the Plan and a sentence about those would
# leave the build step's own reading standing on nothing.
carries_any "the sides the session reads as Extreme at the build step are the ones the Builder handed back" \
  "the two sides the Builder handed back" "the two sides the Builder hands back" \
  "the sides the Builder handed back" "the sides the Builder hands back" \
  "the two sides the Builder returned" "the two sides the Builder returns" \
  "the two sides the Builder's return" "the sides the Builder's return" \
  "both sides the Builder handed back" "both sides the Builder's return" \
  "the Builder's return carries" "the Builder's return carried" \
  "the Builder handed back" "the Builder hands back" \
  "handed back by the Builder" "the Builder's return names" \
  "in the Builder's return" "on the Builder's return"

# What the stop still is once the build step's half is written in. The sidecar and the blocked shape
# already hold for the Plan step's half, and the case keeps them so a rewrite that adds the
# Builder's cannot drop either on the way through; the middle group is the new half's other side,
# the stop and its sidecar staying the session's, which the Builder's write guard makes true whether
# or not the reference says so.
carries_each "the stop keeps its blocked shape and its \`<Ticket>.extreme.md\` sidecar, both the session's and never the Builder's" \
  "<Ticket>.extreme.md" \
  -- "never the Builder" "not the Builder" "never the fork that built" \
  "the Builder writes neither" "the Builder rules on none" "the Builder never writes" \
  "the Builder's own write guard" "the session, never the Builder" \
  -- "a blocked run, written by the blocked shape" "the blocked shape of" "blocked shape"

exit $((fails > 0))
