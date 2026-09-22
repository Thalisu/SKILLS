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
playbook="$here/../references/ticket.md"
plan_format="$here/../references/plan.md"
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

# Ticket 02 (a resolved probe) found a `PreToolUse` hook declared in an agent's own frontmatter
# fires for that agent's own tool calls, when the definition file is on disk before the session
# starts. This is the best-effort guard beside the door's header check: it limits the fork's
# `Write` to the Plan's own pattern and refuses an overwrite, so a bug in the write path (a path
# outside the Plan, or a clobbered existing Plan) has an independent hook-level check catching it.
expect "the planning agent declares a PreToolUse hook scoped to its Write tool" \
  bash -c '[ -n "$1" ] && grep -qE "^ *PreToolUse:" <<<"$1" && grep -qE "matcher: *Write" <<<"$1"' \
  _ "$out"

# The body, flattened: the definition hard-wraps its prose, so a phrase sits across two lines as
# often as not. The frontmatter is dropped so its `description` never answers for the write step.
flat="$(awk 'NR == 1 && $0 == "---" { fm = 1; next } fm && $0 == "---" { fm = 0; next } !fm' "$agent" |
  tr '\n' ' ' | tr -s ' ')"
expect "the planning agent carries a body below its frontmatter" test -n "$flat"

# The Ticket and the Digest may carry a stranger's text (the body's own closing paragraph says so),
# and the frontmatter grants `Agent` with no scope restriction: a body that names `sketch` for the
# shape step but never states, absolutely, that it is the only agent the fork may dispatch leaves a
# prompt-injected line free to make the fork dispatch do-code-review or prototype instead, either of
# which holds `Bash`, one layer below a fork that itself holds none.
carries_any "the planning agent's body forbids dispatching any agent but sketch" \
  "no agent but sketch" "no agent but \`sketch\`" "dispatches no agent but sketch" \
  "dispatch no agent but sketch" "dispatches no agent but \`sketch\`" \
  "dispatch no agent but \`sketch\`" "no agent other than sketch" "no agent other than \`sketch\`" \
  "the only agent you dispatch" "the only agent you fork" "the only agent this fork dispatches" \
  "sketch is the only agent" "\`sketch\` is the only agent" "never dispatch any other agent" \
  "never fork any other agent" "dispatch no other agent" "fork no other agent"

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

echo "# skills/do/references/ticket.md: the grounding step forks the Planner and holds the path"

# The Playbook's side of the same handover. Scoped to the step that names the fork, taken from its
# `**<n>.` marker to the next one: the step is renumbered by the change that writes it, since the
# shape and behaviours steps are absorbed into the fork and everything below them shifts up, so the
# number, the title and the order are all moving and none of them can anchor anything. The scope is
# what keeps the shape step's own fork out: that one already explores in a window of its own and
# fills a brief, so a file-wide search would read its sentences as this step's.
whole="$(tr '\n' ' ' <"$playbook" | tr -s ' ')"
flat="$whole"
carries "the Playbook names the Planner fork \`do\` ships" "do-planner"

flat="$(item_holding "$playbook" '\*\*[0-9]+\.' "do-planner" | tr '\n' ' ' | tr -s ' ')"
expect "a step of the Playbook hands the grounding to that fork" test -n "$flat"

# A fork dispatched with nothing knows no Ticket, no Sources and no path to write the Plan at.
carries_any "the step forks it with a brief" \
  "the brief" "a brief" "its brief" "brief in" "brief of" "brief below"

# Criterion 1 of the Ticket: the grounding happens in the fork, not in the developer's window. A
# Playbook that forks the Planner and still has the session read the ground pays for the reading
# twice, and the window grows with the Ticket exactly as before. The three imperatives below are
# what an inline grounding is made of, and no step may carry one, not only the step that forks: read
# over the whole file so a grounding left behind in a neighbouring step is caught too. A step that
# explains what the fork reads states it of the fork, never as an order to the session.
# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$whole"
check_absent "no step has the session ground in its own window" 0 0 \
  "Read \`CONTEXT.md\`" "call the Skill tool with \`how\`" "call the Skill tool with \`discover\`"

