#!/usr/bin/env bash
# impeccable-agent.sh: the definition of the fork that builds a Front-end ticket of a Spec reading
# `Front-end: impeccable` in the Builder's place (ADR 0078), read through its frontmatter.
# Run: bash skills/do/tests/impeccable-agent.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
agent="$here/../agents/do-impeccable.md"
builder="$here/../agents/do-builder.md"
ticket="$here/../references/ticket.md"
reference="$here/../references/impeccable.md"
fails=0

echo "# skills/do/agents/do-impeccable.md: the name the build step dispatches, pinned to the Builder's pair"

# The pair is read off the Builder's own frontmatter and never written here: the Ticket's Ruling
# settled it as the Builder's own, so a change to the Builder's tier has to move this fork with it.
# shellcheck disable=SC2034  # lib.sh's field reads $out
out="$(frontmatter "$builder" 2>/dev/null)" || out=""
builder_model="$(field model)"
builder_effort="$(field effort)"
expect "the Builder pins a model and an effort for the pair to be read from" \
  test -n "$builder_model" -a -n "$builder_effort"

# Every fork the build step names, one per line: the step is where the session reads the name it
# hands the Agent tool, so a name found anywhere else in the Playbook never answers for it.
dispatched="$(passage_of "$ticket" "**3. Build.**" "**4. Diff.**" |
  grep -oE 'subagent_type: [a-z0-9-]+' | sed 's/^subagent_type: //')"

# shellcheck disable=SC2034  # lib.sh's field reads $out
out="$(frontmatter "$agent" 2>/dev/null)" || out=""
name="$(field name)"

# The harness resolves a fork on the frontmatter `name`: one the build step never dispatches leaves
# the step handing the Ticket to a fork that resolves to nothing.
expect "the build step dispatches the name the definition's frontmatter carries" \
  bash -c '[ -n "$1" ] && grep -qxF -- "$1" <<<"$2"' _ "$name" "$dispatched"

# link-skills.sh links the definition under its file name, so the two have to agree for the linked
# file to be the fork the harness finds.
expect "the definition's file name and its frontmatter name agree" \
  test "$name" = "$(basename "$agent" .md)"

# ADR 0062: an agent with no pin runs at whatever model and effort the session holds.
# shellcheck disable=SC2034  # lib.sh's check_lines reads $out
out="model=$(field model)
effort=$(field effort)"
check_lines "the definition pins the Builder's own model and effort" 0 0 \
  "model=$builder_model" "effort=$builder_effort"

echo "# skills/do/agents/do-impeccable.md: its own Write|Edit hook keeps every write inside the run's worktree"

# ADR 0078: whether the impeccable skill honours a root other than the session's working directory
# is unproven, so the hook is what keeps the Main checkout as the developer left it while the fork
# builds. Run live, the way the harness runs it: the payload on stdin, carrying the `cwd` it reports.
# Without jq a guard that fails closed would deny every path, and the denials below would pass on a
# hook that never compared a path with the worktree at all.
expect "jq is on PATH so the extracted hook runs its own logic, not its fail-closed exit" \
  bash -c 'command -v jq >/dev/null 2>&1'

tmp="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$tmp"' EXIT
main="$tmp/main"
worktree="$main/.claude/worktrees/do-screen"
sibling="$main/.claude/worktrees/do-other"
mkdir -p "$worktree/src" "$sibling/src" "$main/.scratch/20260921-screen/issues"
printf 'readme\n' >"$main/README.md"
printf 'build it\n' >"$main/.scratch/20260921-screen/issues/03-screen.md"
printf 'theirs\n' >"$sibling/src/screen.tsx"
printf 'screen\n' >"$worktree/src/screen.tsx"
ln -s "$main/.scratch/20260921-screen/issues" "$worktree/src/data"
ln -s "$main/README.md" "$worktree/readme-alias.md"

hook_out_at() { # $1 the hook's command, $2 the file_path the tool was handed: the hook's stdout, run from the worktree with the payload on stdin
  (cd "$worktree" &&
    printf '{"cwd": "%s", "tool_input": {"file_path": "%s"}}' "$worktree" "$2" |
    sh -c "$1" 2>/dev/null)
}

for tool in Write Edit; do
  tool_hook="$(hook_command "$agent" "$tool")"
  # An empty command prints no deny either, so the paths let through below would pass on a
  # definition carrying no hook at all.
  expect "a PreToolUse hook scopes the fork's $tool" test -n "$tool_hook"

  for outside in "$main/README.md" \
    "$main/.scratch/20260921-screen/issues/03-screen.md" \
    "$sibling/src/screen.tsx" \
    "$worktree/src/../../../../README.md" \
    "../../../README.md" \
    "$worktree/src/data/03-screen.md" \
    "$worktree/readme-alias.md"; do
    outside_out="$(hook_out_at "$tool_hook" "$outside")"
    expect "the hook denies the fork's $tool at ${outside#"$tmp/"}, a path outside its worktree" \
      bash -c 'grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$outside_out"
  done

  # The other half of the same hook: the screen is what this fork exists to write, new files and
  # new folders included, and a guard that denied them would leave it unable to build anything.
  for inside in "src/screen.tsx" \
    "$worktree/src/screen.tsx" \
    "$worktree/src/new-screen.tsx" \
    "src/components/card/card.tsx"; do
    inside_out="$(hook_out_at "$tool_hook" "$inside")"
    expect "the hook lets the fork's $tool through at ${inside#"$tmp/"}, a path inside its worktree" \
      bash -c '! grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$inside_out"
  done
