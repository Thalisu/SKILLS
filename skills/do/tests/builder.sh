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
# The fourth is the shared mechanics all three Playbooks read: `## Delegates` carries ADR 0009's
# one-writer rule, which ADR 0047 supersedes for `ticket` alone, so the rule has to name the runs
# it is about rather than stand over every one of them.
# Run: bash skills/do/tests/builder.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
playbook="$here/../references/ticket.md"
agent="$here/../agents/do-builder.md"
contract="$here/../references/builder.md"
planner="$here/../agents/do-planner.md"
reply="$here/../references/reply.md"
run_report="$here/../references/run-report.md"
forks="$here/../references/forks.md"
mechanics="$here/../references/mechanics.md"
stand_in="$here/../references/stand-in.md"
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

# A resumed run's branch carries pairs earlier stretches already committed and the fork never
# repeats in its return: matching against the whole branch would demand a returned line for a pair
# this fork never touched, and every resumed run would fail the check the same way.
carries_any "the match is scoped to this fork's own stretch, not the whole branch" \
  "as many trailing pairs as there are" "this fork's own stretch" \
  "never a pair an earlier stretch already committed and returned before" \
  "already committed and returned before"

# A flow this fork commits on its own carries no `Behaviour:` line, so resume-state.sh prints a
# `behaviour=<sha> none` pair with nothing in the return to match it against: a check that still
# demanded a match would fail every run whose flow landed as its own commit.
carries_any "a standalone flow commit's \`behaviour=<sha> none\` pair needs no returned line to match" \
  "behaviour=<sha> none" "carries no \`Behaviour:\` line" "needs no returned line to match"

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

# The other half of what the return has to be checked against: the Plan the fork was handed. The
# door verified its `## Sources` section by hash before the fork, and the session never reads the
# Plan back after that, so today nothing reads that grounding again once a fork that held a shell
# in the worktree has run. The Builder's Bash guard denies the obvious route, and a guard is one
# layer: a Plan rewritten while the fork held the tree is routed on as if the door still vouched
# for it, its `behaviour:` lines are copied into the Reply, and the run builds, gates and lands on
# grounding nobody checked. The check is the file's own, run once more here with the two records
# the door computed, and it has to come before the route, since routing on `built` is what copies
# those lines out.
carries "the step reads the Plan's grounding once more, through the file's own \`## Sources\` check" \
  "## Sources"

sources_at="$(first_at "## Sources")"
route_at="$(first_at "Route on the first line")"
expect "the grounding is read again before the return is routed on, never after" \
  test "$sources_at" -gt 0 -a "$route_at" -gt "$sources_at"

# Read from the re-check to the route, so the return check above it and the routes below it cannot
# answer for what this one does.
step="$flat"
flat="${step:$((sources_at > 0 ? sources_at - 1 : ${#step})):$((route_at > sources_at ? route_at - sources_at : 0))}"
carries_any "the re-check is the door's own two records, not a reading the session composes here" \
  "the same two hashes" "the same hashes" "the two hashes the door" "the hashes the door" \
  "the door's own hashes" "the door's two hashes" "the same two records" "the two records the door" \
  "the door's own two records" "the same records"
carries "the step knows the word the check prints on a Plan that no longer matches" "refused"
carries_any "a \`refused\` there is a return the step drops instead of routing on" \
  "drops the return" "drop the return" "the return is dropped" "is dropped" "dropped" \
  "discards the return" "discard the return" "the return is discarded" "discarded"
flat="$step"

# The resume path itself: a resumed run with behaviours left unbuilt has to fork the Builder at the
# first one with no commit, the same fork step 3 already runs on a first pass, never run the build
# loop and author the flows in the session's own window, which is exactly what the pre-fix wording
# had it do and what criterion 3 of the governing Ticket exists to prevent (the run reads the
# Builder's diff and gates before the review, so nothing reaches the reviewers the run never checked).
flat="$(flat_section "$here/../references/resume.md" "## Resume")"
expect "resume.md carries a \`## Resume\` section to scope this check against" test -n "$flat"

carries_any "a resumed run with unbuilt behaviours forks the Builder rather than running the loop itself" \
  "The Builder is forked" "the Builder is forked"

# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$flat"
check_absent "the Resume section no longer has the run build the flows itself before the gate" 0 0 \
  "the flows, the gate, the review, the close, the reply"

# The branch where every behaviour is already ticked still meets the fork's diff, never a flow it
# treats as self-authored: it goes on at step 4 the way a first run does, reading the Builder's diff.
flat="$(flat_section "$here/../references/resume.md" "## Resume")"
carries_any "the branch where every behaviour is ticked reads the Builder's diff already on the branch" \
  "reading the diff already on the branch" "reads the diff already on the branch" \
  "the diff already on the branch"

# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$flat"
check_absent "that branch no longer treats a flow already on the branch as self-authored" 0 0 \
  "a flow already on the branch counting as authored"

echo "# skills/do/scripts/resume-state.sh: an issue-backed Ticket, resolved through the tracker"

# The step above runs the probe on "the Ticket's path", but a Ticket resolved through the tracker
# (docs/agents/issue-tracker.md, e.g. "#42") is never a local file: the probe has to resolve the
# bare issue reference straight to the do-<slug> worktree the door already created, the same slug
# ticket.md already reads that reference as elsewhere (.scratch/plans/42.plan.md for issue 42), or
# the check above can never pass on an issue-backed run and drops every good `built` return.
btmp="$(mktemp -d)"
trap 'cd /; rm -rf "$btmp"' EXIT
mkdir -p "$btmp/repo" && cd "$btmp/repo" || exit 1
git init -q -b main >/dev/null
committer_identity
printf 'one\n' >notes.txt
git add -A && git commit -qm fixture >/dev/null
echo ".claude/worktrees/" >>.git/info/exclude
git worktree add -q .claude/worktrees/do-42 -b do/42
bwt="$(pwd -P)/.claude/worktrees/do-42"
printf 'two\n' >>"$bwt/notes.txt"
git -C "$bwt" commit -qam "feat: close the issue" -m "Behaviour: the issue's fix lands"
bshort="$(git -C "$bwt" rev-parse --short HEAD)"
brc=0
bout="$(bash "$resume" "#42" 2>&1)" || brc=$?
out="$bout"
# The pairs are what the step matches the return against, so they are the outcome here: a probe that
# resolved the reference and then printed no pair leaves the step dropping the build all the same.
check_lines "an issue reference resolves to its do-<slug> worktree, printing the probe's pairs" 0 "$brc" \
  "worktree=$bwt" "branch=do/42" "commit=$bshort feat: close the issue" \
  "behaviour=$bshort the issue's fix lands" "verdict=build"
cd "$here" || exit 1

echo "# skills/do/references/stand-in.md: the two runs with no Builder to fork, and what each is told"

# The run that cannot fork the Builder at all, the way the Plan step already writes the Planner's
# half (planner.sh owns that one). Scoped to stand-in.md's Builder section, the reference the build
# step points at on either branch, so the reader's own section cannot answer here for a Builder
# section that says nothing. Each guarantee below can be phrased several ways and the cases pin more
# than one at a time, so the group of phrasings that found nothing is what a failure names: lib.sh's
# carries_each.
flat="$(flat_section "$stand_in" "## The Builder")"
expect "stand-in.md carries the Builder's fallback, to read it off" test -n "$flat"

# The two branches, named apart. A harness that withheld the Agent tool and a machine that never ran
# `scripts/link-skills.sh` both reach the same dead end, and the developer's way out differs: one is
# the harness, the other is one run of the installer. A message naming a single branch, or naming
# the dead end without saying which produced it, leaves them guessing which of the two to go fix.
carries_each "the step names both branches on which no Builder can be forked" \
  "Agent tool withheld" "Agent tool is withheld" "no Agent tool" \
  -- \
  "lists no \`do-builder\`" "\`do-builder\` not listed" "no \`do-builder\` listed" \
  "lists no do-builder" "do-builder not listed" "no do-builder listed"

# What the run does on either one. The Ticket still has to be built, and the only builder left is
# the session: a branch that named the dead end and stopped there ends the run with a claimed Ticket
# and an empty worktree on the two machines least able to diagnose it.
carries_any "on either branch the session runs the build loop in its own window" \
  "the session runs the loop itself" "the session runs the build loop itself" \
  "runs the build loop itself" "runs the loop itself" "the session builds itself" \
  "does the build itself" "builds the Ticket itself"

# The degraded run and the forked one leave the same commits on the same branch, so this line is the
# only thing that tells the developer their own window carried the build, and which of the two
# branches to go fix. Every phrasing accepted names the choice: the `fork` verdict's own route above
# already says the run "says in one line" about something else entirely.
carries_each "the run says in one line which of the two branches held" \
  "which of the two holds" "which of the two held" "which branch holds" "which branch held" \
  "which of the two branches held" "which of the two branches holds" "one line says which" \
  "says in one line which"

# And nobody else is forked in its place. A general-purpose fork holds `Bash`, `Write` and `Edit`
# with none of the two `PreToolUse` hooks `do-builder`'s own definition carries, so it could write
# the Plan, the Digest or anything under `.scratch/` that those hooks deny, and the session would
# still be holding the hashes it verified.
carries_each "the run forks no other agent in the Builder's place" \
  "never forks another agent" "forks no other agent" "never forks a second agent" \
  "no other agent is forked" "another agent in the Builder's place" \
  -- \
  "in the Builder's place" "in its place" "in the place of the Builder"

# The build still owes the Ticket its flows, degraded or not: a fallback that ran the loop and said
# nothing about them is the old step-4 gap this text exists to close (a criterion nobody flowed and
# nothing said about it). It binds to the same rule the forked Builder reads, flows.md, and to the
# Digest's own list of what needs one, so a rewrite of either is read the same way here.
carries_each "on either branch the session authors the flows itself, per flows.md's rule, for the criteria the Digest's Observable criteria section names" \
  "authors the flows itself" "also authors the flows" \
  -- \
  "[flows.md](flows.md)" \
  -- \
  "Observable criteria"

# The stop the forked Builder would take on the same gap, carried over so a degraded run cannot
# reach the Gate with a named criterion left with no flow and nothing said about it.
carries_any "a criterion the fallback names with no flow authored stops the step" \
  "stops the step" "the step stops" "stops the build" "ends the step"

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

# The production code moved to a Sonnet Implementer, and the loop's judgments (what the next
# behaviour is, whether a changeset is in scope, whether a red is the declared one) stayed here. A
# pin that drifts with that move hands those judgments to a weaker model before a comparative eval
# has said it can carry them.
check_lines "the Builder runs on opus at medium effort" 0 0 \
  "model: opus" "effort: medium"

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
  author_out="$(printf '{"tool_input": {"subagent_type": "%s", "run_in_background": false}}' "$author" |
    sh -c "$builder_agent_hook" 2>/dev/null)"
  expect "the hook lets the Builder dispatch $author to prove a behaviour" \
    bash -c '! grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$author_out"
done

# `do-implementer` writes the production code every behaviour needs, on a cheaper model than the
# Builder's (ADR 0090). A hook that denies it leaves the Builder writing that code itself, and every
# Ticket pays the Builder's model for the work the Implementer exists to take.
implementer_out="$(printf '{"tool_input": {"subagent_type": "do-implementer", "run_in_background": false}}' |
  sh -c "$builder_agent_hook" 2>/dev/null)"
expect "the hook lets the Builder dispatch do-implementer to write production code" \
  bash -c '! grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$implementer_out"

# Every agent the Builder may reach is dispatched in the foreground, since its verdict is what the
# loop's next step reads. One launched in the background returns no verdict: the Builder falls back
# to polling a side effect for it, and the background shell outlives the Stretch it ran in. The
# harness launches in the background when `run_in_background` is left out, so an absent flag is
# denied as surely as a `true` one, and the reason names the flag, the one thing the Builder has to
# change to dispatch again.
for allowed in unit-test-author e2e-test-author global-unit-test-author global-e2e-test-author do-implementer; do
  denies_background "$builder_agent_hook" "$allowed"
