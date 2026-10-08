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

exit "$((fails > 0))"