done

echo "# skills/do/agents/do-impeccable.md: its Agent tool reaches the end-to-end authors and impeccable's own helpers, and no other agent"

# The Spec has this fork dispatch the end-to-end author for the flows under the Builder's own rule,
# and ADR 0078 has impeccable's helpers forked by it, two layers below the session. The Ticket and
# the skill it loads may carry a stranger's text, so which agents the tool reaches is a hook-level
# guarantee, run live the way the harness runs it before the fork's Agent call.
# shellcheck disable=SC2034  # lib.sh's field reads $out
out="$(frontmatter "$agent" 2>/dev/null)" || out=""
# shellcheck disable=SC2034  # lib.sh's carries reads $flat
flat=" $(field tools | tr ',' ' ' | tr -s ' ') "
carries "the fork holds the Agent tool the dispatch of an author takes" " Agent "

agent_hook="$(hook_command "$agent" Agent)"
# An empty command prints no deny either, so the agents let through below would pass on a
# definition carrying no hook at all.
expect "a PreToolUse hook scopes the fork's Agent tool" test -n "$agent_hook"

# The project's author under a Testing Policy and the one `do` ships for a project with none, then
# the two helpers the impeccable skill forks during new work, under the plain name and under the
# plugin's namespace.
for allowed in e2e-test-author global-e2e-test-author \
  impeccable-finish-reviewer impeccable:impeccable-documenter; do
  allowed_out="$(printf '{"tool_input": {"subagent_type": "%s"}}' "$allowed" |
    sh -c "$agent_hook" 2>/dev/null)"
  expect "the hook lets the fork dispatch $allowed" \
    bash -c '! grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$allowed_out"
done

# No test is written ahead of the screen (ADR 0079), so a unit author has nothing to prove here.
# `general-purpose` holds the tools to fork anything, the way around every other line of the hook,
# and a `do-builder` forked from here would build the screen the Spec handed to impeccable. A call
# naming no agent resolves to `general-purpose`.
for forbidden in unit-test-author global-unit-test-author general-purpose do-builder choice-taker ""; do
  forbidden_out="$(printf '{"tool_input": {"subagent_type": "%s"}}' "$forbidden" |
    sh -c "$agent_hook" 2>/dev/null)"
  expect "the hook denies the fork forking ${forbidden:-an agent it does not name}" \
    bash -c 'grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$forbidden_out"
done

echo "# skills/do/agents/do-impeccable.md: its body runs the impeccable skill unattended and code-led"

# The developer left the run alone: a fork that opens a browser nobody is watching, or asks a
# question nobody is there to answer, hangs with the Ticket claimed and nothing built.
# shellcheck disable=SC2034  # lib.sh's field reads $out
out="$(frontmatter "$agent" 2>/dev/null)" || out=""
expect "the frontmatter grants the Skill tool the body loads the skill through" \
  bash -c 'grep -qE "(^|, *)Skill( *,|$)" <<<"$1"' _ "$(field tools)"

# shellcheck disable=SC2034  # lib.sh's carries_any and carries_each read $flat
flat="$(body_of "$agent" | tr '\n' ' ' | tr -s ' ')"
expect "the definition carries a body below its frontmatter" test -n "$flat"

carries_each "the body tells the fork to load the impeccable skill through the Skill tool" \
  "Skill tool" "\`Skill\` tool" "tool \`Skill\`" \
  -- \
  "oad the impeccable skill" "oad the \`impeccable\` skill" "oad \`impeccable\`" \
  "oads the impeccable skill" "nvoke the impeccable skill" "nvoke the \`impeccable\` skill" \
  "nvoke \`impeccable\`" "all the impeccable skill" "all the \`impeccable\` skill" \
  "with the skill \`impeccable\`" "with \`impeccable\`" "with \`skill: impeccable\`" \
  "with \`skill: \"impeccable\"\`" "the impeccable skill through the" \
  "the \`impeccable\` skill through the" "the impeccable skill with the" \
  "the \`impeccable\` skill with the"

carries_any "the body tells the fork to run the skill unattended" \
  "unattended" "nobody is watching" "no one is watching" "nobody watching" "no human is watching" \
  "nobody is there" "no one is there" "with no one at the keyboard" "with nobody at the keyboard"

carries_any "the body tells the fork to run the skill code-led" \
  "code-led" "code led" "led by the code" "from the code alone" "from the code, never"

carries_any "the body tells the fork never to wait on a browser" \
  "never wait on a browser" "never waits on a browser" "never wait for a browser" \
  "never waits for a browser" "ever wait on a browser" "ever wait on the browser" \
  "never wait on the browser" "never wait for the browser" "not wait on a browser" \
  "not wait for a browser" "never open a browser" "never opens a browser" \
  "never on a browser" "no browser" "without a browser" "nor on a browser" "or on a browser" \
  "neither on a browser" "on a browser nor"

carries_any "the body tells the fork never to wait on an answer or ask a question" \
  "never ask a question" "never asks a question" "ever ask a question" "never ask the developer" \
  "never ask anyone" "never ask anything" "ask no question" "asks no question" \
  "ask nothing" "never ask" "Never ask" "never wait on an answer" "never waits on an answer" \
  "never wait for an answer" "never waits for an answer" "nor on an answer" \
  "nor for an answer" "no question" "not ask"