done

# `choice-taker` rules a Design fork and writes the Ruling into the Spec. Forked from here it would
# rule from two layers below the session, against a Spec this fork never read, and the next Ticket
# of the same feature would be free to rule the same fork the other way: two Rulings, one Spec, and
# nothing in the run comparing them. `general-purpose` is the way around every other line of this
# hook, since it holds the tools to fork anything itself. `do-builder` would fork a Builder from a
# Builder, a third layer ADR 0047 keeps out of reach. The names that only contain or extend
# `do-implementer` hold whatever tools their own definitions grant, which the Builder's guards never
# reach: `do-implementer` is admitted by its exact name and by nothing that resembles it.
for forbidden in choice-taker general-purpose do-builder do-implementer-x implementer x-do-implementer; do
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
  source_out="$(printf '{"tool_input": {"file_path": "%s"}, "cwd": "%s"}' \
    "/home/dev/proj/.claude/worktrees/do-export/src/export/notes.ts" "/home/dev/proj/.claude/worktrees/do-export" |
    sh -c "$tool_hook" 2>/dev/null)"
  expect "the hook lets the Builder's $tool through at the source path a behaviour changes" \
    bash -c '! grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$source_out"
done

# The same guard read against a symlinked alias: the case match above runs on the raw file_path
# string, and a Ticket, Digest or Plan may carry a stranger's text directing the Builder to create
# an ordinary-looking alias under its own worktree (Write is allowed to create one, since its own
# path names no protected pattern) that resolves to the session's .scratch/ or to a *.plan.md /
# *.digest.md file. A guard that never resolves the path before matching lets that write land on
# the real protected file.
stmp="$(mktemp -d)"
trap 'cd /; rm -rf "$btmp" "$stmp"' EXIT
mkdir -p "$stmp/worktree/tests/fixtures" "$stmp/protected/.scratch/20260921-feature/issues"
printf 'plan\n' >"$stmp/protected/plan.plan.md"
printf 'digest\n' >"$stmp/protected/digest.digest.md"
printf 'build it\n' >"$stmp/protected/.scratch/20260921-feature/issues/07-build-it.md"

# A symlinked directory component: the alias resolves straight into the issues directory, so the
# unresolved string fed to the hook carries no literal ".scratch" anywhere, only the resolved
# target does.
ln -s "$stmp/protected/.scratch/20260921-feature/issues" "$stmp/worktree/tests/fixtures/data"
for tool in Write Edit; do
  case "$tool" in
    Write) tool_hook="$builder_write_hook" ;;
    *) tool_hook="$builder_edit_hook" ;;
  esac
  alias_path="$stmp/worktree/tests/fixtures/data/07-build-it.md"
  alias_out="$(cd "$stmp/worktree" &&
    printf '{"tool_input": {"file_path": "%s"}}' "$alias_path" |
    sh -c "$tool_hook" 2>/dev/null)"
  expect "the hook denies the Builder's $tool through a symlinked directory resolving into .scratch/" \
    bash -c 'grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$alias_out"
done

# A symlinked file directly naming the protected suffix through its target, not its own name.
ln -s "$stmp/protected/plan.plan.md" "$stmp/worktree/plan-alias.md"
ln -s "$stmp/protected/digest.digest.md" "$stmp/worktree/digest-alias.md"
for tool in Write Edit; do
  case "$tool" in
    Write) tool_hook="$builder_write_hook" ;;
    *) tool_hook="$builder_edit_hook" ;;
  esac
  for alias_file in plan-alias.md digest-alias.md; do
    file_alias_out="$(cd "$stmp/worktree" &&
      printf '{"tool_input": {"file_path": "%s/worktree/%s"}}' "$stmp" "$alias_file" |
      sh -c "$tool_hook" 2>/dev/null)"
    expect "the hook denies the Builder's $tool through $alias_file, a symlink resolving to a protected suffix" \
      bash -c 'grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$file_alias_out"
  done
done

# A feature that spans repositories puts a second checkout beside the Home one, and the run's branch,
# diff, Review and landing all belong to the run worktree alone: a write the Builder lands in the
# sibling repository sits on no branch and in no diff, so nothing downstream ever reads it. The
# sibling path names none of the artifact patterns above, so a deny here can only come from where
# the file sits. The payload carries the `cwd` the harness sends with every PreToolUse call, and the
# same `cwd` with a source file under the run worktree stays allowed, so the deny is never a blanket
# one over every absolute path.
mkdir -p "$stmp/repos/home" "$stmp/repos/sibling/src/export"
repos="$(cd "$stmp/repos" && pwd -P)"
g -C "$repos/home" init -q
g -C "$repos/home" commit -q --allow-empty -m fixture
g -C "$repos/sibling" init -q
run_worktree="$(branch_worktree "$repos/home" export)"
mkdir -p "$run_worktree/src/export"
printf 'export const notes = 1\n' >"$repos/sibling/src/export/notes.ts"
printf 'export const notes = 1\n' >"$run_worktree/src/export/notes.ts"
for tool in Write Edit; do
  case "$tool" in
    Write) tool_hook="$builder_write_hook" ;;
    *) tool_hook="$builder_edit_hook" ;;
  esac
  sibling_out="$(cd "$run_worktree" &&
    printf '{"tool_input": {"file_path": "%s"}, "cwd": "%s"}' "$repos/sibling/src/export/notes.ts" "$run_worktree" |
    sh -c "$tool_hook" 2>/dev/null)"
  expect "the hook denies the Builder's $tool to an absolute path inside a sibling repository, outside its worktree" \
    bash -c 'grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$sibling_out"
  own_tree_out="$(cd "$run_worktree" &&
    printf '{"tool_input": {"file_path": "%s"}, "cwd": "%s"}' "$run_worktree/src/export/notes.ts" "$run_worktree" |
    sh -c "$tool_hook" 2>/dev/null)"
  expect "the hook lets the Builder's $tool through at an absolute source path inside its own run worktree" \
    bash -c '! grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$own_tree_out"
done

# The reason is all the Builder reads of that deny, and one that says only where the path resolves
# reads as an obstacle to route around: the same file reached through the shell, or through a path
# spelled another way. The Bash guard's reason for a path outside the worktree already says the two
# things that make a deny final, whose place it is and where the finding goes instead, and the write
# guard's reason is held to the same two. The rest of the Bash reason is about shell commands, so the
# two strings are never compared whole.
for tool in Write Edit; do
  case "$tool" in
    Write) tool_hook="$builder_write_hook" ;;
    *) tool_hook="$builder_edit_hook" ;;
  esac
  sibling_reason="$(cd "$run_worktree" &&
    printf '{"tool_input": {"file_path": "%s"}, "cwd": "%s"}' "$repos/sibling/src/export/notes.ts" "$run_worktree" |
    sh -c "$tool_hook" 2>/dev/null | jq -r '.. | .permissionDecisionReason? // empty' 2>/dev/null)"
  expect "the hook's reason for the Builder's denied $tool in a sibling repository says the place belongs to the session and the developer, and to report it on the return line" \
    bash -c 'grep -qE "belongs? to the session and the developer" <<<"$1" && grep -qiE "report.*return line" <<<"$1"' _ "$sibling_reason"
done

# The worktree rule above reads the run worktree off a `cwd` inside `.claude/worktrees/<name>`, and
# do always forks the Builder there. A payload with no `cwd`, or one in the main checkout, leaves the
# rule nothing to apply, and a guard that let the write through there would let the fork write
# anywhere on disk. The path names no protected artifact, so a deny can only come from the `cwd`.
for tool in Write Edit; do
  case "$tool" in
    Write) tool_hook="$builder_write_hook" ;;
    *) tool_hook="$builder_edit_hook" ;;
  esac
  for off_worktree_payload in \
    '{"cwd": "/home/dev/proj", "tool_input": {"file_path": "/home/dev/proj/src/export/notes.ts"}}' \
    '{"tool_input": {"file_path": "/home/dev/proj/src/export/notes.ts"}}'; do
    off_worktree_out="$(printf '%s' "$off_worktree_payload" | sh -c "$tool_hook" 2>/dev/null)"
    expect "the hook denies the Builder's $tool a source path when cwd is not a run worktree: $off_worktree_payload" \
      bash -c 'grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$off_worktree_out"
  done
done

# A run worktree can sit inside another run's worktree, and the Builder's own is the innermost one
# around its `cwd`: the outer worktree is another run's branch, so a write there lands outside this
# Builder's diff exactly as a sibling repository's does.
nested_outer="/home/dev/proj/.claude/worktrees/t1"
nested_inner="$nested_outer/.claude/worktrees/t2"
for tool in Write Edit; do
  case "$tool" in
    Write) tool_hook="$builder_write_hook" ;;
    *) tool_hook="$builder_edit_hook" ;;
  esac
  outer_out="$(printf '{"cwd": "%s", "tool_input": {"file_path": "%s"}}' "$nested_inner" "$nested_outer/README.md" |
    sh -c "$tool_hook" 2>/dev/null)"
  expect "the hook denies the Builder's $tool a path in the outer worktree when cwd sits in a run worktree nested inside it" \
    bash -c 'grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$outer_out"
  inner_out="$(printf '{"cwd": "%s", "tool_input": {"file_path": "%s"}}' "$nested_inner" "$nested_inner/src/export/notes.ts" |
    sh -c "$tool_hook" 2>/dev/null)"
  expect "the hook lets the Builder's $tool through at a source path in the innermost run worktree around its cwd" \
    bash -c '! grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$inner_out"
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

echo "# skills/do/agents/do-builder.md: a Bash-matcher PreToolUse hook scopes the building agent's shell the same way"

# The Builder's Bash tool runs the build loop's tests and commits, and it is the same shell that
# could rewrite the Plan, the Digest or anything under .scratch/ with a redirect ("printf x >
# <ticket>.plan.md"), which the Write|Edit guard above denies for the Write and Edit tools alone.
# The Plan was verified by hash before the fork started and the Digest is what that hash was
# computed over, so a Bash write here rewrites the grounding the door already vouched for with the
# session none the wiser: a stranger's text reaches this fork through the Ticket, the Digest and
# the Plan's Criteria, and a shell command is the one route the Write|Edit guard never covers.
builder_bash_hook="$(hook_command "$agent" Bash)"
expect "a PreToolUse hook scopes the building agent's Bash" test -n "$builder_bash_hook"
worktree_path="/home/dev/proj/.claude/worktrees/do-export"

for artifact in ".scratch/features/02-export/02-export.md" \
  "/home/dev/proj/.claude/worktrees/do-export/.scratch/probes/build.log" \
  "docs/02-export.plan.md" "src/export/02-export.digest.md"; do
  bash_artifact_out="$(printf '{"cwd": "%s", "tool_input": {"command": "printf x > %s"}}' "$worktree_path" "$artifact" |
    sh -c "$builder_bash_hook" 2>/dev/null)"
  expect "the hook denies the Builder's Bash writing $artifact, an artifact the session owns" \
    bash -c 'grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$bash_artifact_out"
done

# The literal-substring gate above matches "printf x > .scratch/..." directly, but a stranger's
# text reaching the Builder's Bash tool through the Ticket, the Digest or the Plan's Criteria is
# never obliged to spell the write that way: a `cd` into .scratch/ before the redirect, or a path
# built from a shell variable that only assembles into ".scratch" at run time, reaches the same
# artifact while a gate keyed on the literal substring ".scratch/" never sees it.
bash_cd_cmd="cd \"$worktree_path/.scratch\" && printf 'pwned' > 20260921-feature/issues/07-build-it.md"
bash_cd_cmd_json="$(printf '%s' "$bash_cd_cmd" | sed 's/"/\\"/g')"
bash_cd_out="$(printf '{"cwd": "%s", "tool_input": {"command": "%s"}}' "$worktree_path" "$bash_cd_cmd_json" |
  sh -c "$builder_bash_hook" 2>/dev/null)"