# Criterion 2: what crosses back is the path alone. A session that reads the Plan back has put the
# whole grounding in its window, and nothing downstream would catch it: the run still builds and
# still lands.
carries_any "the fork hands back the Plan's path" \
  "returns the Plan's path" "return the Plan's path" "returns the path" "return the path" \
  "returns that path" "return that path" "the path it returns" "the path the fork returns" \
  "the Plan's path" "hands back the path" "comes back is the path"

carries_any "the session never reads the Plan back" \
  "never reads the Plan" "never read the Plan" "does not read the Plan" "never opens the Plan" \
  "opens no Plan" "never read back" "is never read back" "never reads it back" \
  "never the Plan's text" "never its text" "never the text" "holds only the path" \
  "the path alone" "path and never"

# Criterion 3: the path check alone proves the Plan is at the right place, never that it is the
# right Plan. A fork could write at the named path a Plan cut from a stale or a tampered Ticket or
# Digest, and only the header comparison against the hashes the door computed before the fork,
# per ADR 0048 and plan.md's `## Sources` rule, catches that: a run that skips this comparison
# silently builds behaviours from an unverified grounding artifact.
carries_any "the step refuses a Plan whose \`## Sources\` lines do not match the hashes the door computed" \
  "do not match the two hashes" "does not match the two hashes" "don't match the two hashes" \
  "not the two hashes" "not the hashes it computed" "not the hashes the door computed" \
  "not match the hashes" "do not match the hashes" "does not match the hashes" \
  "the hashes do not match" "the hashes don't match" "the hashes it computed do not match" \
  "the Sources lines do not match" "\`## Sources\` lines do not match" \
  "\`## Sources\` lines it computed" "a mismatch" "the hashes moved"

carries_any "the step stops the run in one line naming the Sources mismatch" \
  "stops the run naming the Sources mismatch" "stops the door naming the Sources mismatch" \
  "stops in one line naming the mismatch" "stops the run in one line naming the mismatch" \
  "stops the door in one line naming the mismatch" "refuses the Plan and stops" \
  "refuses that Plan and stops" "refuses the Plan, stopping" "the mismatch stops the run" \
  "a mismatch stops the run" "naming the mismatch" "naming the Sources mismatch" \
  "and stops the run in one line" "and stops the door in one line"

# The session names the path itself and never learns it from the fork's return, so a path built by
# any other rule is a Plan nothing downstream, and no next run on this Ticket, ever finds.
carries "the Plan is keyed by the Ticket's file name, \`.plan\` before the extension" ".plan"
carries "a Ticket that is an issue keys its Plan under \`.scratch/plans/\`" ".scratch/plans/"

echo "# the Plan path plan.md documents for an issue, against the planning agent's own PreToolUse hook"

# The command sits three levels into the frontmatter's \`hooks:\` block, a YAML double-quoted string
# with the JSON payload's own quotes escaped inside it, so field() (which reads a top-level
# \`key: value\` line off $out) cannot reach it: pull the one \`command:\` line and undo the YAML
# escaping by hand, the way the harness's own YAML parser would before handing it to a shell.
hook_cmd="$(grep -m1 '^ *command:' "$agent" | sed -E 's/^ *command: *"//; s/"$//')"
hook_cmd="${hook_cmd//\\\"/\"}"
expect "the planning agent's PreToolUse hook carries a command to extract" test -n "$hook_cmd"

# Without jq the command exits 0 before it ever reads the path, and every case below would pass on a
# hook that never ran.
expect "jq is on PATH so the extracted hook runs its own logic, not its early exit" \
  bash -c 'command -v jq >/dev/null 2>&1'

# The path the session names for a Ticket that is not a local file, read out of the section that
# fixes it rather than written here: a case carrying its own copy of the path proves nothing about
# what the documents tell the session to name. Its own \`## Where it lives\` neighbour, the Ticket's
# own file name, is named concretely (\`02-export-notes.plan.md\`), so the issue-keyed case is read
# the same way, as the file name the section spells out under \`.scratch/plans/\`. A separate
# variable, since \$flat still holds the Playbook step the cases below read.
where_lives="$(flat_section "$plan_format" "## Where it lives")"
expect "plan.md carries the \`## Where it lives\` section that fixes the Plan's path" test -n "$where_lives"