echo "# skills/do/agents/do-impeccable.md: its body closes each acceptance criterion with one commit quoting it"

# The Reply and a resumed run match commits to the Ticket by the `Behaviour:` line
# (resume-state.sh prints one `behaviour=` line per commit from it): a commit covering two
# criteria, or quoting none, has a resumed fork rebuild a criterion already built or skip one never
# built. The frontmatter's description already names the commit, so only the body is read here.
carries_any "the body has the fork make one commit per acceptance criterion" \
  "ne commit per criterion" "ne commit per acceptance criterion" "ne commit for each criterion" \
  "ne commit for each acceptance criterion" "ne commit for every criterion" "ne commit each" \
  "a commit per criterion" "ne criterion, one commit" "ne commit, one criterion" \
  "ne criterion per commit" "riterion is closed by one commit" "riterion closes with one commit" \
  "riterion closes in one commit" "riterion ends in one commit" "riterion gets one commit" \
  "riterion gets its own commit" "riterion in its own commit" "riterion with one commit" \
  "riterion with a single commit" "riterion by one commit" "ne commit closes each criterion" \
  "ne commit closes a criterion" "ommit once per criterion" "exactly one commit" \
  "a single commit per criterion" "its own commit"

carries_any "the body never lets one commit cover two criteria" \
  "ommit covering two" "ommit covers two" "ommit cover two" "ommit for two criteria" \
  "ommit that covers two" "ommit spanning two" "ommit spans two" "ommit span two" \
  "ommit closes two" "ommit closing two" "ommit close two" "ommit carries two" \
  "ommit carrying two" "ommit holds two" "ommit holding two" "two criteria in one commit" \
  "two criteria into one commit" "two criteria in a single commit" "two criteria in the same commit" \
  "two criteria share a commit" "two criteria never share" "more than one criterion" \
  "ever fold two criteria" "ever batch two criteria" "ever squash two criteria" \
  "ever combine two criteria" "ever merge two criteria" "ever group two criteria"

carries_any "the body never lets the next criterion start with the one before it half-built" \
  "half-built" "half built" "half-done" "half done" "half-finished" "half finished" \
  "partly built" "partially built" "left unfinished" "leave one unfinished" \
  "leave a criterion unfinished" "inish one criterion before" "inish a criterion before" \
  "inish each criterion before" "inish it before" "before you start the next" \
  "before starting the next" "before the next one starts" "before the next starts" \
  "before the next criterion" "before the next one" "before moving to the next" \
  "before you move to the next" "before moving on" "before you move on" \
  "committed before the next" "closed before the next" "built whole before"

# Scoped to the paragraphs naming the line: "verbatim" or "own line" said of anything else in the
# body never answers for the commit's `Behaviour:` line.
# shellcheck disable=SC2034  # lib.sh's carries_each reads $flat
flat="$(paragraph_with <(body_of "$agent") "Behaviour:" all | tr '\n' ' ' | tr -s ' ')"
expect "the body names the commit's Behaviour: line" test -n "$flat"

carries_each "the body puts the Behaviour: line on a line of its own in the commit body, quoting its criterion verbatim" \
  "on a line of its own" "on its own line" "a line of its own" "its own line" "own line" \
  "a line by itself" "alone on a line" "alone on its line" "a separate line" "a line to itself" \
  -- \
  "commit body" "commit's body" "body of the commit" "body of each commit" "body of its commit" \
  "body of that commit" "message body" "message's body" "body of the message" \
  "body of the commit message" "in its body" "in the body" "second \`-m\`" "a second -m" \
  -- \
  "verbatim" "word for word" "character for character" "letter for letter" \
  "exactly as the Ticket" "exactly as written" "exactly as it is written" "exactly as it reads" \
  "as the Ticket writes it" "as the Ticket words it" "unchanged" "unedited"

echo "# skills/do/agents/do-impeccable.md: its body binds the fork to the lines and the one verdict a Builder returns"