expect "the hook denies the Builder's Bash reaching .scratch/ through a cd prefix" \
  bash -c 'grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$bash_cd_out"

bash_quote_split_cmd="d=.scr''atch; printf 'pwned' > \"$worktree_path/\$d/20260921-feature/issues/07-build-it.md\""
bash_quote_split_cmd_json="$(printf '%s' "$bash_quote_split_cmd" | sed 's/"/\\"/g')"
bash_quote_split_out="$(printf '{"cwd": "%s", "tool_input": {"command": "%s"}}' "$worktree_path" "$bash_quote_split_cmd_json" |
  sh -c "$builder_bash_hook" 2>/dev/null)"
expect "the hook denies the Builder's Bash reaching .scratch/ through a quote-split path segment" \
  bash -c 'grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$bash_quote_split_out"

# The second thing this guard stands over is the review marker's token store, and it is not an
# artifact the fork writes: it is a value the fork can mint. `scripts/review-token.sh new <slug>`
# mints a token nothing can guess and stores it under the clone's git common dir, and
# `resume-state.sh` honours a `<Ticket>.review.marker` holding that value by routing `verdict=land`
# straight to the fix call and the landing, with no second review. Writing the marker itself is
# denied by the `.scratch` gate above and by the Write|Edit guard, so a mint alone forges nothing
# today, but both of those are text and path matchers doing a best effort: a fork that can still
# mint turns any single miss of theirs into a landed, unreviewed branch. `revoke` is the same door
# from the other side, stripping the token a legitimate review stored and forcing the next run back
# through a review it had already paid for. The session mints at the review step and revokes at the
# build step, so the Builder has a call on neither mode, however the command is spelled: a `cd`
# into the script's folder leaves only the bare name behind, and a quote-split spelling leaves the
# name itself in pieces, the two evasions this guard's normaliser already exists for.
for token_cmd in \
  "bash skills/do/scripts/review-token.sh new 20260921-feature-07-build-it" \
  "bash skills/do/scripts/review-token.sh revoke 20260921-feature-07-build-it" \
  "cd skills/do/scripts && ./review-token.sh new 20260921-feature-07-build-it" \
  "bash skills/do/scripts/review-'token'.sh new 20260921-feature-07-build-it"; do
  token_cmd_json="$(printf '%s' "$token_cmd" | sed 's/"/\\"/g')"
  token_out="$(printf '{"cwd": "%s", "tool_input": {"command": "%s"}}' "$worktree_path" "$token_cmd_json" |
    sh -c "$builder_bash_hook" 2>/dev/null)"
  expect "the hook denies the Builder's Bash minting or revoking a review token: $token_cmd" \
    bash -c 'grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$token_out"
done

# Integration, landing, push and every branch but the Builder's own belong to the session. The
# Builder reads Spec text a stranger can append to, so a shell in its run worktree that can push,
# rebase, switch, merge, fetch into main, move a ref or open another worktree lands unreviewed code.
# The payload carries the `cwd` the harness sends with every PreToolUse call.
for landing_cmd in \
  "git push --force origin main" \
  "git rebase main" \
  "git switch main" \
  "git checkout main" \
  "git merge do/export" \
  "git pull" \
  "git fetch . HEAD:main" \
  "git -c core.x=y push origin HEAD:main" \
  "git branch -f main HEAD" \
  "git update-ref refs/heads/main HEAD" \
  "git worktree add ../x"; do
  landing_out="$(printf '{"cwd": "%s", "tool_input": {"command": "%s"}}' "$worktree_path" "$landing_cmd" |
    sh -c "$builder_bash_hook" 2>/dev/null)"
  expect "the hook denies the Builder's Bash a landing-shaped git command from its run worktree: $landing_cmd" \
    bash -c 'grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$landing_out"
done

# The main checkout is the session's: the developer's uncommitted work, the Spec, the Ticket and
# every other run's worktree. do cuts each run worktree at `<main checkout>/.claude/worktrees/do-<slug>`,
# so the checkout is known from the `cwd`, and a Builder shell that names it or a path under it
# outside its own worktree lets injected Spec text commit to, forge or delete work off its branch.
for outside_cmd in \
  "git -C /home/dev/proj commit -am wip" \
  "rm -rf /home/dev/proj/docs" \
  "git --git-dir=/home/dev/proj/.git commit -am wip" \
  "printf x > /home/dev/proj/.claude/worktrees/do-other/notes.md"; do
  outside_out="$(printf '{"cwd": "%s", "tool_input": {"command": "%s"}}' "$worktree_path" "$outside_cmd" |
    sh -c "$builder_bash_hook" 2>/dev/null)"
  expect "the hook denies the Builder's Bash a command that names the main checkout outside its run worktree: $outside_cmd" \
    bash -c 'grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$outside_out"
done

# The same targets spelled relative to the worktree: a `..` that climbs out of it reaches the main
# checkout or another run's worktree as surely as the absolute path the loop above denies.
for climb_cmd in \
  "cd ../../.. && git commit -am wip" \
  "rm -rf ../../../docs" \
  "git -C ../do-other commit -am wip"; do
  climb_out="$(printf '{"cwd": "%s", "tool_input": {"command": "%s"}}' "$worktree_path" "$climb_cmd" |
    sh -c "$builder_bash_hook" 2>/dev/null)"
  expect "the hook denies the Builder's Bash a command that climbs out of its run worktree with a relative path: $climb_cmd" \
    bash -c 'grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$climb_out"
done

# A sibling repository sits beside the main checkout, so neither rule above reaches it: the write
# guard denies it by where the file sits, and the shell has to do the same, since a redirect, an
# in-place `sed` or a `git commit` aimed at a sibling by its absolute path lands a change on no
# branch, in no diff and under no Review. The deny follows the path into a git repository, found by
# walking up from the path to the nearest directory that exists, so a file the command is about to
# create is caught as well; `/tmp`, `/usr` and paths inside the run worktree sit in no other
# repository and keep passing.
mkdir -p "$stmp/outside"
for sibling_cmd in \
  "printf 'two\n' > $repos/sibling/src/export/notes.ts" \
  "sed -i s/one/two/ $repos/sibling/src/export/notes.ts" \
  "printf two > $repos/sibling/src/export/created.ts" \
  "cd $repos/sibling && git commit -am x" \
  "git -C $repos/sibling commit -am x"; do
  sibling_bash_out="$(jq -n --arg c "$sibling_cmd" --arg w "$run_worktree" '{cwd: $w, tool_input: {command: $c}}' |
    sh -c "$builder_bash_hook" 2>/dev/null)"
  expect "the hook denies the Builder's Bash a command naming an absolute path inside a sibling repository: $sibling_cmd" \
    bash -c 'grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$sibling_bash_out"
done
for outside_ok_cmd in \
  "printf x > $stmp/outside/out.log" \
  "printf x > /tmp/builder-out.log" \
  "ls /usr/bin" \
  "printf x > $run_worktree/src/export/created.ts"; do
  outside_ok_out="$(jq -n --arg c "$outside_ok_cmd" --arg w "$run_worktree" '{cwd: $w, tool_input: {command: $c}}' |
    sh -c "$builder_bash_hook" 2>/dev/null)"
  expect "the hook lets the Builder's Bash through on an absolute path in no other repository: $outside_ok_cmd" \
    bash -c '! grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$outside_ok_out"
done

# Both rules above read the main checkout off a `cwd` inside `.claude/worktrees/<name>`, and do
# always forks the Builder there. A shell anywhere else, or a payload with no `cwd`, leaves them
# nothing to apply, so the guard fails closed there as it does when jq is absent.
for off_worktree_payload in \
  '{"cwd": "/home/dev/proj", "tool_input": {"command": "npm test src/export/notes.ts"}}' \
  '{"tool_input": {"command": "npm test src/export/notes.ts"}}'; do
  off_worktree_out="$(printf '%s' "$off_worktree_payload" | sh -c "$builder_bash_hook" 2>/dev/null)"
  expect "the hook denies the Builder's Bash a build-loop command when cwd is not a run worktree: $off_worktree_payload" \
    bash -c 'grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$off_worktree_out"
done

# The same nesting the Write|Edit guard reads: the Builder's worktree is the innermost one around
# its `cwd`, so the outer worktree is another run's branch, and a shell command that reads, writes or
# runs a path there reaches outside this Builder's diff.
outer_bash_out="$(jq -n --arg c "cat $nested_outer/README.md" --arg w "$nested_inner" '{cwd: $w, tool_input: {command: $c}}' |
  sh -c "$builder_bash_hook" 2>/dev/null)"
expect "the hook denies the Builder's Bash a command naming a path in the outer worktree when cwd sits in a run worktree nested inside it" \
  bash -c 'grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$outer_bash_out"
inner_bash_out="$(jq -n --arg c "cat $nested_inner/src/export/notes.ts" --arg w "$nested_inner" '{cwd: $w, tool_input: {command: $c}}' |
  sh -c "$builder_bash_hook" 2>/dev/null)"
expect "the hook lets the Builder's Bash through on a command naming a path in the innermost run worktree around its cwd" \
  bash -c '! grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$inner_bash_out"

# The other half: a Bash command that runs a test or a build step against the source the Ticket's
# behaviours change is what the loop exists to run, and a guard that denied it would leave the
# Builder unable to turn any test green, which is the same dead loop as a missing Bash tool.
bash_source_out="$(printf '{"cwd": "%s", "tool_input": {"command": "%s"}}' "$worktree_path" "npm test src/export/notes.ts" |
  sh -c "$builder_bash_hook" 2>/dev/null)"
expect "the hook lets the Builder's Bash through on a command that targets none of those paths" \
  bash -c '! grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$bash_source_out"

# The two other commands every cycle of the loop runs, which a gate drawn wide enough to catch the
# token store would take with it: this project's own unit scripts, and the commit that closes a
# green cycle, whose message names the behaviour it proved. A guard that denied either leaves the
# Builder unable to finish a single cycle, the same dead loop again.
for loop_cmd in \
  "bash skills/do/tests/builder.sh" \
  "git commit -m 'feat(export): render a note body' -m 'Behaviour: the export renders a note body'"; do
  loop_cmd_json="$(printf '%s' "$loop_cmd" | sed 's/"/\\"/g')"
  loop_out="$(printf '{"cwd": "%s", "tool_input": {"command": "%s"}}' "$worktree_path" "$loop_cmd_json" |
    sh -c "$builder_bash_hook" 2>/dev/null)"
  expect "the hook lets the Builder's Bash through on a command the build loop runs: $loop_cmd" \
    bash -c '! grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$loop_out"
done

# The run worktree sits under the main checkout, so a landing, main-checkout or `..` rule drawn one
# component too wide takes the loop's own commands with it: an absolute path into the worktree, the
# add and commit that close a cycle, a `main..HEAD` range, and a shell in a subdirectory.
for own_case in \
  "$worktree_path|bash $worktree_path/skills/do/tests/builder.sh" \
  "$worktree_path|git add src/export/notes.ts && git commit -m wip" \
  "$worktree_path|git log --oneline main..HEAD" \
  "$worktree_path/src|git status --short"; do
  own_cwd="${own_case%%|*}" own_cmd="${own_case#*|}"
  own_out="$(printf '{"cwd": "%s", "tool_input": {"command": "%s"}}' "$own_cwd" "$own_cmd" |
    sh -c "$builder_bash_hook" 2>/dev/null)"
  expect "the hook lets the Builder's Bash through on a build-loop command inside its own run worktree (cwd $own_cwd): $own_cmd" \
    bash -c '! grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$own_out"
done

# A machine with no jq: the same fail-closed guarantee the Write|Edit guard above already holds.
bash_blind_rc=0
bash_blind_out="$(printf '{"cwd": "%s", "tool_input": {"command": "%s"}}' "$worktree_path" "npm test src/export/notes.ts" |
  PATH="$no_jq_dir" sh -c "$builder_bash_hook" 2>"$no_jq_dir/.err")" || bash_blind_rc=$?
