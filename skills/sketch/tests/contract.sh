#!/usr/bin/env bash
# contract.sh: the static contract of the sketch skill, checked against the files on disk so a
# reviewer can rerun it: the skill file and its Codex metadata, the agent definition and the
# callers its description names, the Sketch format, the docs page, the README rows, the invocation
# contract's rows, and no em-dash in any prose the skill adds.
# Run: bash skills/sketch/tests/contract.sh
# shellcheck disable=SC2016
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
repo="$(cd "$here/../../.." && pwd -P)"
skill="$repo/skills/sketch"
fails=0

# The skill file: user-invoked in Claude Code, forked onto its own agent.
skill_md="$skill/SKILL.md"
has "the skill file carries its fork keys" "$skill_md" \
  "name: sketch" "context: fork" "agent: sketch" "background: false" "argument-hint:" '$ARGUMENTS'
has "the skill is user-invoked in Claude Code" "$skill_md" "disable-model-invocation: true"
expect "the body is one instruction line plus the arguments" \
  test "$(awk '/^---$/ { c++; next } c == 2 && NF { n++ } END { print n }' "$skill_md" 2>/dev/null)" = 2

# The Codex half of the same choice.
codex="$skill/agents/openai.yaml"
has "the Codex metadata carries the interface" "$codex" "display_name:" "short_description:"
has "the Codex metadata closes implicit invocation" "$codex" \
  "policy:" "allow_implicit_invocation: false"

# The agent definition: the second door, gated by the callers its description names.
agent_md="$skill/AGENT.md"
has "the agent carries its frontmatter" "$agent_md" "name: sketch" "model: opus"
has "the agent description names its only callers" "$agent_md" \
  "Invoke through /sketch" "do at its shape step" "the developer and do are its only callers" \
  "Never on your own initiative."

# What it is handed, and what it never reads twice.
has "the brief names every part the caller hands over" "$agent_md" \
  "## The brief" "what to shape" "the map" "the Digest" "the repository root" "where the Sketch goes"
has "the agent grounds the subsystem no second time" "$agent_md" \
  "You ground nothing a second time" "the map is the subsystem"
has "a missing part of the brief is named and never re-derived by exploring" "$agent_md" \
  "A brief that names no map"

# It explores the rivals itself, and depends on no skill this repository does not carry.
has "the agent explores rival shapes in its own window" "$agent_md" \
  "## The rivals" "two structurally different" "rejected"
lacks "the agent calls no skill this repository does not carry" "$agent_md" \
  "arena" "interrogate" "Skill tool"

# The Sketch it writes, and the line it stops at. The format lives with the formats two skills share,
# since `do` writes a Sketch too when the Agent tool is withheld, and the agent reaches it through the
# link the install leaves. So the path is read off the agent and resolved from the skill's folder,
# where `readlink -f ~/.claude/skills/sketch` lands, rather than looked up at a path only this
# repository has.
named="$(grep -o '\$(readlink -f ~/\.claude/skills/sketch)/\.\./\.\./\.agents/formats/[a-z0-9-]*\.md' "$agent_md" | head -n 1)"
format="$skill/${named#'$(readlink -f ~/.claude/skills/sketch)/'}"
expect "the format the agent names is a file, at the path the install gives it" test -f "$format"
expect "the format lives with the formats the chain shares" \
  test "$(cd "$(dirname "$format")" 2>/dev/null && pwd -P)" = "$repo/.agents/formats"
expect "no second copy of the format stays in the skill's own folder" \
  test ! -e "$skill/references/sketch-format.md"
has "the formats index carries the Sketch format's row, with both writers" \
  "$repo/.agents/formats/README.md" "| [sketch-format.md](sketch-format.md) | \`sketch\`; \`do\`"
has "the format opens with its title" "$format" "# Sketch format"
ordered "the format's sections come in the fixed order" "$format" \
  "## Header" "## The caller's usage" "## The types" "## The signatures" "## The boundaries" \
  "## Rejected rivals" "## Rules"