# The session routes on the return's first line alone, the way it does for a Builder, and copies
# the lines under it into the Reply unread. A criterion the fork could not build that came back
# under `built` has the Gate run over a half-built screen and the run land it, and a verdict word of
# the fork's own is one the build step has no route for. The description already says "as the
# Builder does", so only the body is read, by the paragraphs naming each piece of the return.
# shellcheck disable=SC2034  # lib.sh's carries and carries_each read $flat
flat="$(paragraph_with <(body_of "$agent") "\`built\`" all | tr '\n' ' ' | tr -s ' ')"
expect "the body names the \`built\` verdict" test -n "$flat"

carries "the body's verdicts are the three the build step routes on" \
  "\`built\`" "\`fork\`" "\`stopped\`"

carries_each "the verdict is the return's first line, alone on it" \
  "first line" "opening line" "line one" "opens with" "opens on" "open with" "open on" \
  -- \
  "alone" "nothing else" "and nothing more" "only the verdict" "by itself" "on its own" \
  "one word" "a single word" "that word only" "the bare verdict"

carries_each "\`built\` is returned only when every criterion carries a commit and nothing is left uncommitted" \
  "only when" "only if" "only once" "unless" "never when" "never while" "never with" \
  -- \
  "every criterion" "each criterion" "all the criteria" "all of the criteria" "all criteria" \
  "every acceptance criterion" "each acceptance criterion" "every one of the criteria" \
  "every line of the checklist" "every checklist line" \
  -- \
  "a commit" "its commit" "one commit" "own commit" "is committed" "are committed" \
  -- \
  "uncommitted" "nothing left to commit" "nothing to commit" "worktree is clean" \
  "clean worktree" "working tree is clean" "clean working tree" "nothing unstaged" \
  "no unstaged" "\`git status\` prints nothing" "\`git status --porcelain\` prints nothing"

# Scoped to the paragraphs naming the returned line, lower case: the commit's own `Behaviour:` line
# is another line, and "verbatim" said of it never answers for what crosses back.
# shellcheck disable=SC2034  # lib.sh's carries_each reads $flat
flat="$(paragraph_with <(body_of "$agent") "behaviour:" all | tr '\n' ' ' | tr -s ' ')"
expect "the body names the return's behaviour: line" test -n "$flat"

carries_each "each criterion closed comes back as a behaviour: line, verbatim, with its commit after \` | \`, paired with a build: line" \
  "verbatim" "word for word" "character for character" "letter for letter" \
  "exactly as the Ticket" "exactly as written" "exactly as it is written" "exactly as it reads" \
  "as the Ticket writes it" "as the Ticket words it" "unchanged" "unedited" \
  -- \
  " | " \
  -- \
  "commit" "sha" "hash" \
  -- \
  "build:"

# shellcheck disable=SC2034  # lib.sh's carries_each reads $flat
flat="$(paragraph_with <(body_of "$agent") "stopped:" all | tr '\n' ' ' | tr -s ' ')"
expect "the body names the return's stopped: line" test -n "$flat"

carries_each "a criterion the fork could not build comes back as \`stopped\`, its reason on the stopped: line" \
  "\`stopped\`" \
  -- \
  "reason" "why" \
  -- \
  "could not build" "cannot build" "can not build" "could not close" "cannot close" \
  "could not be built" "cannot be built" "could not be closed" "cannot be closed" \
  "not built" "unbuilt" "did not build" "never built" "failed to build" "unable to build" \
  "unable to close" "does not hold" "will not hold" "left open" "still open" "no commit" \
  "without a commit" "without its commit"

# shellcheck disable=SC2034  # lib.sh's carries_any reads $flat
flat="$(paragraph_with <(body_of "$agent") "\`fork\`" all | tr '\n' ' ' | tr -s ' ')"
carries_any "two shapes that disagree come back as \`fork\`, never as a build of one of them" \
  "disagree" "two shapes" "Design fork" "design fork" "both sides" "two sides" "contradict" \
  "conflict" "cannot both hold" "can not both hold" "side A"

echo "# skills/do/agents/do-impeccable.md: its body has the flows of the Digest's observable criteria written after the screen, one flow: line each"

# The developer reads the Reply's evidence to tell a proven screen from an unproven one, and the
# only thing that reaches it is the `flow:` lines this fork returns: a screen committed with no
# flow, and no line saying why, reads there exactly like one whose flows ran green. Scoped to the
# paragraphs naming a flow, so "after", "commit" or "by path" said of the build never answers.
# shellcheck disable=SC2034  # lib.sh's carries_each and carries_any read $flat
flat="$(paragraph_with <(body_of "$agent") "flow" all | tr '\n' ' ' | tr -s ' ')"
expect "the body names the flows" test -n "$flat"

carries_each "the flows are written after the screen exists, and no test is written before it" \
  "after the screen exists" "once the screen exists" "when the screen exists" \
  "after the screen is built" "once the screen is built" "after the screen is whole" \
  "after the last criterion is committed" "once the last criterion is committed" \
  "after the last criterion" "once the last criterion" "after every criterion is committed" \
  "once every criterion is committed" "after every criterion carries" \
  "once every criterion carries" "after the screen" \
  -- \
  "red-first" "ahead of the screen" "before the screen" "o test is written before" \
  "o test before" "o test ahead" "ever a test before" "ever a test ahead" \
  "ever write a test before" "ever write a test ahead"

carries_each "the Digest beside the Ticket, read with the Read tool, decides by its Observable criteria section" \
  "Digest" \
  -- \
  "Read tool" "\`Read\` tool" "tool \`Read\`" \
  -- \
  "\`## Observable criteria\`"

carries_each "a criterion the section leaves out gets no flow and says why on its flow: line" \
  "leaves out" "left out" "leaves off" "does not name" "doesn't name" "never names" \
  "not named" "omits" "is absent from" "missing from the section" "outside the section" \
  -- \
  "no flow" "gets none" "get none" "needs none" "none is written" "none is authored" \
  "without a flow" \
  -- \
  "why" "reason"

# Who authors a flow is the Builder's own rule, read off the brief's `Loop:` key: a fork that wrote
# the flow in its own window where an author can be dispatched would ship it with no reuse audit and
# no fix ceiling, and the Reply's evidence would read the same either way.
carries_each "under Loop: policy the project's end-to-end author is dispatched through the Agent tool, one criterion at a time" \
  "\`Loop: policy\`" \
  -- \
  "Agent tool" "\`Agent\` tool" "tool \`Agent\`" \
  -- \
  "\`subagent_type: e2e-test-author\`" "\`e2e-test-author\`" \
  -- \
  "ne criterion at a time" "ne criterion per" "a criterion at a time" "ne at a time" \
  "ne flow at a time" "ach criterion in turn" "nce per criterion" "ne call per criterion" \
  "ne criterion each" "ne dispatch per criterion"

carries_each "under Loop: global the author do ships is dispatched with the Project map the brief names" \
  "\`Loop: global\`" \
  -- \
  "\`subagent_type: global-e2e-test-author\`" "\`global-e2e-test-author\`" \
  -- \
  "\`Project map:\`" "Project map"

carries_each "under Loop: fallback the fork writes the flow itself and says so on a fallback: line" \
  "\`Loop: fallback\`" \
  -- \
  "rite the flow yourself" "rite each flow yourself" "author the flow yourself" \
  "author each flow yourself" "rite it yourself" "author it yourself" \
  -- \
  "\`fallback:\`"

carries_each "a flow has to run green and is committed, staged by path" \
  "\`GREEN\`" \
  -- \
  "ommit" \
  -- \
  "by path"

# The two shapes are read as whole lines of the body's fenced blocks: the session copies the lines
# into the Reply unread, so a shape the prose only describes is one each run words its own way.
# shellcheck disable=SC2034  # lib.sh's check_lines reads $out
out="$(body_of "$agent" | awk '/^ *```/ { fence = !fence; next } fence { sub(/^ */, ""); print }')"
check_lines "the return's flow: line has its two shapes, a commit or the reason no flow was written" 0 0 \
  "flow: <the observable criterion> | <commit>" \
  "flow: <the observable criterion> | no flow: <reason>"