bash_blind_err="$(cat "$no_jq_dir/.err" 2>/dev/null)"
expect "the hook on the Builder's Bash fails closed when jq is absent from PATH, instead of exiting 0 silently" \
  bash -c '{ [ "$1" -ne 0 ] && [ -n "$2" ]; } || grep -qF "\"permissionDecision\": \"deny\"" <<<"$3"' \
  _ "$bash_blind_rc" "$bash_blind_err" "$bash_blind_out"

# A machine with no `tr`: the guard normalises the command through `tr` before matching it, so on
# that machine the substitution yields an empty string, the `case` matches nothing and the plainest
# write of all, a redirect straight at an artifact, comes back allow. The obfuscated spellings above
# are the reason the normaliser exists, but it is the unobfuscated write that this asks for: a guard
# blinded by a missing tool has to fail closed the same way the jq-absent path does, or every write
# to the session's artifacts is permitted there with nothing saying so.
no_tr_dir="$(path_without tr)"
bash_no_tr_rc=0
bash_no_tr_out="$(printf '{"cwd": "%s", "tool_input": {"command": "%s"}}' "$worktree_path" "printf x > .scratch/features/02-export/02-export.md" |
  PATH="$no_tr_dir" sh -c "$builder_bash_hook" 2>"$no_tr_dir/.err")" || bash_no_tr_rc=$?
bash_no_tr_err="$(cat "$no_tr_dir/.err" 2>/dev/null)"
expect "the hook on the Builder's Bash still denies a write to a session artifact when tr is absent from PATH" \
  bash -c '{ [ "$1" -ne 0 ] && [ -n "$2" ]; } || grep -qF "\"permissionDecision\": \"deny\"" <<<"$3"' \
  _ "$bash_no_tr_rc" "$bash_no_tr_err" "$bash_no_tr_out"
rm -rf "$no_tr_dir"

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
# the door resolved, and where the project map lives. A key that is not here is a
# fork guessing, or opening the session's own artifacts to guess from.
flat="$(blocks_of "$contract" "## The brief")"
carries "the brief fixes every key the fork cannot find for itself" \
  "Ticket:" "Criteria:" "Digest:" "Plan:" "Rulings:" "Repository root:" "Tree:" "Branch:" \
  "Loop:" "Project map:"

# Written here and nowhere else. A key list copied into a second file drifts from the brief the fork
# is actually handed: the session fills the copy, the fork reads the original, and a key that moved
# in one of them is a Builder dispatched without it, which is the reason plan.md already owns the
# Planner's keys alone. A key line is what the brief's own block writes, `<key>: <...>`, so a
# sentence naming one key in prose is not a copy of the list.
brief_keys='Ticket|Criteria|Digest|Plan|Rulings|Repository root|Tree|Branch|Loop|Project map'
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

# The brief's own prose, not the key block: a re-fork after a Ruling hands the Builder that meets
# the same Design fork again the settled side, and it can only read that off `Rulings:` if the
# session filled it again. A paragraph that says the brief is identical on every re-fork with no
# named exception leaves a session filling it strictly from this file (the rule right above, "The
# keys are written here and in no second place") free to leave a stale `Rulings:` on the re-fork,
# so the re-forked Builder meets the same fork again and ticket.md's blocked-run rule fires on a
# fork already settled.
flat="$(flat_section "$contract" "## The brief")"
carries_each "the brief's prose names \`Rulings:\` as the one key that changes on a re-fork after a Ruling" \
  "\`Rulings:\`" \
  -- \
  "one exception" "with one exception" "the one exception" \
  "changes on a re-fork" "differs on a re-fork" "fills again" "fills it again"

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

echo "# skills/do/references/run-report.md: the \`flow:\` lines the fork returns have a home in the Run list"

# Where a returned `flow:` line lands. The return above fixes it as one of the lines that cross
# back, and ADR 0039 makes the Reply the one place a line reaches the developer: a line with no
# numbered home in this list is a line the run reads off the return and drops on the floor. The
# home is found by what it says, not by its number, so folding it into the Build lines and giving
# it an entry of its own both count, the way gated-once.sh and reapply-step.sh find their items;
# `passage_of` keeps the search inside `## Run`, since the `## Sections` list names the flows too,
# under Evidence, and a Run line the developer never gets is not answered by an evidence line.
flow_item="$(item_holding <(passage_of "$run_report" "## Run" "## Sections") '[0-9]+\.' "flow")"
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

echo "# skills/do/references/ticket.md, skills/do/references/run-report.md: the Builder's \`fallback:\` lines reach the Reply, naming why no Implementer was dispatched"

# A Builder that wrote the code itself, because `do-implementer` is not linked or its dispatch was
# refused, says so on a `fallback:` line of its return. A session that routes `built` off the
# `behaviour:`, `build:` and `flow:` lines alone drops that line, and the developer reads a Reply in
# which the Implementers wrote the code: the run's cost and ADR 0090's eval are then read against a
# shape the run never had. The route copies the line as returned, the way it copies the others.
# The `built` bullet is scoped from the route's own opening line, so a `built` elsewhere in the
# Playbook never answers for it.
flat="$(bullets_opening_on <(passage_of "$playbook" "Route on the first line:" "## ") "\`built\`:" | head -n 1)"
expect "the Playbook routes the Builder's \`built\` return" test -n "$flat"
carries_each "the \`built\` route copies the returned \`fallback:\` lines into the Run report unchanged" \
  "\`fallback:\`" "fallback:" -- "Reply" "Run section" "Run report" -- \
  "unchanged" "verbatim" "never composed" "as returned" "as the Builder returned"

# The Run list is where the copied line lands. Its home is found by the Implementer it speaks of,
# not by its number, so folding it into the Build lines and giving it an item of its own both count;
# the Planner's fallbacks in the Plan line carry no Implementer and never answer for it.
implementer_item="$(item_holding <(passage_of "$run_report" "## Run" "## Sections") '[0-9]+\.' "mplementer")"
expect "the Run list carries a home for the Builder's lines on the Implementer" test -n "$implementer_item"
flat="$(tr '\n' ' ' <<<"$implementer_item" | tr -s ' ')"
carries_each "the home takes the Builder's \`fallback:\` lines with the reason no Implementer was dispatched" \
  "fallback:" "fallback\` line" "fallback line" -- \
  "Builder" "the build returned" "the fork returned" -- \
  "not linked" "isn't linked" "is unlinked" "not installed" "no \`do-implementer\`" -- \
  "dispatch is refused" "dispatch refused" "refuses the dispatch" "refused dispatch" "is refused" \
  "was refused" "is denied" "denies the dispatch" "dispatch denied"

echo "# skills/do/references/ticket.md, run-report.md, builder.md: the Builder's \`fallback:\` and refused-changeset lines land in the Run report"

# ADR 0091: Build lines sit under run-report.md's `## Run`, never part of the five-part message, and a
# run without `--auto` writes no Run report. A passage that sends the `fallback:` line or a refused
# changeset's build line to "the Reply" has the session write it into the message, where reply.md
# forbids it, or nowhere. The `built` bullet's opening clause already names the Run report for the
# Build lines in general, so the check is scoped to the clause that says what a `fallback:` line
# tells the developer (the Builder wrote the code itself, no Implementer was dispatched).
flat="$(bullets_opening_on <(passage_of "$playbook" "Route on the first line:" "## ") "\`built\`:" | head -n 1 |
  sed 's/: /:\n/g; s/; /;\n/g; s/\. /.\n/g' | grep -F "fallback:" | grep -E "itself|Implementer" | tr '\n' ' ')"
expect "the \`built\` route has a clause saying what the \`fallback:\` line tells the developer" test -n "$flat"
carries_each "the \`built\` route's \`fallback:\` clause names the Run report as where the line lands" "Run report"

build_item="$(item_holding <(passage_of "$run_report" "## Run" "## Sections") '[0-9]+\.' "Build lines")"
flat="$(bullets_opening_on <(printf '%s\n' "$build_item") "\`fallback:\`" | head -n 1)"
expect "the Run list's Build lines carry the Builder's \`fallback:\` lines" test -n "$flat"
carries_each "the Build lines' \`fallback:\` sentence names the Run report as where the line lands" "Run report"

flat="$(bullets_opening_on "$contract" "Each changeset the check refused" | head -n 1)"
expect "the contract says where a refused changeset shows" test -n "$flat"
carries_each "a refused changeset's build line is shown in the Run report" "Run report"

flat="$(bullets_opening_on "$contract" "An edit the Builder wrote itself" | head -n 1)"
expect "the contract says where an edit the Builder wrote itself shows" test -n "$flat"
carries_each "an edit the Builder wrote itself is told apart in the Run report" "Run report"

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

echo "# skills/do/agents/do-builder.md, skills/do/references/builder.md, skills/do/references/build-loop.md: the Builder dispatches the Implementer at every production edit"

# The Builder runs on Opus, and every production edit it still writes itself is paid at that rate
# by the developer running `/do`. The Implementer exists to take those edits at a cheaper model, and
# there are four of them in a cycle: the green, the seam a `BLOCKED` asks for, the fix a `HANDBACK`
# diagnosed as `production` asks for, and the refactor. Any one the three readers leave to the
# Builder is an edit it goes on writing itself. The fork reads its own definition first, the
# contract fixes the call, and build-loop.md is the step the Builder is at when the edit comes up,
# so all three have to say it.
build_loop="$here/../references/build-loop.md"

# The body, never the frontmatter: the Agent hook there already names `do-implementer` to let the
# dispatch through, and an allowed dispatch is not a definition that tells the fork to make one.
body_of "$agent" >"$stmp/builder-body.md"
flat="$(paragraph_with "$stmp/builder-body.md" "do-implementer" all | tr '\n' ' ' | tr -s ' ')"
carries_each "the building agent's body has it dispatch \`do-implementer\` for its production edits" \
  "do-implementer" -- "dispatch" -- "production"

# The contract fixes the call and names each edit by the `Edit:` kind the Implementer reads off its
# brief: a kind missing here is an edit the Builder has no call for, and writes itself. Read over
# every section of the contract that names the Implementer, so the call is found wherever the
# contract puts it.
flat="$(awk '/^## / { if (keep) print sec; sec = ""; keep = 0 }
  { sec = sec " " $0; if (index($0, "do-implementer")) keep = 1 }
  END { if (keep) print sec }' "$contract" | tr -s ' ')"
carries_each "the contract has the Builder call the Agent tool with \`subagent_type: do-implementer\`" \
  "Agent tool" "\`Agent\`" -- "subagent_type" -- "do-implementer" -- "Builder"
carries_each "the contract names each of the four edits by its \`Edit:\` kind: green, seam, fix and refactor" \
  "\`green\`" "Edit: green" -- "\`seam\`" "Edit: seam" -- "\`fix\`" "Edit: fix" \
  -- "\`refactor\`" "Edit: refactor"

# build-loop.md is also read by the bug-fix and refactoring sessions, which have no Implementer and
# write the code themselves, so each step says it for a Builder by name rather than for every reader.
# Each step is found by what it is about, not by its number or its wording.
green_step="$(item_holding "$build_loop" '[0-9]+\.' "smallest production change")"
refactor_step="$(item_holding "$build_loop" '[0-9]+\.' "Refactor on green")"
seam_route="$(bullets_opening_on "$build_loop" "\`BLOCKED\`" | grep -F "seam" | head -n 1)"
production_route="$(bullets_opening_on "$build_loop" "\`production\`")"
for edit in green seam fix refactor; do
  case "$edit" in
    green) where="the green step" step="$green_step" ;;
    seam) where="the route for \`BLOCKED\` on a missing seam" step="$seam_route" ;;
    fix) where="the \`HANDBACK\` route diagnosed \`production\`" step="$production_route" ;;
    *) where="the refactor step" step="$refactor_step" ;;
  esac
  expect "build-loop.md carries $where" test -n "$step"
  flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ')"
  carries_each "build-loop.md: $where has a Builder dispatch \`do-implementer\` for that edit" \
    "Builder" -- "do-implementer" -- "dispatch"
done

echo "# skills/do/references/builder.md / ## The Implementer: the brief the Builder writes carries every key the Implementer reads"

# The Implementer never explores and never decides where to write: a brief missing what the edit
# needs comes back `OUT OF BRIEF` with nothing edited, and the cycle has paid a dispatch for no
# edit. The keys are read off the Implementer's own `## Where you start`, so the brief the Builder
# writes and the one the Implementer reads cannot drift apart.
implementer="$here/../agents/do-implementer.md"
mapfile -t implementer_keys < <(paragraph_with "$implementer" "The brief is one key per line" |
  grep -oE '`[A-Z][A-Za-z ]*:`' | tr -d '`' | awk '!seen[$0]++')
