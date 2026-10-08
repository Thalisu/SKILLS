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

carries_each "the project's end-to-end author writes each flow, through the Skill tool with test-author and e2e, one criterion at a time" \
  "end-to-end test author" "end-to-end author" "E2E test author" "E2E author" \
  "e2e test author" "e2e author" \
  -- \
  "Skill tool" "\`Skill\` tool" "tool \`Skill\`" \
  -- \
  "\`test-author\`" "\`/test-author\`" "\`test-author e2e\`" "\`/test-author e2e\`" \
  "\`skill: test-author\`" "\`skill: \"test-author\"\`" \
  -- \
  "\`e2e\`" "\`test-author e2e\`" "\`/test-author e2e\`" "\`args: e2e\`" "\`args: \"e2e\"\`" \
  -- \
  "ne criterion at a time" "ne criterion per" "a criterion at a time" "ne at a time" \
  "ne flow at a time" "ach criterion in turn" "nce per criterion" "ne call per criterion" \
  "ne criterion each"

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

exit "$((fails > 0))"