# shellcheck disable=SC2034  # lib.sh's carries_each reads $flat
flat="$(paragraph_with <(body_of "$agent") "flow:" all | tr '\n' ' ' | tr -s ' ')"
expect "the body names the return's flow: line" test -n "$flat"

carries_each "the return carries one flow: line per criterion, after the behaviour: and build: pairs" \
  "ne \`flow:\` line per criterion" "ne \`flow:\` line for each criterion" \
  "ne \`flow:\` line for every criterion" "a \`flow:\` line per criterion" \
  "ne \`flow:\` line each" "ne line per criterion" "ne per criterion" \
  "ach criterion gets one \`flow:\` line" "ach criterion gets its \`flow:\` line" \
  "ach criterion has one \`flow:\` line" "very criterion gets one \`flow:\` line" \
  "very criterion gets its \`flow:\` line" "very criterion has one \`flow:\` line" \
  "its own \`flow:\` line" \
  -- \
  "after the pairs" "after every pair" "after the last pair" "after its pairs" \
  "after your pairs" "below the pairs" "under the pairs" "ollow the pairs" "ollows the pairs" \
  "ollow every pair" "ollow the last pair" "pairs first" "pairs, then" "pairs and then" \
  "after the \`behaviour:\` and \`build:\`" "below the \`behaviour:\` and \`build:\`" \
  "ollow the \`behaviour:\` and \`build:\`" "after the last \`build:\`" "after the \`build:\`" \
  "after every \`build:\`"

echo "# skills/do/references/impeccable.md: the session's copy of the return carries the flow: lines into the Reply"

# The session routes the return by this file and never by the definition: a `flow:` line the
# session's copy does not name is a line it has no rule to copy, and the Reply's evidence loses it.
# shellcheck disable=SC2034  # lib.sh's carries_each reads $flat
flat="$(paragraph_with <(passage_of "$reference" "## The return" "## The return ends") "flow:" all |
  tr '\n' ' ' | tr -s ' ')"
expect "the reference's return names the flow: line" test -n "$flat"

carries_each "the return carries one flow: line per criterion the Digest's Observable criteria names, after the behaviour: and build: lines" \
  "Digest" \
  -- \
  "\`## Observable criteria\`" \
  -- \
  "ne \`flow:\` line per criterion" "ne \`flow:\` line for each criterion" \
  "ne \`flow:\` line for every criterion" "a \`flow:\` line per criterion" \
  "ne \`flow:\` line each" "ne line per criterion" "ne per criterion" \
  "ach criterion gets one \`flow:\` line" "ach criterion gets its \`flow:\` line" \
  "very criterion gets one \`flow:\` line" "very criterion gets its \`flow:\` line" \
  "its own \`flow:\` line" \
  -- \
  "after the \`behaviour:\` and \`build:\`" "below the \`behaviour:\` and \`build:\`" \
  "ollow the \`behaviour:\` and \`build:\`" "ollows the \`behaviour:\` and \`build:\`" \
  "after the pairs" "after every pair" "after the last pair" "below the pairs" \
  "ollow the pairs" "ollows the pairs" "after the last \`build:\`" "after the \`build:\`" \
  "after them" "pairs, then"

carries_each "the flow: line is in the shape builder.md fixes, a commit or the reason no flow was written" \
  "builder.md" \
  -- \
  "commit" \
  -- \
  "reason" "why"

carries_each "the flows are written after the screen exists, by the end-to-end author under the Builder's rule" \
  "after the screen exists" "once the screen exists" "when the screen exists" \
  "after the screen is built" "once the screen is built" "after the screen is whole" \
  "after the last criterion" "once the last criterion" "after every criterion is committed" \
  "once every criterion is committed" "after the screen" \
  -- \
  "end-to-end test author" "end-to-end author" "E2E test author" "E2E author" \
  "e2e test author" "e2e author" \
  -- \
  "\`## The flows\`"

carries_each "the session copies the flow: lines into the Reply's Evidence unchanged" \
  "Reply" \
  -- \
  "Evidence" \
  -- \
  "unchanged" "verbatim" "unedited" "as returned" "as they came back" "as they are" \
  "word for word" "never composed" "never reworded"