expect "do-implementer.md lists the brief keys it reads, to read them off" \
  test "${#implementer_keys[@]}" -gt 1
# shellcheck disable=SC2034  # lib.sh's check_lines reads $out
out="$(blocks_of "$contract" "## The Implementer" | sed -nE 's/^([A-Z][A-Za-z ]*:).*/\1/p')"
check_lines "the brief's block in \`## The Implementer\` opens a line on every key do-implementer.md reads" 0 0 \
  "${implementer_keys[@]}"

# A brief written from the Plan or from an earlier cycle names files and signatures the tree no
# longer has, and the Implementer stops on them.
flat="$(flat_section "$contract" "## The Implementer")"
affirms "the Builder writes the brief from the tree as it stands at that cycle" \
  "the tree" "the worktree" -- "that cycle" "this cycle" "each cycle" "every cycle" "the cycle"

# `Where:` is what spares the Implementer the exploring: its block line, and every paragraph that
# speaks of it, are read together, since the contract may say it in either.
passage_of "$contract" "## The Implementer" "## " >"$stmp/implementer-section.md"
flat="$({
  blocks_of "$contract" "## The Implementer" | grep -E '^Where:'
  paragraph_with "$stmp/implementer-section.md" '`Where:`' all
} | tr '\n' ' ' | tr -s ' ')"
carries_each "\`Where:\` names the files to edit, the symbols and signatures to create or change, and the seam when there is one" \
  "file" -- "symbol" -- "signature" -- "seam"

echo "# skills/do/agents/do-builder.md, skills/do/references/builder.md / ## The Implementer: the judgments stay the Builder's and the code goes to the Implementer"

# The Implementer runs on a cheaper model that takes its brief literally. The five judgments the
# loop turns on (whether the red is the expected one, the test author's verdict, a `HANDBACK`'s
# diagnosis, a missing seam, a Design fork) are the ones a literal model gets wrong, so both
# readers have to keep them on the Builder's side of the dispatch, in the passage that names the
# Implementer, all five by name. And the dispatch only moves the code off Opus when the Builder
# writes none of it itself. An Implementer that cannot be dispatched has its own group below.
for reader in agent contract; do
  case "$reader" in
    agent) where="do-builder.md's body" scope="$stmp/builder-body.md" ;;
    *) where="builder.md's \`## The Implementer\`" scope="$stmp/implementer-section.md" ;;
  esac
  flat="$({
    paragraph_with "$scope" "Implementer" all
    paragraph_with "$scope" "do-implementer" all
  } | awk '!seen[$0]++' | grep -F "Design fork" | tr '\n' ' ' | tr -s ' ')"
  carries_each "$where: the paragraph naming the Implementer keeps all five judgments the Builder's" \
    "expected red" "red is the expected" "declared red" "red for the reason" "red as expected" \
    -- "verdict" \
    -- "\`HANDBACK\`" "HANDBACK" -- "diagnosis" "diagnoses" \
    -- "missing seam" "seam is missing" \
    -- "Design fork" \
    -- "the Builder's" "stay with the Builder" "the Builder keeps" "Builder's own" "yours" \
    "you keep" "stay with you" "remain with you"
  flat="$(tr '\n' ' ' <"$scope" | tr -s ' ')"
  carries_any "$where: the Builder writes no production code itself" \
    "writes no production code" "write no production code" "never writes production code" \
    "never write production code" "does not write production code" "do not write production code" \
    "writes none of the production code" "write none of the production code"
done

echo "# skills/do/references/build-loop.md: the test author's dispatch input is unchanged by the Implementer's"

# The unit and E2E test authors return `REFUSED_INCOMPLETE_INPUT` on an input that lost or renamed a
# key, and every cycle the loop runs starts at that dispatch. The Implementer's brief now sits in the
# steps around it, so step 1 has to keep naming the field of every key the Testing Policy fixes, and
# carry none of the Implementer's own keys: a `Where:` or an `Edit:` handed to a test author is a
# field it does not read, in place of one it refuses without. The keys are checked on the policy's
# own block first, so a key the policy renames fails here rather than passing on stale phrasings.
policy="$here/../../../.claude/testing-policy/policy.md"
# shellcheck disable=SC2034  # lib.sh's check_lines reads $out
out="$(blocks_of "$policy" "## Test authoring: delegation and reuse" | sed -nE 's/^([A-Z][A-Za-z ()]*:).*/\1/p')"
check_lines "the Testing Policy still fixes the six dispatch input keys step 1 is read against" 0 0 \
  "Behavior to prove:" "Relied on by:" "Target:" "Origin:" "Expected red:" "Placement (optional):"

author_step="$(item_holding "$build_loop" '[0-9]+\.' "unit test author")"
expect "build-loop.md carries the step that dispatches the unit test author" test -n "$author_step"
flat="$(tr '\n' ' ' <<<"$author_step" | tr -s ' ')"
carries_each "build-loop.md: the test author's dispatch step names the field of every key the policy fixes" \
  "behaviour to prove" "behavior to prove" "Behavior to prove:" \
  -- "who relies on it" "Relied on by:" \
  -- "what a wrong or missing result costs" "a wrong or missing result costs" \
  -- "the target" "Target:" \
  -- "the origin" "Origin:" \
  -- "\`new feature\`" -- "\`bugfix\`" \
  -- "the expected red" "Expected red:" \
  -- "placement" "Placement"
# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$author_step"
check_absent "build-loop.md: the test author's dispatch step carries none of the Implementer's keys" 0 0 \
  "Worktree:" "Edit:" "Ask:" "Where:" "Ruled out:" "do-implementer"

echo "# skills/do/references/builder.md / ## The Implementer, skills/do/agents/do-builder.md: the changeset check runs after each Implementer return, before the commit"

# The Implementer edits production code from a brief it takes literally, and nothing in its edit
# stops it touching the test the behaviour is proven by. A change that moved that test, landed by
# the Builder's commit, reaches the session and the review as a behaviour proven green when the
# proof itself was rewritten. The snapshot is the baseline the check reads the changeset against,
# so it has to be taken before the dispatch it covers, and the check has to run before the commit
# that would land the change, against the paths the test author named. The order is read off the
# two command blocks: the Implementer sits between them, and the commit after the second.
flat="$(flat_section "$contract" "## The Implementer")"
snapshot_cmd="$(blocks_of "$contract" "## The Implementer" | grep -E '^bash .*main-untouched\.sh"? +snapshot' | head -n 1)"
changeset_cmd="$(blocks_of "$contract" "## The Implementer" | grep -E '^bash .*changeset-check\.sh' | head -n 1)"
expect "builder.md's \`## The Implementer\` names the snapshot as a runnable \`bash\` line" test -n "$snapshot_cmd"
expect "builder.md's \`## The Implementer\` names the changeset check as a runnable \`bash\` line" test -n "$changeset_cmd"
after_snapshot="${flat#*"$snapshot_cmd"}"
expect "builder.md: the changeset check comes after the snapshot" \
  bash -c '[ -n "$1" ] && [ -n "$2" ] && [ "$3" != "$4" ] && grep -qF -- "$2" <<<"$3"' _ \
  "$snapshot_cmd" "$changeset_cmd" "$after_snapshot" "$flat"
# With either command missing the slices below would be the whole section, and pass on it.
flat=""
[ -n "$snapshot_cmd" ] && [ -n "$changeset_cmd" ] && flat="${after_snapshot%%"$changeset_cmd"*}"
carries_any "builder.md: the Implementer is dispatched between the snapshot and the changeset check" \
  "do-implementer" "Implementer"
flat=""
[ -n "$snapshot_cmd" ] && [ -n "$changeset_cmd" ] && flat="${after_snapshot#*"$changeset_cmd"}"
carries_any "builder.md: the commit comes after the changeset check" "commit"
flat="$(flat_section "$contract" "## The Implementer")"
carries_each "builder.md: the changeset check is handed the test author's named paths" \
  "Test changeset" -- "Promotion changeset"

flat="$(body_of "$agent" | awk 'BEGIN { RS = "" } /changeset-check\.sh|changeset check/' | tr '\n' ' ' | tr -s ' ')"
changeset_at="$(first_at "changeset-check.sh" "changeset check")"
expect "do-builder.md's body names the changeset check" test "$changeset_at" -gt 0
body_tail="${flat:changeset_at}"
flat="${flat:0:changeset_at}"
carries_any "do-builder.md: the changeset check follows the Implementer's return" "Implementer" "do-implementer"
flat="$body_tail"
carries_any "do-builder.md: the changeset check comes before the commit" "commit"

# Both commands run in the worktree of whatever project is being built, from the Builder's own Bash,
# under the guard its frontmatter carries. Each placeholder is filled the way the Builder fills it:
# the run worktree, a state file outside it, and a named path from its root. The commands then run
# from a project that does not hold the skill, with the skill linked under a throwaway HOME.
changeset_proj="$stmp/changeset/proj"
changeset_tree="$changeset_proj/.claude/worktrees/do-w1"
changeset_home="$stmp/changeset/home"
changeset_state="$stmp/changeset/state"
changeset_digest=0
mkdir -p "$changeset_tree" "$changeset_home/.claude/skills"
ln -s "$here/.." "$changeset_home/.claude/skills/do"
(cd "$changeset_proj" && git init -q && cd "$changeset_tree" && git init -q && printf 'a\n' >a.txt && g add -A && g commit -qm init)
fill_placeholders() { # $1 a command line: each <placeholder> filled, on stdout
  sed -E -e 's/>\.\.\./>/g' -e "s#<[^>]*digest[^>]*>#$changeset_digest#g" -e "s#<[^>]*state[^>]*>#$changeset_state#g" \
    -e "s#<[^>]*([Tt]ree|[Ww]orktree)[^>]*>#$changeset_tree#g" -e 's#<[^>]*>#tests/a.test.sh#g' <<<"$1"
}
snapshot_run="$(fill_placeholders "$snapshot_cmd")"
changeset_run="$(fill_placeholders "$changeset_cmd")"
for run_line in "$snapshot_run" "$changeset_run"; do
  hook_out="$(jq -n --arg command "$run_line" --arg cwd "$changeset_tree" \
    '{tool_input: {command: $command}, cwd: $cwd}' | sh -c "$(hook_command "$agent" Bash)" 2>/dev/null)"
  expect "the Builder's Bash guard lets the command through from its worktree: ${run_line:-<missing>}" \
    bash -c '[ -n "$1" ] && ! grep -qF "\"permissionDecision\": \"deny\"" <<<"$2"' _ "$run_line" "$hook_out"
done

snapshot_out="$(cd "$changeset_tree" && HOME="$changeset_home" bash -c "$snapshot_run" 2>&1)"
changeset_digest="$(sed -n 's/^digest=//p' <<<"$snapshot_out")"
changeset_run="$(fill_placeholders "$changeset_cmd")"
changeset_out="$(cd "$changeset_tree" && HOME="$changeset_home" bash -c "$changeset_run" 2>&1)"
expect "the snapshot and the changeset check run from a project that does not hold the skill" \
  bash -c '[ -n "$1" ] && grep -q "^state=" <<<"$2" && grep -q "^verdict=pass" <<<"$3"' _ \
  "$snapshot_run" "$snapshot_out" "$changeset_out"

echo "# skills/do/references/builder.md / ## The Implementer, skills/do/references/build-loop.md: the Builder formats and commits each behaviour, never the Implementer"