has "the header names its keys" "$format" "Shapes:" "Map:" "Digest:" "Written:"
has "every body is unimplemented" "$format" "not implemented"
has "a rejected rival is one line with the fact that killed it" "$format" \
  "one line" "the fact that killed it"
has "a section with nothing to say reads none" "$format" "reads \`none\`"

has "the agent stops at the Sketch and names the format at its installed path" "$agent_md" \
  "## The Sketch" '$(readlink -f ~/.claude/skills/sketch)/../../.agents/formats/sketch-format.md' \
  "always write" "always name"
lacks "the agent names no copy of the format in the skill's own folder" "$agent_md" \
  "references/sketch-format.md"
has "the agent reaches the principles through the link the install leaves" "$agent_md" \
  '$(readlink -f ~/.claude/skills/sketch)/../../.agents/principles/exhaust-the-design-space.md' \
  '$(readlink -f ~/.claude/skills/sketch)/../../.agents/principles/boundary-discipline.md'
expect "the first principle the agent names is a file" \
  test -f "$repo/.agents/principles/exhaust-the-design-space.md"
expect "the second principle the agent names is a file" \
  test -f "$repo/.agents/principles/boundary-discipline.md"
lacks "the agent names no path that resolves from this repository only" "$agent_md" \
  "](references/" "](../../.agents/"
has "the agent implements nothing" "$agent_md" \
  "## What you never do" "No implementation" "No test" "No commit" \
  "every test still goes through a test author"
expect "the agent is granted these tools and no other" \
  test "$(awk -F'tools: *' '/^tools: /{ print $2; exit }' "$agent_md")" = "Read, Glob, Grep, Bash, Write"

# Where the Sketch goes at each door, and what comes back.
has "the agent names both doors and the path each writes to" "$agent_md" \
  "## Where the Sketch goes" "the path the brief names" "resolve-feature-folder.sh" \
  "sketch.md" ".scratch/sketches/" "absolute"
has "the standalone door derives a slug when the developer passes none" "$agent_md" \
  "the slug the developer passes" "derive one from the argument"
has "the destination is composed from the resolver's own keys and never a raw slug" "$agent_md" \
  "It prints \`slug=\`" "are the \`slug=\` and the \`root=\`" \
  "never the word the developer typed"
has "a destination that does not resolve under the Scratch is refused and nothing is written" \
  "$agent_md" "readlink -m" 'case "$dest" in' "refused\` ends the run" "write nothing"
has "the agent appends the scratch ignore before it writes" "$agent_md" \
  "git check-ignore -v .scratch/" ".gitignore"
has "a resolver exit other than 0 stops the run on the resolver's own reason" "$agent_md" \
  "The script's exit decides the run" "any other exit" "stop. Write nothing" \
  "the script's own stderr line"
has "the absent-script degrade is reached by testing for the file, never by an empty stdout" \
  "$agent_md" "\`test -f\` does not find the script" "never infer the last row from an empty"
has "the return names the location and the shape" "$agent_md" \
  "## Your return" "the Sketch's location" "the shape in one line"
has "the agent reaches the resolver through the link the install leaves" "$agent_md" \
  '$(readlink -f ~/.claude/skills/sketch)/../../.agents/scripts/resolve-feature-folder.sh'
resolver="$(grep -o '\.\./\.\./\.agents/scripts/[a-z0-9-]*\.sh' "$agent_md" | head -n 1)"
resolver="${resolver#../../}"
expect "the resolver the agent names is on disk and runnable" \
  test -x "$repo/${resolver:-none.sh}"

# The docs page, per .agents/writing-docs.md.
page="$repo/docs/sketch.md"
expect "the docs page opens with the skill's name" test "$(head -n 1 "$page" 2>/dev/null)" = "# sketch"
ordered "the docs page keeps the contract's section order" "$page" \
  "## What it does" "## When to reach for it" "## Prerequisites" "## Common questions" \
  "## It's working if" "## Where it fits"