echo "# skills/do/agents/do-impeccable.md: its body returns one fallback: line in a project with no end-to-end command"

# A project with no end-to-end suite has nothing to run a flow with. A return that said nothing
# about it would reach the Reply reading like a screen whose flows were simply not needed, and the
# developer would take the evidence as covering what it does not. The sentence that places the line
# may sit beside the fenced block rather than in the paragraph that names the condition, so both
# are read.
# shellcheck disable=SC2034  # lib.sh's carries_each reads $flat
flat="$({
  paragraph_with <(body_of "$agent") "end-to-end command" all
  paragraph_with <(body_of "$agent") "fallback:" all
} | tr '\n' ' ' | tr -s ' ')"
expect "the body names a project with no end-to-end command" \
  bash -c 'grep -qF "no end-to-end command" <<<"$1"' _ "$flat"

carries_each "the project's Testing Policy, by its Project facts, says whether there is an end-to-end command" \
  "Testing Policy" \
  -- \
  "Project facts"

carries_each "with no end-to-end command no flow is written and no author is called" \
  "no end-to-end command" \
  -- \
  "no flow is written" "o flow is written" "rite no flow" "rites no flow" "no flow written" \
  "gets no flow" "get no flow" "no flow at all" "without writing a flow" "rite none" \
  "none is written" "no flow gets written" \
  -- \
  "no author is called" "o author is called" "all no author" "alls no author" \
  "no author called" "never call the author" "not call the author" "author is not called" \
  "author is never called" "without calling the author" "nor is the author called" \
  "nor call the author" "no end-to-end author" "no end-to-end test author" "no test author" \
  "not call \`test-author\`" "never call \`test-author\`" "no \`test-author\`" \
  "nvoke no author" "oad no author" "no call to the author" "and no author" \
  "not load \`test-author\`" "never load \`test-author\`"

# shellcheck disable=SC2034  # lib.sh's check_lines reads $out
out="$(body_of "$agent" | awk '/^ *```/ { fence = !fence; next } fence { sub(/^ */, ""); print }')"
check_lines "the return's fallback: line is a whole line of a fenced block, in its one fixed wording" 0 0 \
  "fallback: no end-to-end command in the project"

carries_each "the fallback: line stands in place of the flow: lines" \
  "fallback:" \
  -- \
  "in place of the \`flow:\` line" "in their place" "in place of" "nstead of the \`flow:\` line" \
  "nstead of" "eplaces the \`flow:\` line" "eplaces them" "eplace the \`flow:\` line" \
  "no \`flow:\` line" "o \`flow:\` line" "stands in for" "stand in for" \
  "takes the place of" "takes their place" "rather than the \`flow:\` line" \
  -- \
  "\`flow:\`"

echo "# skills/do/references/impeccable.md: the session's copy of the return has a fallback: line put one line in the Reply"

# The session writes the Reply by this file: a `fallback:` line it has no rule for is dropped, and
# the Reply's evidence then reads as if flows had covered the screen.
# shellcheck disable=SC2034  # lib.sh's carries_each reads $flat
flat="$(paragraph_with <(passage_of "$reference" "## The return" "## The return ends") "fallback:" all |
  tr '\n' ' ' | tr -s ' ')"
expect "the reference's return names the fallback: line" test -n "$flat"

carries_each "the fallback: line comes back in a project with no end-to-end command, in place of the flow: lines" \
  "no end-to-end command in the project" \
  -- \
  "in place of the \`flow:\` line" "in their place" "in place of" "nstead of the \`flow:\` line" \
  "nstead of" "eplaces the \`flow:\` line" "eplaces them" "eplace the \`flow:\` line" \
  "no \`flow:\` line" "o \`flow:\` line" "stands in for" "stand in for" \
  "takes the place of" "takes their place" "rather than the \`flow:\` line" \
  -- \
  "\`flow:\`"

mapfile -t no_flow_proof < <(no_flow_proof_groups)
carries_each "the session then writes one line in the Reply: no flow covered the screen, the detector scan and the Gate are its proof" \
  "Reply" -- "${no_flow_proof[@]}"

echo "# skills/do/agents/do-impeccable.md: its body runs the detector scan by script, fixes what it reports and returns a scan: line with one finding: line per finding left"

# The session writes the Reply's evidence from the return and has no other source for the scan: a
# scan judged by eye, or one whose findings stay in the fork's window, reaches the Reply as a screen
# the detector cleared. Scoped to the paragraphs naming the detector or its two returned lines, so
# "by path", "before you return" or `built` said of the build or the flows never answers.
# shellcheck disable=SC2034  # lib.sh's carries_each reads $flat
flat="$({
  paragraph_with <(body_of "$agent") "detector" all
  paragraph_with <(body_of "$agent") "scan:" all
  paragraph_with <(body_of "$agent") "finding:" all
} | tr '\n' ' ' | tr -s ' ')"
expect "the body names the detector scan" test -n "$flat"

one_finding_line_each=(
  "ne \`finding:\` line per finding" "ne \`finding:\` line for each finding"
  "ne \`finding:\` line for every finding" "a \`finding:\` line per finding"
  "a \`finding:\` line for each finding" "a \`finding:\` line for every finding"
  "ne \`finding:\` line each" "ne line per finding" "ne per finding"
  "ach finding left gets one \`finding:\` line" "ach finding left gets its \`finding:\` line"
  "ach finding that remains gets one \`finding:\` line"
  "ach finding that remains gets its \`finding:\` line" "its own \`finding:\` line"
)

