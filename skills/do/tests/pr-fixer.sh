#!/usr/bin/env bash
# pr-fixer.sh: the agent the `pr` Playbook forks to fix a red check, `do-pr-fixer`. A pull request's
# head may be shared, and ADR 0086 keeps the session's one fast-forward push as the only write to
# it: a fixer that pushes, pulls, moves a ref, switches branch, opens a worktree or reaches GitHub
# through `gh` makes a write the session never vouched for. The guarantee is the agent's own hooks,
# run live the way the harness runs them, since the fixer reads a check's log a stranger can write
# into. And the agent is listed wherever the repo lists what `do` ships, so the installer's links
# and the developer's docs name it.
# Run: bash skills/do/tests/pr-fixer.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
root="$here/../../.."
agent="$here/../agents/do-pr-fixer.md"
fails=0

deny_in() { grep -qF '"permissionDecision": "deny"' <<<"$1"; }

echo "# skills/do/agents/do-pr-fixer.md: the name, tier and hooks the pr Playbook forks"

# shellcheck disable=SC2034  # lib.sh's field reads $out
out="$(frontmatter "$agent" 2>/dev/null)" || out=""
expect "the fixer's frontmatter names it do-pr-fixer" test "$(field name)" = "do-pr-fixer"
expect "the fixer runs on sonnet" test "$(field model)" = "sonnet"
expect "the fixer runs at effort high" test "$(field effort)" = "high"

bash_hook="$(hook_command "$agent" Bash 2>/dev/null)"
expect "a PreToolUse hook scopes the fixer's Bash" test -n "$bash_hook"

bash_out() { # $1 the command: the Bash hook's output on that payload
  jq -n --arg c "$1" '{tool_input: {command: $c}}' 2>/dev/null | sh -c "$bash_hook" 2>/dev/null
}

for cmd in \
  "git push origin HEAD" \
  "git pull" \
  "git fetch origin" \
  "git rebase main" \
  "git merge origin/main" \
  "git checkout main" \
  "git switch main" \
  "git worktree add ../x" \
  "git worktree list" \
  "git update-ref refs/heads/main HEAD" \
  "git symbolic-ref HEAD refs/heads/main" \
  "git branch -f main HEAD" \
  "git -C /t push origin HEAD" \
  "git -C /t fetch origin" \
  "git -C /t checkout main" \
  "git -C /t worktree add ../x" \
  "cd /t && git push" \
  "cd /t && git rebase main" \
  "cd /t && git update-ref refs/heads/main HEAD" \
  "gh run rerun 7" \
  "gh pr view 42" \
  "cd /t && gh api x"; do
  expect "the hook denies the fixer's Bash a write to the shared head or GitHub: $cmd" \
    deny_in "$(bash_out "$cmd")"
done

# An empty hook prints nothing, so a case reading "no deny" off it alone would pass on an agent with
# no guard at all: each one holds only when the hook is there to have said so.
for cmd in \
  "git -C /t status" \
  "cd /t && git add src/a.py && git commit -m 'fix'" \
  "bash tests/run.sh" \
  "git -C /t diff" \
  "git -C /t restore src/a.py"; do
  expect "the hook lets the fixer's Bash do ordinary fix work: $cmd" \
    bash -c '[ -n "$1" ] && ! grep -qF "\"permissionDecision\": \"deny\"" <<<"$2"' _ "$bash_hook" "$(bash_out "$cmd")"
done

agent_hook="$(hook_command "$agent" Agent 2>/dev/null)"
expect "a PreToolUse hook scopes the fixer's Agent" test -n "$agent_hook"

agent_out() { # $1 the subagent_type: the Agent hook's output on that payload
  jq -n --arg t "$1" '{tool_input: {subagent_type: $t}}' 2>/dev/null | sh -c "$agent_hook" 2>/dev/null
}

expect "the hook lets the fixer dispatch unit-test-author to prove its fix" \
  bash -c '[ -n "$1" ] && ! grep -qF "\"permissionDecision\": \"deny\"" <<<"$2"' _ "$agent_hook" "$(agent_out unit-test-author)"
for type in general-purpose do-pr-fixer e2e-test-author ""; do
  expect "the hook denies the fixer forking any agent but unit-test-author: '$type'" \
    deny_in "$(agent_out "$type")"
done

echo "# README.md, .agents/invocation.md, docs/do.md: the agent is listed with what do ships"

# shellcheck disable=SC2034  # lib.sh's carries reads $flat
flat="$(grep -E '^\| `do` +\|' "$root/README.md")"
carries "the README's do row lists do-pr-fixer among the agents do ships" "do-pr-fixer"

agents_table="$(passage_of "$root/.agents/invocation.md" "## Agents a skill ships" "## ")"
expect "invocation.md's Agents a skill ships table has a do-pr-fixer row" \
  grep -qE '^\| `do-pr-fixer` +\|' <<<"$agents_table"

has "docs/do.md names do-pr-fixer" "$root/docs/do.md" "do-pr-fixer"

exit "$((fails > 0))"