# The resume step matches the `Behaviour:` lines on the branch one for one and rebuilds a behaviour
# whose commit it cannot find. An Implementer that committed its own edit would land a commit with
# no `Behaviour:` line, or a second one beside the Builder's, and the resume would rebuild a
# behaviour already on the branch or count one twice. The contract says it past the changeset
# check, the last thing a dispatch is put through before the commit: the brief's own `Behaviour:`
# key, earlier in the section, cannot answer for it.
flat="$(flat_section "$contract" "## The Implementer")"
pass_line="Only \`verdict=pass\` goes on toward the commit."
pass_at="$(first_at "$pass_line")"
expect "builder.md's \`## The Implementer\` carries the \`verdict=pass\` line its commit step follows" \
  test "$pass_at" -gt 0
section="$flat"
flat=""
[ "$pass_at" -gt 0 ] && flat="${section:$((pass_at - 1 + ${#pass_line}))}"
affirms "builder.md: past the changeset check, the Builder itself formats the touched files and commits the behaviour" \
  "the Builder" "itself" -- "format" -- "commit"
carries_each "builder.md: the Builder's commit carries the behaviour's \`Behaviour:\` line, one commit per behaviour" \
  "Behaviour:" \
  -- "one commit per behaviour" "one commit for each behaviour" "a commit per behaviour" \
  "each behaviour its own commit" "one commit to each behaviour" "one behaviour per commit"
carries_any "builder.md: the Implementer never commits" \
  "the Implementer never commits" "\`do-implementer\` never commits" "the Implementer commits nothing" \
  "the Implementer does not commit" "never the Implementer's" "never by the Implementer" \
  "never the Implementer" "not the Implementer's"

# bug-fix and refactoring read the same two steps and have no Implementer, so each says it for a
# Builder by name. Each step is found by what it is about, not by its number.
format_step="$(item_holding "$build_loop" '[0-9]+\.' "format the touched files")"
commit_step="$(item_holding "$build_loop" '[0-9]+\.' "\`Behaviour: <line>\`")"
for what in format commit; do
  case "$what" in
    format) where="the format step" step="$format_step" ;;
    *) where="the commit step" step="$commit_step" ;;
  esac
  expect "build-loop.md carries $where" test -n "$step"
  flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ')"
  carries_each "build-loop.md: $where keeps the $what a Builder's and never the Implementer's" \
    "Builder" \
    -- "the Builder's" "a Builder's" "Builder's own" "the Builder itself" "a Builder itself" \
    "stays with the Builder" "stay with the Builder" \
    -- "never the Implementer's" "not the Implementer's" "never by the Implementer" \
    "the Implementer never" "\`do-implementer\` never" "never \`do-implementer\`"
done

echo "# skills/do/references/builder.md / ## The Implementer, skills/do/agents/do-builder.md: a \`NOT GREEN\` return is dispatched once more, its Ruled out quoted between two tags sharing one random id"

# An Implementer that spent its budget returns `NOT GREEN` with a `Ruled out:` line, and a Builder
# that has no route for it stops the developer's run on one stuck dispatch. The route is one more
# dispatch for the same edit, carrying that line in the brief's `Ruled out:` key so the second
# Implementer does not buy the same experiment again. The line comes out of a failing test's run, a
# place a stranger's fixture or a dependency's error can write into, so it goes over between an
# opening and a closing tag that share one random id the Builder generates for that re-dispatch, the
# way build-loop.md hands a test author's Handback over: quoted text, never an order. The dispatch
# is read off the paragraphs that name `NOT GREEN`; the tags may sit there or beside the brief's
# `Ruled out:` key, so those paragraphs are read too. A refused changeset, `OUT OF BRIEF`, a second
# failure and an Implementer that cannot be dispatched are later behaviours, and nothing here pins them.
for reader in agent contract; do
  case "$reader" in
    agent) where="do-builder.md's body" scope="$stmp/builder-body.md" ;;
    *) where="builder.md's \`## The Implementer\`" scope="$stmp/implementer-section.md" ;;
  esac
  flat="$(paragraph_with "$scope" "NOT GREEN" all | tr '\n' ' ' | tr -s ' ')"
  expect "$where names the Implementer's \`NOT GREEN\` return" test -n "$flat"
  affirms "$where: on \`NOT GREEN\` the Builder dispatches the Implementer once more" \
    "do-implementer" "Implementer" -- "once more" "again" "a second time" "re-dispatch" "redispatch"
  carries_any "$where: the second dispatch is for the same edit" \
    "same edit" "that edit" "this edit" "the same brief" "same \`Edit:\`"
  flat="$({
    paragraph_with "$scope" "NOT GREEN" all
    paragraph_with "$scope" "Ruled out:" all
  } | awk '!seen[$0]++' | tr '\n' ' ' | tr -s ' ')"
  carries_each "$where: the first return's Ruled out goes into the brief's \`Ruled out:\` key" \
    "Ruled out:" -- "NOT GREEN"
  expect "$where: that Ruled out sits between an opening and a closing tag carrying the same id" \
    bash -c 'grep -qE "<([a-z][a-z-]*) id=\"([^\"]*)\">.*</\\1 id=\"\\2\">" <<<"$1"' _ "$flat"
  carries_any "$where: the id the two tags share is a random one the Builder generates for that re-dispatch" \
    "random id" "random \`id\`" "one random" "short random"
done

echo "# skills/do/references/builder.md / ## The Implementer, skills/do/agents/do-builder.md: a refused changeset is dispatched once more as a failed dispatch, the refusal quoted between two tags sharing one random id, nothing refused committed"

# The changeset check refuses an Implementer's edit that touched the test the behaviour is proven
# by (`verdict=refused`, exit 1), and a Builder with no route past it stops the developer's run
# there. The route is the failed dispatch's own: one more dispatch for the same edit, carrying the
# refusal (the offending paths the check named) in the brief's `Ruled out:` key, between an opening
# and a closing tag that share one random id, so the second Implementer keeps off those paths. The
# refused edit never reaches the commit, so the resume still finds one commit per behaviour. The
# decision is read off the paragraphs that speak of the check's refusal; a paragraph that folds it
# into the `NOT GREEN` one answers too. The build line, a second failure, `OUT OF BRIEF` and an
# Implementer that cannot be dispatched are later behaviours, and nothing here pins them.
for reader in agent contract; do
  case "$reader" in
    agent) where="do-builder.md's body" scope="$stmp/builder-body.md" ;;
    *) where="builder.md's \`## The Implementer\`" scope="$stmp/implementer-section.md" ;;
  esac
  flat="$(awk 'BEGIN { RS = "" } /refus/ && /changeset|check|verdict=/ { gsub(/\n/, " "); print }' "$scope" |
    tr '\n' ' ' | tr -s ' ')"
  expect "$where says what follows a refused changeset" test -n "$flat"
  affirms "$where: on a refused changeset the Builder dispatches the Implementer once more" \
    "do-implementer" "Implementer" -- "once more" "again" "a second time" "re-dispatch" "redispatch"
  carries_any "$where: the refusal is handled as a failed dispatch is" \
    "failed dispatch" "failed one" "a failure" "as a failure" "NOT GREEN" "as it does a" "as it is on"
  carries_any "$where: the second dispatch is for the same edit" \
    "same edit" "that edit" "this edit" "the same brief" "same \`Edit:\`"
  carries_each "$where: the refusal, the offending paths the check named, goes into the brief's \`Ruled out:\` key" \
    "Ruled out:" "\`Ruled out\`" \
    -- "offending" "the paths the check" "paths it named" "paths the check named" "paths it refused" \
    "refused paths" "the refusal" "its refusal" "what the check refused" "what it refused"
  expect "$where: that refusal sits between an opening and a closing tag carrying the same id" \
    bash -c 'grep -qE "<([a-z][a-z-]*) id=\"([^\"]*)\">.*</\\1 id=\"\\2\">" <<<"$1" ||
      grep -qE "tags? (that )?(share|sharing|carry|carrying)" <<<"$1"' _ "$flat"
  carries_any "$where: the id the two tags share is a random one the Builder generates for that re-dispatch" \
    "random id" "random \`id\`" "one random" "short random"
  carries_any "$where: nothing the check refused is committed" \
    "nothing refused is committed" "nothing it refused is committed" "nothing the check refused" \
    "is never committed" "is not committed" "never reaches the commit" "never goes on toward the commit" \
    "commits nothing" "no commit" "without a commit" "Only \`verdict=pass\` goes on toward the commit"
done

echo "# skills/do/references/builder.md / ## The Implementer, skills/do/agents/do-builder.md: a refused changeset's offending paths are put back as the first snapshot read them before the Implementer is dispatched again, so no commit carries a test file the check refused"

# The re-dispatch takes its own step 1 snapshot, so a test file the first Implementer bent and
# nobody put back is that snapshot's baseline: the second changeset check prints `verdict=pass`
# over it and the bent test is committed with the behaviour. Leaving the refused changeset out of
# the commit is not enough, the offending paths have to read as they did at the edit's first
# snapshot before the next dispatch. Read off the same paragraphs as the case above.
for reader in agent contract; do
  case "$reader" in
    agent) where="do-builder.md's body" scope="$stmp/builder-body.md" ;;
    *) where="builder.md's \`## The Implementer\`" scope="$stmp/implementer-section.md" ;;
  esac
  flat="$(awk 'BEGIN { RS = "" } /refus/ && /changeset|check|verdict=/ { gsub(/\n/, " "); print }' "$scope" |
    tr '\n' ' ' | tr -s ' ')"
  expect "$where says what follows a refused changeset" test -n "$flat"
  carries_each "$where: the offending paths the check named are put back as they read at the edit's first snapshot" \
    "puts back" "put back" "puts every" "puts each" "restore" "restoring" "resets" "reset" "reverts" \
    "reads as it did" "read as it did" "read as they did" \
    -- "offending" "the paths the check named" "paths it named" "refused paths" "every path the check" \
    "each path the check" \
    -- "first snapshot" "first dispatch's snapshot" "snapshot taken before the first" "as it read before" \
    "as they read before" "as it did before" "as they did before" "reads as it did" "read as it did" \
    "read as they did"
  carries_any "$where: the offending paths are put back before the Implementer is dispatched again" \
    "before it dispatches" "before the re-dispatch" "before re-dispatching" "before it re-dispatches" \
    "before any re-dispatch" "before that re-dispatch" "before the next dispatch" "before the second dispatch" \
    "before dispatching" "before the Implementer is dispatched" "before you dispatch" "before you re-dispatch" \
    "only then dispatches" "only then re-dispatches" "only then dispatch"
  carries_any "$where: so no commit of the behaviour carries a test file the check refused" \
    "no commit carries" "no commit of the behaviour carries" "carries no test file" "never carries a test" \
    "no refused test file" "test file the check refused" "test the check refused" "refused test file" \
    "refused test is never committed" "refused test is not committed"
done

echo "# skills/do/references/builder.md / ## The return: a refused changeset shows on that behaviour's \`build:\` line"

# The developer reads the Reply's Build lines, copied out of the return unchanged, and nothing else
# of the build: a refusal the Builder caught and routed past leaves no trace there unless the
# behaviour's `build:` line names it, and an Implementer that moved a test file passes unseen. The
# prose is read off the paragraphs of `## The return` above its examples that speak of a refusal,
# and the clause has to affirm it (`build:` splits a clause at its colon, so the line is matched by
# its opening). The examples have to carry one such line, with what was done about it, since the
# shape is what the Builder copies. A second failure, `OUT OF BRIEF` and an Implementer that cannot
# be dispatched are later behaviours, and nothing here pins them.
flat="$(passage_of "$contract" "## The return" "### Examples" |
  awk 'BEGIN { RS = "" } /refus/ { gsub(/\n/, " "); print }' | tr '\n' ' ' | tr -s ' ')"
expect "\`## The return\` says what a refused changeset leaves on the return" test -n "$flat"
affirms "\`## The return\`: a changeset the check refused is named on that behaviour's \`build:\` line" \
  "\`build" "build line" "Build line" -- "refus"