carries_each "after the flows, the fork runs the impeccable skill's detector scan by script, with the Bash tool from the worktree" \
  "detector" \
  -- \
  "fter the flows" "nce the flows" "fter the screen and its flows" "fter the last flow" \
  "nce the last flow" "fter every flow" "nce every flow" "ast before the return" \
  "ast before you return" "ast thing before" "ast step before" \
  -- \
  "impeccable skill" \
  -- \
  "command" \
  -- \
  "Bash tool" "with Bash" "through Bash" \
  -- \
  "worktree"

carries_each "the scan is never judged by eye and never skipped" \
  "by eye" "eyeball" "by reading the code" "by looking at" "from memory" \
  -- \
  "never skip" "ever skipped" "skip it" "no run skips" "skips it" "not skipped" \
  "never left out" "never leave it out" "every run" "on every stretch"

carries_each "the fork fixes what the scan reports and runs it again before it returns, the fixes committed staged by path" \
  "ix what" "ixes what" "ix every finding" "ix each finding" "ix the findings" \
  "ix all" "ix whatever" "ix everything" "ix them" \
  -- \
  "can again" "un it again" "un again" "erun" "e-run" "a second scan" "can once more" \
  "un it once more" \
  -- \
  "before you return" "before returning" "before it returns" "before the return" \
  "before your return" \
  -- \
  "by path"

carries_each "a finding the fork could not fix is returned under \`built\` and never stops the build" \
  "\`built\`" \
  -- \
  "could not fix" "cannot fix" "can't fix" "did not fix" "left unfixed" "not fixed" \
  "that remain" "still remain" "left over" \
  -- \
  "never turn" "no reason to stop" "not a reason to stop" "never a reason to stop" \
  "does not stop" "do not stop" "never stop" "is no stop" "still \`built\`" "stays \`built\`" \
  "remains \`built\`" "never \`stopped\`" "not \`stopped\`" "never end your stretch" \
  "does not end your stretch" "do not end your stretch"

# shellcheck disable=SC2034  # lib.sh's check_lines reads $out
out="$(body_of "$agent" | awk '/^ *```/ { fence = !fence; next } fence { sub(/^ */, ""); print }')"
check_lines "the return's scan: and finding: lines are whole lines of a fenced block, in their two fixed shapes" 0 0 \
  "scan: <the command line as it was run> | <n> findings remain" \
  "finding: <file:line> | <the rule the detector names> | <what it reports, in one line>"

carries_each "the return always carries one scan: line, \`0 findings remain\` included, after the flow: lines" \
  "ne \`scan:\` line" "a \`scan:\` line" "the \`scan:\` line" \
  -- \
  "always" "very return" "very \`built\` return" "whatever the count" "even when" "even at" \
  "even with" \
  -- \
  "0 findings remain" \
  -- \
  "fter the \`flow:\` line" "ollows the \`flow:\` line" "ollow the \`flow:\` line" \
  "elow the \`flow:\` line" "nder the \`flow:\` line" "fter the \`fallback:\` line" \
  "ollows the \`fallback:\` line" "fter the lines of the proof" "ollows the lines of the proof" \
  "ollow the lines of the proof"

carries_each "the return carries exactly as many finding: lines as the count on the scan: line, one per finding left, none at \`0\`" \
  "${one_finding_line_each[@]}" \
  -- \
  "as many" "same number" "the count on the \`scan:\` line" "the count the \`scan:\` line" \
  "matches the count" "match the count" "equals the count" "equal the count" \
  "equal to the count" \
  -- \
  "none when" "none at" "none on" "none under" "none with" "and none" \
  "no \`finding:\` line" "o \`finding:\` line"

carries_each "the scan's own output never crosses back, only those lines" \
  "scan's own output" "scan's output" "detector's own output" "detector's output" \
  "output of the scan" "output of the detector" "what the scan printed" \
  "what the scan prints" "what the detector printed" "what the detector prints" \
  -- \
  "never" "nothing else" "only those lines" "only these lines"

echo "# skills/do/references/impeccable.md: the session's copy of the return carries the scan: and finding: lines into the Reply"

# The session routes the return by this file: a `scan:` or a `finding:` line it has no rule for is
# dropped, and the Reply then says nothing of a finding the developer still has to clear.
# shellcheck disable=SC2034  # lib.sh's carries_each reads $flat
flat="$(paragraph_with <(passage_of "$reference" "## The return" "## The return ends") "scan:" all |
  tr '\n' ' ' | tr -s ' ')"
expect "the reference's return names the scan: line" test -n "$flat"

carries_each "the return carries one scan: line, the command line as it was run and the count of findings that remain, and one finding: line per finding left" \
  "ne \`scan:\` line" "a \`scan:\` line" \
  -- \
  "command line" "command as it was run" "command as it ran" "command it ran" \
  "command the fork ran" \
  -- \
  "findings that remain" "findings remain" "findings left" "findings still" \
  -- \
  "${one_finding_line_each[@]}"

carries_each "the scan is the fork's to run and the session never runs the detector" \
  "the fork's" "fork runs" "run by the fork" "fork ran" \
  -- \
  "session never runs" "never the session" "session runs no" "session does not run" \
  "not the session's" "session never ran" "session runs none" \
  -- \
  "detector"

