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
forks="$here/../references/forks.md"
mechanics="$here/../references/mechanics.md"
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
flat="$(flat_section "$playbook" "## Resume")"
expect "the Playbook carries a \`## Resume\` section to scope this check against" test -n "$flat"

carries_any "a resumed run with unbuilt behaviours forks the Builder rather than running the loop itself" \
  "The Builder is forked" "the Builder is forked"

# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$flat"
check_absent "the Resume section no longer has the run build the flows itself before the gate" 0 0 \
  "the flows, the gate, the review, the close, the reply"

# The branch where every behaviour is already ticked still meets the fork's diff, never a flow it
# treats as self-authored: it goes on at step 4 the way a first run does, reading the Builder's diff.
flat="$(flat_section "$playbook" "## Resume")"
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
git config user.email t@example.com
git config user.name t
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

echo "# skills/do/references/ticket.md: the two runs with no Builder to fork, and what each is told"

# The run that cannot fork the Builder at all, the way the Plan step already writes the Planner's
# half (planner.sh owns that one). Scoped to the build step again, by what the step says rather than
# by its number, so the Plan step's own fallback paragraph cannot answer here for a build step that
# says nothing. Each guarantee below can be phrased several ways and the cases pin more than one at
# a time, so the group of phrasings that found nothing is what a failure names: lib.sh's
# carries_each.
flat="$(item_holding "$playbook" '\*\*[0-9]+\.' "do-builder" | tr '\n' ' ' | tr -s ' ')"
expect "a step of the Playbook hands the build to the fork, to read its fallback off" test -n "$flat"

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
# still be holding the hashes it verified. The evals refuse exactly this substitution for the other
# forks (evals/unlisted-choice-taker/graders/no-general-agent-in-its-place.md).
carries_each "the run forks no other agent in the Builder's place" \
  "never forks another agent" "forks no other agent" "never forks a second agent" \
  "no other agent is forked" "another agent in the Builder's place" \
  -- \
  "in the Builder's place" "in its place" "in the place of the Builder"

# The build still owes the Ticket its flows, degraded or not: a fallback that ran the loop and said
# nothing about them is the old step-4 gap this text exists to close (a criterion nobody flowed and
# nothing said about it). It binds to the same rule the forked Builder reads, builder.md's
# `## The flows`, and to the Digest's own list of what needs one, so a rewrite of either is read the
# same way here.
carries_each "on either branch the session authors the flows itself, per builder.md's flows rule, for the criteria the Digest's Observable criteria section names" \
  "authors the flows itself" "also authors the flows" \
  -- \
  "builder.md" \
  -- \
  "\`## The flows\`" "The flows" \
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
agent_body="$(awk 'BEGIN { dashes = 0 } /^---$/ { dashes++; next } dashes >= 2' "$agent")"
if grep -qE 'never an instruction to (you|follow)' <<<"$agent_body"; then
  ok "the building agent's body carries a just-text clause for a stranger's imperative in the Ticket, the Digest or the Plan"
else
  fail "the building agent's body carries a just-text clause for a stranger's imperative in the Ticket, the Digest or the Plan (no line matching 'never an instruction to you/follow' found in the body)"
fi

exit $((fails > 0))