issue_name="$(grep -oE '\.scratch/plans/[A-Za-z0-9][A-Za-z0-9._-]*' <<<"$where_lives" |
  head -1 | sed 's|^\.scratch/plans/||')"
expect "plan.md names the issue-keyed Plan file it puts under \`.scratch/plans/\`" test -n "$issue_name"

# That path, through the hook's own command, live, the way Write would take it before the Planner's
# first write. The hook lets a write through its \`*.plan.md)\` arm alone, so a documented path that
# never matches it falls to the deny-all \`*)\` arm and the fork's one write is refused on every
# Ticket that is an issue, leaving the run with no Plan to build from. Silence is the hook allowing
# the write: it prints a decision only when it refuses one.
issue_path=".scratch/plans/$issue_name"
hook_out="$(printf '{"tool_input": {"file_path": "%s"}}' "$issue_path" | sh -c "$hook_cmd" 2>/dev/null)"
expect "the issue-keyed Plan path plan.md documents is one the Planner's own hook lets it write" \
  bash -c '! grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$hook_out"

# The `*.plan.md)` arm only lets a write through when nothing sits there yet: the two other branches
# of the same arm, an already-written Plan at that exact path and a path that never carries the
# `.plan.md` suffix at all, both hit a `printf` and both come back with the deny key set.
hook_tmp="$(mktemp -d)"
existing_plan="$hook_tmp/existing.plan.md"
: >"$existing_plan"
existing_hook_out="$(printf '{"tool_input": {"file_path": "%s"}}' "$existing_plan" | sh -c "$hook_cmd" 2>/dev/null)"
expect "the hook denies a write at a \`.plan.md\` path a Plan already sits at" \
  bash -c 'grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$existing_hook_out"

wrong_path=".scratch/plans/42.md"
wrong_hook_out="$(printf '{"tool_input": {"file_path": "%s"}}' "$wrong_path" | sh -c "$hook_cmd" 2>/dev/null)"
expect "the hook denies a write at a path that never carries the \`.plan.md\` suffix" \
  bash -c 'grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$wrong_hook_out"
rm -rf "$hook_tmp"