flat="$(blocks_of "$contract" "### Examples" | grep -E '^build:' | grep -F 'refus' | tr '\n' ' ' | tr -s ' ')"
expect "\`### Examples\` carries a return whose \`build:\` line names a refused changeset" test -n "$flat"
carries_any "\`### Examples\`: that \`build:\` line says the edit was dispatched once more" \
  "re-dispatched" "redispatched" "dispatched once more" "dispatched again" "once more" "again" \
  "a second time" "second dispatch"

echo "# skills/do/references/builder.md / ## The Implementer, skills/do/agents/do-builder.md, ## The return: a second failure on the same edit has the Builder write it, and the \`build:\` line says so"

# One re-dispatch is the whole route past a failed Implementer: a Builder that meets a second
# `NOT GREEN` or a second refused changeset on the same edit and has nothing written for it either
# dispatches a third time, and a fourth, or stops the developer's run on that edit. The route is the
# Builder writing that edit itself, with no third dispatch. The decision is read off the paragraphs
# that speak of a second failure (or a failure again, or twice), in both readers: the agent's body
# addresses the Builder as "you", so its subject is "you " (trailing space, since each group masks
# what it matched and a bare "you" would eat the "you" of "yourself"). The developer then
# reads on the behaviour's `build:` line that the Opus Builder wrote it rather than an Implementer,
# read off the paragraphs of `## The return` above its examples that speak of the Builder's own
# write (`build:` splits a clause at its colon, so the clause after it answers through its "` line").
# `OUT OF BRIEF` and an Implementer that cannot be dispatched are later behaviours, and nothing here
# pins them.
for reader in agent contract; do
  case "$reader" in
    agent) where="do-builder.md's body" scope="$stmp/builder-body.md" ;;
    *) where="builder.md's \`## The Implementer\`" scope="$stmp/implementer-section.md" ;;
  esac
  flat="$(awk 'BEGIN { RS = "" } /[Ss]econd|again|twice/ && /fail|NOT GREEN|refus/ { gsub(/\n/, " "); print }' "$scope" |
    tr '\n' ' ' | tr -s ' ')"
  expect "$where says what follows a second failure" test -n "$flat"
  affirms "$where: on a second failure the Builder writes the edit itself" \
    "Builder" "it writes" "it makes" "you " -- "write" "makes" "edits" "applies" -- "itself" "by hand" "its own" "yourself" "your own"
  carries_each "$where: a second failure is a second \`NOT GREEN\` or a second refused changeset" \
    "NOT GREEN" -- "refus"
  carries_any "$where: that is the edit the two dispatches failed on" \
    "same edit" "that edit" "this edit" "the edit itself"
  carries_any "$where: no third dispatch follows" \
    "no third" "never a third" "not a third" "without a third" "third dispatch" "no further dispatch" \
    "dispatches no more" "not dispatched again" "never dispatched again" "no more dispatch"
done
flat="$(passage_of "$contract" "## The return" "### Examples" |
  awk 'BEGIN { RS = "" } /itself|its own|Builder wrote|Builder writes/ && /fail|dispatch/ { gsub(/\n/, " "); print }' |
  tr '\n' ' ' | tr -s ' ')"
expect "\`## The return\` says what an edit the Builder wrote itself leaves on the return" test -n "$flat"
affirms "\`## The return\`: the behaviour's \`build:\` line names an edit the Builder wrote itself" \
  "\`build" "build line" "Build line" "\` line" -- "itself" "Builder wrote" "Builder's own" "its own"
carries_any "\`## The return\`: that edit is one written after two failed dispatches" \
  "two failed" "second failure" "second failed" "failed twice" "twice" "both dispatches" "two dispatches"

echo "# skills/do/references/builder.md / ## The Implementer, skills/do/agents/do-builder.md, ## The return: an Implementer that cannot be dispatched has the Builder write the code, and a \`fallback:\` line names why"

# A developer whose machine has no `do-implementer` linked, or whose harness refuses the dispatch,
# would see the run stop on a missing agent unless the Builder has a route past it: writing the
# production code itself, as the loop did before the Implementer, and going on. The decision is read
# off the paragraphs that speak of the Implementer being unlinked or undispatchable, in both
# readers; the agent's body addresses the Builder as "you" (trailing space, as in the group above).
# The session then reads the reason off the return, so `## The return` above its examples has to
# put it on a `fallback:` line naming which of the two held. `OUT OF BRIEF` is a later behaviour.
undispatchable='linked|not installed|cannot be dispatched|can.t be dispatched|could not be dispatched|cannot dispatch|can.t dispatch|unavailable'
for reader in agent contract; do
  case "$reader" in
    agent) where="do-builder.md's body" scope="$stmp/builder-body.md" ;;
    *) where="builder.md's \`## The Implementer\`" scope="$stmp/implementer-section.md" ;;
  esac
  flat="$(awk -v k="$undispatchable" 'BEGIN { RS = "" } $0 ~ k && /[Ii]mplementer/ { gsub(/\n/, " "); print }' "$scope" |
    tr '\n' ' ' | tr -s ' ')"
  expect "$where says what follows an Implementer that cannot be dispatched" test -n "$flat"
  carries_each "$where: the two reasons are an Implementer not linked and a dispatch refused" \
    "not linked" "isn't linked" "is unlinked" "not installed" "no \`do-implementer\`" \
    -- "dispatch is refused" "dispatch refused" "refuses the dispatch" "refused dispatch" "is refused" \
    "is denied" "denies the dispatch" "dispatch denied"
  affirms "$where: the Builder then writes the production code itself" \
    "Builder" "it writes" "you " -- "write" "writes" -- "itself" "yourself" "by hand" "its own" "your own"
  carries_any "$where: the run goes on" \
    "run goes on" "run continues" "run carries on" "run keeps going" "goes on" "carries on" \
    "never stops the run" "does not stop the run" "without stopping" "instead of stopping" \
    "rather than stopping" "rather than stop"
done
flat="$(passage_of "$contract" "## The return" "### Examples" |
  awk -v k="$undispatchable" 'BEGIN { RS = "" } $0 ~ k && /[Ii]mplementer/ { gsub(/\n/, " "); print }' |
  tr '\n' ' ' | tr -s ' ')"
expect "\`## The return\` says what an Implementer that cannot be dispatched leaves on the return" test -n "$flat"
carries_each "\`## The return\`: a \`fallback:\` line names which reason held, not linked or the dispatch refused" \
  "\`fallback:\`" "\`fallback\` line" "fallback line" \
  -- "not linked" "isn't linked" "is unlinked" "not installed" "no \`do-implementer\`" \
  -- "dispatch is refused" "dispatch refused" "refuses the dispatch" "refused dispatch" "is refused" \
  "is denied" "denies the dispatch" "dispatch denied"

echo "# skills/do/references/builder.md / ## The Implementer, skills/do/agents/do-builder.md: an \`OUT OF BRIEF\` return is a failed dispatch, dispatched once more like \`NOT GREEN\`, and a second failure has the Builder write the edit"

# A brief that merely left out a file the edit needs comes back `OUT OF BRIEF` with `Ruled out:`
# and `Needs:` and nothing edited. A Builder that stops there, or skips the cheap retry and writes
# the edit itself at once, or hands it to the test author, costs the developer either the run or
# the Sonnet dispatch the fix needed. The route is the failed dispatch's own: one more dispatch for
# the same edit, carrying what the first one ruled out (and what it needs) between an opening and a
# closing tag sharing one random id, and only a second failure on that edit, a second `OUT OF BRIEF`
# among them, has the Builder write it. The retry is read off the paragraphs that name
# `OUT OF BRIEF` and a dispatch once more, and the second failure off those that name it beside the
# Builder's own write, in both readers; the agent's body addresses the Builder as "you" (trailing
# space, as in the groups above).
for reader in agent contract; do
  case "$reader" in
    agent) where="do-builder.md's body" scope="$stmp/builder-body.md" ;;
    *) where="builder.md's \`## The Implementer\`" scope="$stmp/implementer-section.md" ;;
  esac
  flat="$(awk 'BEGIN { RS = "" } /OUT OF BRIEF/ && /once more|again|a second time|re-?dispatch/ { gsub(/\n/, " "); print }' "$scope" |
    tr '\n' ' ' | tr -s ' ')"
  expect "$where names \`OUT OF BRIEF\` among the returns dispatched once more" test -n "$flat"
  affirms "$where: on \`OUT OF BRIEF\` the Builder dispatches the Implementer once more" \
    "do-implementer" "Implementer" -- "once more" "again" "a second time" "re-dispatch" "redispatch"
  carries_any "$where: \`OUT OF BRIEF\` is a failed dispatch, as \`NOT GREEN\` is" \
    "failed dispatch" "failed one" "a failure" "as a failure" "NOT GREEN"
  carries_any "$where: the second dispatch is for the same edit" \
    "same edit" "that edit" "this edit" "the same brief" "same \`Edit:\`"
  carries_each "$where: what the first return ruled out and needs reaches the second dispatch" \
    "Ruled out:" "\`Ruled out\`" -- "Needs:" "\`Needs\`" "what it needs" "the file it needs" "files it needs"
  expect "$where: what it ruled out sits between an opening and a closing tag carrying the same id" \
    bash -c 'grep -qE "<([a-z][a-z-]*) id=\"([^\"]*)\">.*</\\1 id=\"\\2\">" <<<"$1" ||
      grep -qE "tags? (that )?(share|sharing|carry|carrying)" <<<"$1"' _ "$flat"
  carries_any "$where: the id the two tags share is a random one the Builder generates for that re-dispatch" \
    "random id" "random \`id\`" "one random" "short random"

  flat="$(awk 'BEGIN { RS = "" } /OUT OF BRIEF/ && /[Ss]econd|again|twice/ && /itself|yourself|by hand/ { gsub(/\n/, " "); print }' "$scope" |
    tr '\n' ' ' | tr -s ' ')"
  expect "$where names a second \`OUT OF BRIEF\` among the second failures the Builder writes itself" test -n "$flat"
  affirms "$where: on a second failure, a second \`OUT OF BRIEF\` among them, the Builder writes the edit itself" \
    "Builder" "it writes" "it makes" "you " -- "write" "makes" "edits" "applies" -- "itself" "by hand" "its own" "yourself" "your own"
  carries_each "$where: a second failure is a second \`NOT GREEN\`, a second \`OUT OF BRIEF\` or a second refused changeset" \
    "NOT GREEN" -- "OUT OF BRIEF" -- "refus"
  carries_any "$where: that is the edit the two dispatches failed on" \
    "same edit" "that edit" "this edit" "the edit itself"
done

echo "# skills/do/references/builder.md, skills/do/agents/do-builder.md: work for another repository ends the Stretch on \`stopped\`"

