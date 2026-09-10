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
has "the skill file carries its keys and the arguments" "$skill_md" \
  "name: sketch" "argument-hint:" '$ARGUMENTS'
has "the skill is user-invoked in Claude Code" "$skill_md" "disable-model-invocation: true"
frontmatter="$(awk '/^---$/ { c++; next } c == 1' "$skill_md" 2>/dev/null)"
expect "a typed /sketch runs in the developer's session: no fork context in the frontmatter" \
  test -z "$(grep -E '^context: *fork' <<<"$frontmatter")"
expect "a typed /sketch runs in the developer's session: no agent key in the frontmatter" \
  test -z "$(grep -E '^agent:' <<<"$frontmatter")"
has "the typed door calls the agent through the Agent tool" "$skill_md" "subagent_type: sketch"

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

# The agent can only read and search, so it has no shell to `cat` through the install link, and the
# Read tool collapses the `..` before it follows that link. Its brief hands it the chain's `.agents/`
# folder as an absolute path instead, and both callers fill that part.
expect "the agent is granted reading and search and no other tool" \
  test "$(sed -n 's/^tools: //p' "$agent_md" 2>/dev/null)" = "Read, Glob, Grep"
lacks "the agent has no write tool, no edit tool and no shell" "$agent_md" "Write" "Edit" "Bash"
has "the brief names the chain's .agents/ folder" "$agent_md" "the chain's \`.agents/\` folder"
expect "the brief's .agents/ part is an absolute path the agent names as <agents-dir>" \
  grep -qE "^\| the chain's \`\.agents/\` folder \|.*absolute path.*\`<agents-dir>\`" "$agent_md"
has "the agent reads the format and the principles with the Read tool" "$agent_md" \
  "with the Read tool"
lacks "the agent reaches nothing through the install link, with cat, or around the Read tool" \
  "$agent_md" "readlink -f ~/.claude/skills/sketch" "\`cat\`" "never with the Read tool"
ordered "the typed door fills the chain's .agents/ folder in the brief it forks with" "$skill_md" \
  "## 3. The shape" "the chain's \`.agents/\` folder" "## 4. The ignore"
ordered "do's shape step fills the chain's .agents/ folder in the brief it forks with" \
  "$repo/skills/do/references/ticket.md" \
  "The brief is the one the \`sketch\` agent fixes" "the chain's \`.agents/\` folder" \
  "Before it forks, the destination the brief names"

# The Sketch it writes, and the line it stops at. The format lives with the formats two skills share,
# since `do` writes a Sketch too when the Agent tool is withheld. The agent names it under the
# brief's `.agents/` folder, so the path is read off the agent and resolved under this repository's
# `.agents/`, the folder a caller hands over, rather than looked up at a path the test assumes.
named="$(grep -o '<agents-dir>/formats/[a-z0-9-]*\.md' "$agent_md" | head -n 1)"
format="$repo/.agents/${named#'<agents-dir>/'}"
expect "the format the agent names is a file under the brief's .agents/ folder" test -f "$format"
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

has "the agent stops at the Sketch and names the format under the brief's .agents/ folder" \
  "$agent_md" "## The Sketch" "<agents-dir>/formats/sketch-format.md"
lacks "the agent names no copy of the format in the skill's own folder" "$agent_md" \
  "references/sketch-format.md"
has "the agent names the principles under the brief's .agents/ folder" "$agent_md" \
  "<agents-dir>/principles/exhaust-the-design-space.md" \
  "<agents-dir>/principles/boundary-discipline.md"
expect "the first principle the agent names is a file" \
  test -f "$repo/.agents/principles/exhaust-the-design-space.md"
expect "the second principle the agent names is a file" \
  test -f "$repo/.agents/principles/boundary-discipline.md"
lacks "the agent names no path that resolves from this repository only" "$agent_md" \
  "](references/" "](../../.agents/"
has "the agent implements nothing" "$agent_md" \
  "## What you never do" "No implementation" "No test" "No commit" \
  "every test still goes through a test author"

# Where a typed /sketch files the Sketch, and what comes back. The session owns the destination, the
# containment check and the ignore probe; the agent returns the Sketch's text and writes nothing.
has "the typed door resolves the Feature folder through the shared resolver" "$skill_md" \
  "/../../.agents/scripts/resolve-feature-folder.sh"
resolver="$(grep -o '\.\./\.\./\.agents/scripts/[a-z0-9-]*\.sh' "$skill_md" 2>/dev/null | head -n 1)"
resolver="${resolver#../../}"
expect "the resolver the typed door names is on disk and runnable" \
  test -x "$repo/${resolver:-none.sh}"
has "the typed door files the Sketch in the Feature folder, or under sketches when none resolves" \
  "$skill_md" "sketch.md" ".scratch/sketches/"
has "the destination is composed from the resolver's own keys" "$skill_md" "slug=" "root="
has "a resolver exit other than 0 stops the run, and a missing script is found by testing for it" \
  "$skill_md" "exit 0" "any other exit" "test -f"
has "a destination that does not resolve under the Scratch is refused" "$skill_md" \
  "readlink -m" 'case "$dest" in "$scratch"/*)' "refused"
has "the typed door probes the scratch ignore and appends it to .gitignore when owed" "$skill_md" \
  "git check-ignore -v .scratch/" ">> .gitignore"
has "the typed door ends with the Sketch's location and the shape in one line" "$skill_md" \
  "the Sketch's location" "the shape in one line"
lacks "the agent carries no destination, containment or ignore step" "$agent_md" \
  "## Where the Sketch goes" "resolve-feature-folder.sh" "readlink -m" 'case "$dest" in' \
  "git check-ignore" ">> .gitignore"
has "the agent returns the shape in one line" "$agent_md" "## Your return" "the shape in one line"

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