# A machine with no \`jq\` on PATH: the hook's own early exit, \`command -v jq >/dev/null 2>&1 || exit
# 0\`, fires before the command ever reads \`.tool_input.file_path\`, and \`exit 0\` with no stdout is
# what the harness reads as allow. A stranger's text in the Ticket or the Digest could steer the
# fork toward a path outside its one Plan (\`.git/config\` here), and this guard is the Planner's only
# independent check against that once the fork is running: it has to fail closed, never open, when
# jq happens to be missing. A bare PATH override is not enough: stripping every directory that holds
# jq also strips \`/usr/bin\`, and \`sh\` itself, one \`command -v jq\` fails to find, turns \`sh -c
# "$hook_cmd"\` red for a reason that has nothing to do with the hook. The stand-in directory below
# symlinks every other \`/usr/bin\` entry, so \`sh\`, \`grep\` and \`printf\` still resolve and only \`jq\`
# is gone.
no_jq_dir="$(mktemp -d)"
for bin in /usr/bin/*; do
  name="$(basename "$bin")"
  [ "$name" = jq ] && continue
  ln -s "$bin" "$no_jq_dir/$name" 2>/dev/null
done
denied_path=".git/config"
no_jq_rc=0
no_jq_out="$(printf '{"tool_input": {"file_path": "%s"}}' "$denied_path" |
  PATH="$no_jq_dir" sh -c "$hook_cmd" 2>"$no_jq_dir/.err")" || no_jq_rc=$?
no_jq_err="$(cat "$no_jq_dir/.err" 2>/dev/null)"
expect "the hook denies a write outside its one Plan when jq is absent from PATH, instead of exiting 0 silently" \
  bash -c '{ [ "$1" -ne 0 ] && [ -n "$2" ]; } || grep -qF "\"permissionDecision\": \"deny\"" <<<"$3"' \
  _ "$no_jq_rc" "$no_jq_err" "$no_jq_out"
rm -rf "$no_jq_dir"

echo "# the planning agent's own PreToolUse hook on its Agent tool: no fork but sketch"

# The frontmatter grants \`Agent\` with no scope of its own (Finding 4 of the do-code-review pass):
# a body sentence forbidding every dispatch but sketch is prose the fork itself could be tricked into
# ignoring by a hostile line the Ticket or the Digest carries, since both may hold a stranger's text.
# A second \`PreToolUse\` matcher, on \`Agent\`, is the hook-level guarantee that a Bash-capable fork
# (do-code-review, prototype, general-purpose) is unreachable one hop past the Planner even when the
# body's prose fails, mirroring the \`Write\` matcher already scoping the one tool the Planner keeps.
fm_out="$(frontmatter "$agent" 2>/dev/null)" || fm_out=""
expect "the planning agent declares a second PreToolUse hook scoped to its Agent tool" \
  bash -c '[ -n "$1" ] && grep -qE "^ *PreToolUse:" <<<"$1" && grep -qE "matcher: *Agent" <<<"$1"' \
  _ "$fm_out"

# The Agent-matcher entry's own \`command:\` line, scoped the same way the Write-matcher one is scoped
# above: from its \`- matcher: Agent\` marker to the next \`- matcher:\` line or the end of the file,
# so a two-matcher \`hooks:\` block never hands this extraction the Write hook's command by mistake.
agent_hook_cmd="$(awk '
  /^ *- matcher: *Agent *$/ { on = 1; next }
  on && /^ *- matcher:/ { exit }
  on && /^ *command:/ { print; exit }
' "$agent" | sed -E 's/^ *command: *"//; s/"$//')"
agent_hook_cmd="${agent_hook_cmd//\\\"/\"}"
expect "the planning agent's Agent-matcher PreToolUse hook carries a command to extract" \
  test -n "$agent_hook_cmd"

sketch_out="$(printf '{"tool_input": {"subagent_type": "sketch"}}' | sh -c "$agent_hook_cmd" 2>/dev/null)"
expect "the hook lets the Planner fork sketch" \
  bash -c '! grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$sketch_out"

prototype_out="$(printf '{"tool_input": {"subagent_type": "prototype"}}' | sh -c "$agent_hook_cmd" 2>/dev/null)"
expect "the hook denies the Planner forking any agent but sketch" \
  bash -c 'grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$prototype_out"

# The run that cannot fork the Planner, per ADR 0047. Each guarantee below can be phrased several
# ways and the cases pin more than one of them at a time, so the group of phrasings that found
# nothing is what a failure names. Same accept-list idea as carries_any, one case over several
# groups: carries_any takes a single group and carries takes strings that must all appear verbatim,
# and neither says "each of these guarantees, however it is worded".
carries_each() { # $1 label, $2.. groups of fixed strings separated by `--`: each group needs one match in $flat
  local label="$1" key matched=0 group="" missing=""
  shift
  set -- "$@" "--"
  for key in "$@"; do
    if [ "$key" = "--" ]; then
      if [ -n "$group" ] && [ "$matched" = 0 ]; then missing="$missing (none of:$group)"; fi
      matched=0
      group=""
      continue
    fi
    group="$group $key"
    grep -qF -- "$key" <<<"$flat" && matched=1
  done
  if [ -z "$missing" ]; then ok "$label"; else fail "$label$missing"; fi
}

# A harness that withholds the Agent tool and a machine that never linked the agent `do` ships are
# the two runs with no fork to hand the grounding to. Named apart, because the developer's way out
# differs: one is the harness, the other is one run of the installer.
carries_each "the step names both branches on which no Planner can be forked" \
  "Agent tool withheld" "Agent tool is withheld" "no Agent tool" \
  -- \
  "lists no \`do-planner\`" "\`do-planner\` not listed" "no \`do-planner\` listed" \
  "lists no do-planner" "do-planner not listed" "no do-planner listed"

# The Plan is what every step below the grounding opens, at the path this step named: a fallback
# that grounds but writes nowhere, or writes somewhere else, leaves the build with no Plan to open.
carries_each "on either branch the session grounds and writes the Plan itself, at the same path" \
  "does that work itself" "grounds the Ticket itself" "grounds and writes the Plan itself" \
  "writes the Plan itself" "does the grounding itself" "the session grounds" \
  -- \
  "the same path" "that same path" "the same destination" "the path above" "the destination above"

# A degraded run and a normal one leave the same Plan at the same path, so this line is the only
# thing that tells a developer their own window carried the grounding.
carries_each "the run says in one line which of the two branches held" \
  "which of the two holds" "which of the two held" "which branch holds" "which branch held" \
  "which of the two branches held" "which of the two branches holds" "one line says which" \
  "says in one line which"

# Neither way out is available mid-run: the developer cannot hand over a tool the harness withheld,
# and a fork under another name could still hold what `do-planner`'s own definition denies it.
carries_each "the run neither stops nor asks for what it cannot get, and forks nobody else in the Planner's place" \
  "neither stops nor asks" "never stops and never asks" "does not stop and does not ask" \
  "neither stops the run nor asks" \
  -- \
  "never forks another agent" "forks no other agent" "never forks a second agent" \
  "no other agent is forked"

# The check the door runs over what the fork hands back, per ADR 0048 and plan.md's `## Sources`
# rule. The session never reads the Plan, so this check is the whole of what it knows about the
# artifact a whole branch of behaviours is cut from, and three returns reach it that a comparison
# of hashes alone lets through. Every case below shares the refusal as its last group: a branch the
# step names but still builds from costs the developer exactly what a branch it never names does.
refused=("is refused" "are refused" "refuses" "refused and stops" "stops the run"
  "Nothing is built" "nothing is built" "builds nothing")

# A fork that comes back with a line of prose and no path at all hands the session nothing to check.
# A step whose only branch is a hash comparison has no word for that return, and the run walks on to
# a destination nothing wrote, building from a file it never established exists.
carries_each "the step refuses a return that names no Plan at all" \
  "names no Plan" "a return that names no" "returns no path" "no path at all" \
  "no path comes back" "carries no path" "hands back no path" "comes back with no path" \
  "without a path" "returns nothing" "names no file" "no Plan path" \
  -- "${refused[@]}"

# The destination is the run's own, and every step below the grounding opens that path and no other.
# A return naming a different one is a Plan sitting somewhere the run never looks: the Plan it does
# open is whatever was already at the destination, an older cut of this Ticket or nothing at all, and
# a check that reads `## Sources` at the returned path rather than at the destination it named would
# hash a file the build never touches.
carries_each "the step refuses a returned path that is not the destination the run named" \
  "a path other than" "any path but the one" "differs from the destination" \
  "differs from the path it named" "not the path it named" "is not the destination" \
  "another path" "a different path" "a path the run did not name" "some other path" \
  -- "${refused[@]}"

# A hash says what a document held, never which document it was. plan.md fixes each `## Sources`
# line as `<name>: <absolute path> <hash>`, so a comparison that reads the hashes alone passes a
# Plan whose two names are swapped, cut with the Digest read as the Ticket, and one whose paths
# point into another checkout: both carry the two values the door computed and neither is the
# grounding the door hashed.
carries_each "the step matches each \`## Sources\` record on its name and its path as well as its hash" \
  "name, path and hash" "the name, the path and the hash" "its name, its path and its hash" \
  "name and path" "the path and the hash" "names and paths" "record whole" "whole record" \
  "each record whole" \
  -- "${refused[@]}"

# Two records is what the format fixes, one per document, and the count is its own check. A section
# carrying the Ticket's record alone, or carrying it twice and no Digest line, satisfies a
# comparison that only asks whether every line it reads is one the door computed, and the Plan is
# then vouched for against half of the grounding it claims to be cut from.
carries_each "the step refuses a \`## Sources\` section that is not exactly the two records, one missing or one repeated included" \
  "exactly the two records" "exactly two records" "two records and nothing" \
  "the two records the door" "two complete records" "exactly the two" \
  -- \
  "a missing record" "a record missing" "a duplicated record" "a duplicate record" \
  "the same name twice" "a name twice" "twice" "repeated" "a second line for the same" \
  "one record missing" \
  -- "${refused[@]}"

echo "# skills/do/references/ticket.md: the Resume section names the Plan step's real behaviour"

# The Resume section's own Plan bullet, not step 2's: step 2 already says a moved hash re-forks the
# Planner with a write, and the Resume bullet has to agree with it rather than restate the step from
# scratch. Scoped to the heading so a phrase step 2 carries legitimately is never read as this bullet's.
flat="$(flat_section "$playbook" "## Resume")"
expect "the Playbook carries a Resume section" test -n "$flat"

# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$flat"

# A resume that reused the Plan wrote nothing, but the hashes moving under it is exactly the branch
# step 2 sends to a fresh Planner fork, which does write. A bullet that claims the step never writes
# is wrong every time that branch is the one that held on this resume.
check_absent "the Resume section never claims the Plan step runs with no write" 0 0 \
  "without a write"

# The behaviours list is never rebuilt inline by the session from the Ticket and the Digest: that
# grounding happens once, inside the Planner fork, per ADR 0047, and a resume that opened the Ticket
# and the Digest itself to redo it would be the very inline grounding the fork exists to avoid.
check_absent "the Resume section never claims the list is re-derived from the Ticket and its Digest, never the commits" 0 0 \
  "re-derived from the Ticket and its Digest" "never from the commits"

# What the loop ticks off is the list already sitting in the Plan's own \`## Behaviours\` section,
# per plan.md, whichever run wrote it: the one reused because the hashes still matched, or the fresh
# one a moved hash forked the Planner again to write.
carries_any "the Resume section ties the behaviours list to the Plan's own \`## Behaviours\` section" \
  "Plan's \`## Behaviours\`" "Plan's Behaviours section" "\`## Behaviours\` section" \
  "the list in the Plan" "the Plan already holds" "list the Plan carries" \
  "the Plan holds the list" "reads the Plan" "opens the Plan"

carries_any "the Resume section names both branches step 2 leaves: the Plan reused when the hashes still match, or the Planner forked again when they moved" \
  "forks the Planner again" "forks \`do-planner\` again" "forks that fork again" \
  "the hashes moved" "the hashes differ" "hashes still match" "the same hashes" \
  "reuses the Plan" "reuse the Plan" "as step 2 does"

echo "# a Plan built per plan.md's \`## Sketch\` rule: the section stays whole past the Sketch's own headings"

# A Plan shaped exactly as plan.md directs: the Sketch's whole text, its own header included,
# embedded under the Plan's `## Sketch` heading with every heading in it demoted two levels, its
# title at `###` and its own sections at `####`, so no line of it opens a level-2 heading. Its
# rejected rivals are the last of those sections, past everything a reader would stop at first if
# the Sketch's own headings still sat at the Plan's level. The signatures section carries a fenced
# block, which a real Sketch does, so the section has to survive one. The Plan-level
# `## Where it lives` below is a genuinely separate section and stays out.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
plan="$tmp/plan.md"
cat >"$plan" <<'EOF'
## Sketch
### Sketch: export notes
Shapes: none
Map: none
Digest: none
Written: .scratch/plans/export-notes.plan.md

#### The caller's usage
The caller imports `exportNotes` and awaits it.

#### The types
`ExportOptions` carries the format and the destination path.

#### The signatures
```ts
export function exportNotes(options: ExportOptions): Promise<void> {
  throw new Error("not implemented")
}
```

#### The boundaries
The filesystem write is the only boundary crossed.

#### Rejected rivals
Nested shape: lost to indirection.

## Where it lives
skills/export/src/notes.ts
EOF

flat="$(flat_section "$plan" "## Sketch")"
expect "the Plan's \`## Sketch\` section holds the Sketch whole, rejected rivals included, past the Sketch's own headings" \
  bash -c '[ -n "$1" ] && grep -qF "Nested shape" <<<"$1"' _ "$flat"

exit $((fails > 0))
