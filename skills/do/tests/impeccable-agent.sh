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

exit "$((fails > 0))"