# A feature that spans repositories can hand the Builder a behaviour whose change belongs in a
# repository its worktree is not part of, and nothing it builds there sits on the run's branch or in
# its diff. The session routes on the `stopped:` line alone and writes the finding into the Spec
# from it, so the line has to name the behaviour and the repository, with where that repository
# sits on this machine or that nobody knows. Without the rule a guard-denied write in a sibling
# repository reads as an obstacle to route around, or the Builder builds the rest and returns
# `built`, and the Ticket reads `resolved` with a criterion that cannot pass in this repository.
# Both readers are asked, since the fork may never open the contract and the session never opens
# the agent. Each is read by paragraph, unwrapped first (the files hard-wrap), and only the
# paragraphs that name another repository are kept: the `stopped` shape and the guard's own bullets
# say plenty about stops and denials already, and none of it may answer for this decision.
for reader in contract agent; do
  case "$reader" in
    contract)
      reader_name="the contract"
      reader_text="$(passage_of "$contract" "## The return" "## " &&
        echo && passage_of "$contract" "## Its edges" "## ")"
      ;;
    *)
      reader_name="the building agent's own definition"
      reader_text="$(passage_of "$agent" "## How your turn ends" "## What you return" &&
        echo && passage_of "$agent" "## What you return" "## ")"
      ;;
  esac
  awk 'BEGIN { RS = ""; ORS = "\n\n" } { gsub(/\n/, " "); print }' <<<"$reader_text" >"$stmp/unwrapped.md"
  flat="$(for naming in "other repository" "different repository" "sibling repository" \
    "second repository" "repository other than" "repository that is not" "repository it does not" \
    "repository you do not" "not the one its worktree" "not the one your worktree" \
    "outside its repository" "outside your repository"; do
    paragraph_with "$stmp/unwrapped.md" "$naming" all
  done | tr '\n' ' ' | tr -s ' ')"
  carries_each "$reader_name: a behaviour that needs a change in another repository ends the Stretch on \`stopped\`, its reason naming the behaviour, the repository and its location or that it is not known, a guard-denied write being one way of finding out, with nothing built there and nothing written into the Spec" \
    "\`stopped\`" "stopped:" \
    -- \
    "names the behaviour" "naming the behaviour" "name the behaviour" "the behaviour and the repository" \
    "which behaviour" "the behaviour that needs" "the behaviour that needed" "the behaviour needing" \
    "the behaviour it" "the behaviour you" "the behaviour whose" \
    -- \
    "repository it belongs" "repository that owns" "repository the change belongs" \
    "repository the behaviour belongs" "repository the work belongs" "and the repository" \
    "which repository" "names the repository" "naming the repository" "name the repository" \
    "the owning repository" "belongs to another repository" "belongs in another repository" \
    -- \
    "location" "where it sits" "where that repository" "where the repository" "its path" \
    "path on this machine" \
    -- \
    "not known" "unknown" "nobody knows" "no one knows" "is not listed" "does not know" \
    "do not know" "none is known" \
    -- \
    "a write its guard denied" "a write your guard denied" "a write the guard denied" \
    "a write its hook denied" "a write your hook denied" "a write the hook denied" \
    "a denied write" "denied write" "a write denied" "write that was denied" "write it denied" \
    "guard denied" "hook denied" "guard denies" "hook denies" "denial of a write" \
    -- \
    "builds nothing there" "build nothing there" "nothing there" "nothing is built" \
    "nothing in that repository" "nothing in the other repository" "nothing in the sibling" \
    "never builds it" "does not build it" "do not build it" "leaves it unbuilt" "leave it unbuilt" \
    "builds none of it" "build none of it" "never builds there" "never build there" \
    -- \
    "nothing into the Spec" "nothing to the Spec" "nothing in the Spec" "never writes the Spec" \
    "never write the Spec" "does not write the Spec" "do not write the Spec" "no write to the Spec" \
    "no Spec write" "never into the Spec" "not into the Spec" "the Spec is the session's" \
    "the session writes the finding" "the session writes it into the Spec" \
    "the Spec write is the session's" "the Spec is not the fork's" "the Spec is not yours"
done

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

echo "# skills/do/references/mechanics.md: the one-writer rule names the runs it still holds for"

# mechanics.md is the file `ticket`, `bug-fix` and `refactoring` all read, and its `## Delegates`
# section is where ADR 0009's rule that the session writes the production code is written down for
# all three. ADR 0047 supersedes it for `ticket` alone, whose build step forks the Builder, so a
# section that states the rule flat contradicts the Playbook that links it, and the next change
# made from it puts the session back in the writer's seat for a `ticket` run: the loop paid for
# twice and a window that grows with the Ticket again, the one cost the fork exists to remove.
flat="$(flat_section "$mechanics" "## Delegates")"
expect "mechanics.md carries the \`## Delegates\` section" test -n "$flat"

# Read sentence by sentence, since the reader acts on the sentence that says who writes the code,
# not on the section as a whole: one that names no run at all is read by a `ticket` run as its own.
# The accepted names are the two Playbooks the rule still holds for and the `ticket` run it no
# longer does, however that run is named (the Playbook, the fork, or the ADR that moved it).
unscoped=""
while IFS= read -r sentence; do
  [ -n "$sentence" ] || continue
  named=""
  for key in "bug-fix" "refactoring" "ticket" "Builder" "builder" "0047"; do
    grep -qF -- "$key" <<<"$sentence" && named=yes
  done
  [ -n "$named" ] || unscoped="$sentence"
done < <(awk 'BEGIN { RS = "\\. " } /production code/ { print }' <<<"$flat")
if [ -z "$unscoped" ]; then
  ok "no sentence of \`## Delegates\` leaves the session writing the production code in a \`ticket\` run"
else
  fail "\`## Delegates\` states the one-writer rule over every Playbook (\"$unscoped\")"
fi

# And the rule is scoped, not deleted: `bug-fix` and `refactoring` still build in the session's own
# window, and a reader of either finds the rule named for its own run.
carries_each "the rule is kept for the two Playbooks whose session still writes the code" \
  "bug-fix" -- "refactoring"

echo "# skills/do/agents/do-builder.md: a just-text clause for a stranger's imperative in the Ticket, the Digest or the Plan"

# The Builder is forked with Bash, Write, Edit and Agent, and it reads the Ticket and the Digest
# (and the Plan), which may carry text a stranger appended to a remote tracker issue, the exposure
# do-planner.md's own last paragraph names for itself and carries the same clause against. With no
# line telling the Builder that an imperative sentence in that text is material to build from and
# never an instruction to it, the Builder has nothing in its own contract distinguishing a line the
# Ticket asks it to prove from a line telling it what to do with the tools it holds. do-builder.md
# ships no `<!-- testing-policy:core-start/end -->` markers, unlike AGENT-UNIT.md and AGENT-E2E.md
# (handback-just-text.sh's own scope), so the check reads the whole body after the frontmatter's
# closing `---` rather than a marked-off core. The same regex handback-just-text.sh already runs.
agent_body="$(body_of "$agent")"
if grep -qE 'never an instruction to (you|follow)' <<<"$agent_body"; then
  ok "the building agent's body carries a just-text clause for a stranger's imperative in the Ticket, the Digest or the Plan"
else
  fail "the building agent's body carries a just-text clause for a stranger's imperative in the Ticket, the Digest or the Plan (no line matching 'never an instruction to you/follow' found in the body)"
fi

echo "# skills/do/agents/do-builder.md: the time budget command resolves in a project that does not hold the skill"

# The Builder runs in the worktree of whatever project is being built, and a repo-relative
# `skills/do/scripts/...` path only resolves when that project is this repository: anywhere else the
# command prints no verdict and the stretch never learns it should return. An empty extraction would
# make every later grep and the guard's pass vacuous, so each of them also requires the command.
budget_cmd="$(grep -E '^bash .*stretch-budget\.sh' "$agent" | head -n 1)"
expect "the building agent names the time budget command as a runnable \`bash\` line" test -n "$budget_cmd"

budget_section="$(passage_of "$contract" "## Asking the time budget" "## ")"
expect "builder.md's \`## Asking the time budget\` carries the same command verbatim" \
  bash -c '[ -n "$1" ] && grep -qF -- "$1" <<<"$2"' _ "$budget_cmd" "$budget_section"

budget_proj="$stmp/budget/proj/.claude/worktrees/w1"
budget_home="$stmp/budget/home"
mkdir -p "$budget_proj" "$budget_home/.claude/skills"
ln -s "$here/.." "$budget_home/.claude/skills/do"
budget_placeholder="<your start>"
budget_run="${budget_cmd/"$budget_placeholder"/$(date +%s)}"

budget_hook_out="$(jq -n --arg command "$budget_run" --arg cwd "$budget_proj" \
  '{tool_input: {command: $command}, cwd: $cwd}' | sh -c "$(hook_command "$agent" Bash)" 2>/dev/null)"
expect "the Builder's Bash guard lets the time budget command through" \
  bash -c '[ -n "$1" ] && ! grep -qF "\"permissionDecision\": \"deny\"" <<<"$2"' _ "$budget_run" "$budget_hook_out"

budget_out="$(cd "$budget_proj" && HOME="$budget_home" bash -c "$budget_run" 2>&1)"
expect "the command prints its verdict from a project that does not hold the skill" \
  bash -c 'grep -q "^stretch=continue" <<<"$1"' _ "$budget_out"

echo "# builder.md / do-builder.md: the time budget is read after each behaviour's commit and never on an Implementer's return"

# An Implementer's return sits inside a cycle, before the behaviour is formatted and committed: a
# `stop` read there returns the Stretch with uncommitted work, which the resume refuses, and a
# Builder that never reads it outlasts its budget past the session's prompt cache. The agent's side
# is read over every paragraph naming the time budget, since the guarantee may sit in any of them.
# The Implementer half is bound to one sentence, so a mention of the Implementer elsewhere in the
# scope never answers for the negation.
for budget_scope in contract agent; do
  case "$budget_scope" in
    contract) budget_label="builder.md's \`## Asking the time budget\`" budget_flat="$(flat_section "$contract" "## Asking the time budget")" ;;
    agent) budget_label="do-builder.md's time budget paragraphs" budget_flat="$(paragraph_with "$agent" "time budget" all | tr '\n' ' ' | tr -s ' ')" ;;
  esac
  flat="$budget_flat"
  carries_each "$budget_label: the budget is asked after each behaviour's commit and at no other moment" \
    "fter each behaviour's commit" "fter every behaviour's commit" "fter each commit" "nce each behaviour is committed" -- \
    "t no other moment" "t no other point" "ever at any other" "nly after each" "nly on a commit" "nly on each"
  flat=" $(grep -oE "[^.;:]*Implementer[^.;:]*" <<<"$budget_flat" | tr '\n' ' ') "
  carries_each "$budget_label: an Implementer's return is not a moment the budget is asked" \
    "return" "comes back" "hands back" -- \
    " never " " not " " no " " nor " "n't "
done

echo "# docs/do.md: the do-builder row says the Builder hands every production edit to the Implementer, and what its brief carries"

# A developer learns what a ticket run does on their machine from this page, not from the agent
# files: a row that says the Builder writes the code leaves them unable to tell which agent wrote
# it, or why a second agent runs under the Builder. The row is selected by its first cell, so the
# do-impeccable row, which also speaks of the Builder, never answers for it.
do_doc="$here/../../../docs/do.md"
builder_row="$(grep -E '^\| \[do-builder\]' "$do_doc")"
expect "docs/do.md carries the do-builder row of its Prerequisites table" test -n "$builder_row"
flat="$(tr -s ' ' <<<"$builder_row")"
carries_each "the do-builder row names \`do-implementer\` as the agent the Builder dispatches" \
  "do-implementer" -- "dispatch" "fork" "hands"
carries_each "the do-builder row names each production edit the Implementer takes: green, seam, fix and refactor" \
  "green" -- "seam" -- "fix" -- "refactor"
carries_each "the do-builder row says the brief carries the behaviour, the test file and its command, the files, the symbols and signatures, the seam and the typecheck command" \
  "brief" -- "behaviour" -- "test file" "test's file" -- "command" -- "files to edit" "files it edits" "file to edit" \
  -- "symbol" -- "signature" -- "seam" -- "typecheck" "type-check" "type check"

# ADR 0091: the Reply never carries the per-fork lines nor `Planner/Builder: none`; they live in the
# Run report, which only `--auto` writes. A row that sends a reader to the Reply for that line has
# them read its absence as "the Builder was forked" when no fork could run.
flat="$(tr -s ' ' <<<"$builder_row")"
carries "the do-builder row says the Builder returns the lines the run records" "the lines the run records"
out="$flat"
absent "the do-builder row never says the Builder returns lines the Reply owes" "your Reply owes"
absent "the do-builder row never puts the \`Planner/Builder: none\` line in the Reply" "Reply carries one \`Planner/Builder: none\`"
flat="$(grep -oE '[^.]*Planner/Builder: none[^.]*' <<<"$out" | tr '\n' ' ')"
before "the do-builder row's sentence on \`Planner/Builder: none\` puts that line in the Run report" "Run report" "Planner/Builder: none"

exit $((fails > 0))