carries_each "findings that remain come back under \`built\` and do not stop the run" \
  "\`built\`" \
  -- \
  "that remain" "still remain" "left over" "findings left" "could not fix" "not fixed" \
  -- \
  "do not stop" "does not stop" "never stop" "no reason to stop" "not a reason to stop" \
  "never a reason to stop" "is no stop" "never turn" "still lands" "lands all the same" \
  "lands anyway" "lands regardless"

carries_each "the session copies the scan: line into the Reply's Evidence and each finding: line into its Pending debt" \
  "copies" "copy" "copied" \
  -- \
  "\`scan:\`" \
  -- \
  "Evidence" \
  -- \
  "\`finding:\`" \
  -- \
  "Pending debt"

echo "# skills/do/agents/do-impeccable.md: its body returns one no scan: line when the skill has no detector for the platform or the detector crashes"

# The impeccable skill's detector is web-only and a detector can crash: a fork bound to a `scan:`
# line it has no command and no count for invents one, which reaches the Reply as a scan that ran,
# or stops on a screen it built. The sentence that places the line may sit beside the fenced block
# rather than in the paragraph that names the condition, so both are read.
in_place_of_scan=(
  "in place of the \`scan:\` line" "in its place" "nstead of the \`scan:\` line"
  "eplaces the \`scan:\` line" "eplace the \`scan:\` line" "stands in for the \`scan:\` line"
  "takes the place of the \`scan:\` line" "takes its place" "rather than the \`scan:\` line"
)
no_detector_for_platform=(
  "no detector for" "names no detector" "name no detector" "has no detector" "names none for"
  "no detector that" "without a detector"
)
detector_crashed=("crash")

# shellcheck disable=SC2034  # lib.sh's carries_each reads $flat
flat="$({
  paragraph_with <(body_of "$agent") "no scan:" all
  paragraph_with <(body_of "$agent") "no detector" all
} | tr '\n' ' ' | tr -s ' ')"
expect "the body names the return's no scan: line" \
  bash -c 'grep -qF "no scan:" <<<"$1"' _ "$flat"

# shellcheck disable=SC2034  # lib.sh's check_lines reads $out
out="$(body_of "$agent" | awk '/^ *```/ { fence = !fence; next } fence { sub(/^ */, ""); print }')"
check_lines "the return's no scan: line is a whole line of a fenced block, in its one fixed wording" 0 0 \
  "no scan: <the reason, in one line>"

carries_each "with no detector for the project's platform, or a detector that crashes, the no scan: line stands in place of the scan: line" \
  "no scan:" \
  -- \
  "${no_detector_for_platform[@]}" \
  -- \
  "platform" \
  -- \
  "${detector_crashed[@]}" \
  -- \
  "${in_place_of_scan[@]}"

carries_each "no finding: line comes with the no scan: line" \
  "no scan:" \
  -- \
  "no \`finding:\` line" "o \`finding:\` line" "without a \`finding:\` line" \
  "without any \`finding:\` line" "nor any \`finding:\` line" "never a \`finding:\` line"

carries_each "a scan that could not run is returned under \`built\` and never as \`stopped\`" \
  "no scan:" \
  -- \
  "\`built\`" \
  -- \
  "never \`stopped\`" "not \`stopped\`" "never as \`stopped\`" "not as \`stopped\`" \
  "still \`built\`" "stays \`built\`" "remains \`built\`" "never stop" "does not stop" \
  "do not stop" "no reason to stop" "not a reason to stop" "never a reason to stop" \
  "never turn"

echo "# skills/do/references/impeccable.md: the session's copy of the return carries the no scan: line into the Reply"

# The session routes the return by this file: a `no scan:` line it has no rule for is dropped, and
# the Reply's evidence then says nothing of a screen the detector never read.
# shellcheck disable=SC2034  # lib.sh's carries_each reads $flat
flat="$(paragraph_with <(passage_of "$reference" "## The return" "## The return ends") "no scan:" all |
  tr '\n' ' ' | tr -s ' ')"
expect "the reference's return names the no scan: line" test -n "$flat"

carries_each "the no scan: line comes back in place of the scan: line, with no detector for the platform or a detector that crashed" \
  "${no_detector_for_platform[@]}" \
  -- \
  "platform" \
  -- \
  "${detector_crashed[@]}" \
  -- \
  "${in_place_of_scan[@]}"

carries_each "the session copies the no scan: line into the Reply's Evidence" \
  "copies" "copy" "copied" \
  -- \
  "Reply" \
  -- \
  "Evidence"

echo "# skills/do/references/reply.md: the proof of an impeccable screen carries the no scan: line"

# The developer reads Evidence to tell a scanned screen from an unscanned one: a Reply with no rule
# for the line shows neither a count nor the reason there is none.
reply="$here/../references/reply.md"
# shellcheck disable=SC2034  # lib.sh's carries_each reads $flat
flat="$(bullets_opening_on "$reply" "The proof of an impeccable screen")"
expect "the Evidence item carries the proof of an impeccable screen" test -n "$flat"

carries_each "the no scan: line is copied unchanged into Evidence in place of the scan: line, with its reason" \
  "\`no scan:\`" \
  -- \
  "${in_place_of_scan[@]}" \
  -- \
  "unchanged" "verbatim" "unedited" "as returned" "as it came back" "word for word" \
  -- \
  "reason" "why"

exit "$((fails > 0))"