has "the docs page states the invocation mode of a user-invoked skill" "$page" \
  'You invoke this by typing `/sketch`, and the agent will not reach for it on its own.'
has "the docs page surfaces the leading word" "$page" "Sketch" "rejected rival"
has "the docs page points at the top-level README as the map" "$page" \
  "[the top-level README](../README.md)"
lacks "the docs page carries no install command" "$page" "ln -s" "git clone"
links_ok=1
while read -r target; do
  target="${target%%#*}"
  [ -n "$target" ] || continue
  case "$target" in http*) continue ;; esac
  [ -e "$repo/docs/$target" ] || {
    echo "      unresolved link: $target"
    links_ok=0
  }
done < <(grep -o '](\([^)]*\))' "$page" 2>/dev/null | sed 's/^](//; s/)$//')
expect "every link on the docs page resolves from docs/" test "$links_ok" = 1

# The rows the repository keeps in step with the skills on disk. The top-level README's tables are
# column-aligned, so a pin on its cells allows any padding.
ordered "the top-level README lists the skill under User-invoked" "$repo/README.md" \
  "## User-invoked" "| [\`sketch\`](skills/sketch/SKILL.md)" "## Model-invoked"
expect "the top-level README's \`sketch\` row carries the page link in its own docs cell" \
  grep -qE "^\| \[\`sketch\`\]\(skills/sketch/SKILL\.md\) +\|.*\[docs/sketch\.md\]\(docs/sketch\.md\)" "$repo/README.md"
expect "the top-level README names the agent the install links" \
  grep -qE "^\| \`sketch\` +\| \`sketch\`, forked by \`/sketch\`" "$repo/README.md"
ordered "the skills README lists the skill under User-invoked" "$repo/skills/README.md" \
  "## User-invoked" "| [\`sketch\`](sketch/SKILL.md) |" "## Model-invoked"
has "the invocation contract names the skill as user-invoked" "$repo/.agents/invocation.md" \
  "\`journey\`, \`do\` and \`sketch\` are user-invoked"
has "the invocation contract's table gains the agent row" "$repo/.agents/invocation.md" \
  "| \`sketch\` | user-invoked |"

# A page names a caller of the agent only once that caller's step is in the tree, per
# .agents/invocation.md: the step and the claim land in the same change.
if grep -rqF -- "subagent_type: sketch" "$repo/skills/do" 2>/dev/null; then
  has "the pages name do, whose shape step forks the agent" "$repo/README.md" \
    "and by \`do\` at its shape step"
  has "the docs page names do, whose shape step forks the agent" "$page" \
    "whose shape step calls this one"
else
  lacks "the top-level README names no caller the tree does not carry" "$repo/README.md" \
    "and by \`do\` at its shape step"
  lacks "the docs page names no caller the tree does not carry" "$page" \
    "\`do\` reaches it too" "whose shape step calls this one" "\`do\` calls it at its shape step" \
    "\`do\` reaches the agent it ships instead"
fi

# The script says how it is run, since this repository has no aggregate runner.
expect "the header carries the invocation line" \
  grep -qF "Run: bash skills/sketch/tests/contract.sh" "$here/contract.sh"

# No em-dash in any prose the skill adds.
prose=("$skill_md" "$agent_md" "$codex" "$format" "$page" "$here/contract.sh")
for f in "${prose[@]}"; do
  [ -f "$f" ] || continue
  if grep -q $'\xe2\x80\x94' "$f"; then
    echo "FAIL  no em-dash in ${f#"$repo/"}"
    fails=$((fails + 1))
  else echo "ok    no em-dash in ${f#"$repo/"}"; fi
done

if [ "$fails" = 0 ]; then echo "PASS"; else
  echo "$fails failing"
  exit 1
fi
