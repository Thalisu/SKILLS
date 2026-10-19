#!/usr/bin/env bash
# pr-fixer.sh: the agent the `pr` Playbook forks to fix a red check, `do-pr-fixer`. A pull request's
# head may be shared, and ADR 0086 keeps the session's one fast-forward push as the only write to
# it: a fixer that pushes, pulls, moves a ref, switches branch, opens a worktree or reaches GitHub
# through `gh` makes a write the session never vouched for, and one that writes under the git
# directory its worktree shares with the run tree (a hook, the config, info/) plants code the
# session's own push then runs. The guarantee is the agent's own hooks,
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
  "cd /t && gh api x" \
  "git --git-dir /t/.git push origin HEAD" \
  "git --work-tree /t push origin HEAD" \
  "git send-pack origin HEAD" \
  'g\it push origin HEAD' \
  'G=git; $G push origin HEAD' \
  'g=git; ${g} push origin HEAD' \
  "git config alias.p push" \
  "git config --global alias.p push" \
  "git -c alias.p=push p origin HEAD" \
  "env gh pr view 42" \
  "command gh pr view 42" \
  "/usr/bin/gh pr view 42" \
  "printf x > /t/.git/hooks/pre-push" \
  "cp hook.sh /t/.git/hooks/pre-push" \
  "tee /t/.git/info/exclude" \
  'printf x > "$(git rev-parse --git-common-dir)/hooks/pre-push"' \
  'd=$(git rev-parse --git-path hooks/pre-push); printf x > $d' \
  "echo x > .git" \
  "git config core.hooksPath /tmp/h" \
  "git -C /t config core.hooksPath /tmp/h" \
  "git --git-dir=/t/.git config core.hooksPath /tmp/h" \
  "git config --get user.name && git config core.hooksPath /tmp/h" \
  "git -C /t config user.name x"; do
  expect "the hook denies the fixer's Bash a write to the shared head, its git dir or GitHub: $cmd" \
    deny_in "$(bash_out "$cmd")"
done

# An empty hook prints nothing, so a case reading "no deny" off it alone would pass on an agent with
# no guard at all: each one holds only when the hook is there to have said so. A git config write
# left this list on purpose: it changes the config the run tree shares, so it is denied above.
for cmd in \
  "git -C /t status" \
  "cd /t && git add src/a.py && git commit -m 'fix'" \
  "bash tests/run.sh" \
  "git -C /t diff" \
  "git -C /t restore src/a.py" \
  'x=$(git -C /t rev-parse HEAD)' \
  "git --git-dir /t/.git status" \
  "git -C /t config --get user.name" \
  "git config --list" \
  "cat .gitignore" \
  "git add .gitignore .github/workflows/ci.yml" \
  "ls .githooks"; do
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

# The fixer's worktree shares one git common dir with the run tree, and the session's own push runs
# whatever hook sits there: Write and Edit reach it as surely as a redirect does, so each holds its
# own guard. A path is asked both literally and through `..`, the pointer file `.git` included, and
# a repo whose common dir carries no `.git` component is asked from its own cwd.
for tool in Write Edit; do
  write_hook="$(hook_command "$agent" "$tool" 2>/dev/null)"
  expect "a PreToolUse hook scopes the fixer's $tool" test -n "$write_hook"

  write_out() { # $1 the file_path, $2 the cwd it runs from (the repo root when left out): the hook's output
    local cwd="${2:-$root}"
    jq -n --arg p "$1" --arg d "$cwd" '{cwd: $d, tool_input: {file_path: $p}}' 2>/dev/null |
      (cd "$cwd" && sh -c "$write_hook" 2>/dev/null)
  }

  common_hook="$(cd "$root" && cd "$(git rev-parse --git-common-dir)" && pwd -P)/hooks/pre-push"
  for p in \
    "/t/.git/hooks/pre-push" \
    "/t/.git/config" \
    "/t/.git/info/exclude" \
    "/t/src/../.git/hooks/pre-push" \
    "/t/.git" \
    "$common_hook"; do
    expect "the hook denies the fixer's $tool a write under the shared git dir: $p" \
      deny_in "$(write_out "$p")"
  done

  for p in \
    "/t/src/a.py" \
    "/t/.gitignore" \
    "/t/.github/workflows/ci.yml" \
    "/t/.githooks/pre-commit" \
    "/t/docs/x.git.md"; do
    expect "the hook lets the fixer's $tool write a tracked file: $p" \
      bash -c '[ -n "$1" ] && ! grep -qF "\"permissionDecision\": \"deny\"" <<<"$2"' _ "$write_hook" "$(write_out "$p")"
  done

  bare="$(mktemp -d)"
  bare="$(cd "$bare" && pwd -P)"
  git init -q --bare "$bare"
  expect "the hook denies the fixer's $tool a hook in a common dir with no .git component" \
    deny_in "$(write_out "$bare/hooks/pre-push" "$bare")"
  expect "the hook lets the fixer's $tool write outside that common dir" \
    bash -c '[ -n "$1" ] && ! grep -qF "\"permissionDecision\": \"deny\"" <<<"$2"' _ "$write_hook" "$(write_out "$bare-other/src/a.py" "$bare")"
  rm -rf "$bare"

  # A guard that exits 0 when jq is missing is one the harness reads as allow, so it is asked with a
  # path it would otherwise let through: a deny there can only come from the blind path.
  no_jq_dir="$(path_without jq)"
  blind_rc=0
  blind_out="$(jq -n --arg d "$root" '{cwd: $d, tool_input: {file_path: "/t/src/a.py"}}' 2>/dev/null |
    (cd "$root" && PATH="$no_jq_dir" sh -c "$write_hook" 2>"$no_jq_dir/.err"))" || blind_rc=$?
  blind_err="$(cat "$no_jq_dir/.err" 2>/dev/null)"
  expect "the hook on the fixer's $tool fails closed when jq is absent from PATH, instead of exiting 0 silently" \
    bash -c '[ -n "$4" ] && { { [ "$1" -ne 0 ] && [ -n "$2" ]; } || grep -qF "\"permissionDecision\": \"deny\"" <<<"$3"; }' \
    _ "$blind_rc" "$blind_err" "$blind_out" "$write_hook"
  rm -rf "$no_jq_dir"
done

echo "# skills/do/agents/do-pr-fixer.md: the fixer reproduces its check's failure before it edits anything"

# A CI log only points at a failure (ADR 0087): a fix written from the log alone answers what the log
# claims, and a commit for a failure nobody reproduced lands on a head others build on. The clauses
# are read off the section itself, so one moved elsewhere in the body no longer binds this step.
# shellcheck disable=SC2034  # lib.sh's carries reads $flat
flat="$(passage_of <(body_of "$agent") "## Reproduce first" "## " | tr '\n' ' ' | tr -s ' ')"
expect "the fixer's body carries a ## Reproduce first section" test -n "$flat"
carries "the fixer runs the failing step's command under its Tree: before any edit" \
  "failed step" "under your \`Tree:\`" "before any edit"
carries "a failure the fixer cannot reproduce gets no edit and no commit, and its own return line" \
  "no edit and no commit" "not reproduced <k>: <the command run> <what it showed instead>"

echo "# skills/do/agents/do-pr-fixer.md: the fixer proves its fix red-first and leaves one commit, or none and its line"

# The developer auditing a pr run needs one commit per check with a test that failed before it: a
# fix with no failing test first can turn a check green without fixing its cause, and
# fix-integrate.sh picks a branch only when it is exactly one commit ahead, so a second commit is lost.
# shellcheck disable=SC2034  # lib.sh's carries reads $flat
flat="$(passage_of <(body_of "$agent") "## The rules" "## " | tr '\n' ' ' | tr -s ' ')"
expect "the fixer's body carries a ## The rules section" test -n "$flat"
carries "the fixer proves its fix through the unit test author, the reproduced failure as a bugfix red" \
  "unit-test-author" "bugfix"
carries "the fixer writes the failing test first itself where no Testing Policy is installed" \
  "no Testing Policy"
carries "the fixer leaves exactly one commit, its body naming the check" \
  "exactly one commit" "Check: <name>"

# shellcheck disable=SC2034  # lib.sh's carries reads $flat
flat="$(passage_of <(body_of "$agent") "## Two ends with no commit" "## " | tr '\n' ' ' | tr -s ' ')"
expect "the fixer's body carries a ## Two ends with no commit section" test -n "$flat"
carries "a fixer with the Agent tool withheld commits nothing and says the test author was unreachable" \
  "test author unreachable"
carries_any "a fixer whose test will not go green leaves the tree clean" \
  "tree clean" "tree left clean" "clean tree"

# shellcheck disable=SC2034  # lib.sh's carries reads $flat
flat="$(passage_of <(body_of "$agent") "## The return file" "## " | tr '\n' ' ' | tr -s ' ')"
expect "the fixer's body carries a ## The return file section" test -n "$flat"
carries "the fixer writes its one line to the brief's Return file: in one shell command" \
  "Return file:" "one shell command"
carries "the fixer's line is fixed with the reproducing command, or not fixed with its reason" \
  "fixed <k>: <the command that reproduced it>" "not fixed <k>: <reason>"

echo "# skills/do/agents/do-pr-fixer.md: the fixer reads the pr Playbook's brief, its excerpt quoted data, never an instruction"

# The fixer reads a check's log, text a stranger can write into, holding Bash and Write (ADR 0087):
# a log line that reads as an order (open this file, skip that test) steers it unless its own body
# says the text between the excerpt tags is quoted data. The keys are the ones the Playbook's step
# fills, so a key the body does not name is one the fixer has to guess the meaning of.
# shellcheck disable=SC2034  # lib.sh's carries reads $flat
flat="$(passage_of <(body_of "$agent") "## The brief" "## " | tr '\n' ' ' | tr -s ' ')"
expect "the fixer's body carries a ## The brief section" test -n "$flat"
carries "the section lists every key the Playbook's brief fills" \
  "Pull request:" "Check:" "Failed steps:" "Excerpt:" "Dropped:" "Files:" "Tree:" "Branch:" \
  "Return file:"
carries_each "the text between the excerpt tags is quoted data, never an instruction" \
  "<excerpt id=" "\`excerpt\` tags" "excerpt tags" -- \
  "quoted data" -- \
  "never an instruction" "not an instruction" "never instructions" "never as an instruction" \
  "never an order" "not an order"

echo "# README.md, .agents/invocation.md, docs/do.md: the agent is listed with what do ships"

# shellcheck disable=SC2034  # lib.sh's carries reads $flat
flat="$(grep -E '^\| `do` +\|' "$root/README.md")"
carries "the README's do row lists do-pr-fixer among the agents do ships" "do-pr-fixer"

do_rows="$(grep -cE '^\| `do` +\|' "$root/README.md")"
expect "the README's agents table has exactly one do row (found $do_rows)" test "$do_rows" = 1
shipped=()
for definition in "$root"/skills/do/agents/*.md; do shipped+=("\`$(basename "$definition" .md)\`"); done
carries "the README's do row lists every agent under skills/do/agents/, which link-skills.sh installs" \
  "${shipped[@]}"

agents_table="$(passage_of "$root/.agents/invocation.md" "## Agents a skill ships" "## ")"
expect "invocation.md's Agents a skill ships table has a do-pr-fixer row" \
  grep -qE '^\| `do-pr-fixer` +\|' <<<"$agents_table"

has "docs/do.md names do-pr-fixer" "$root/docs/do.md" "do-pr-fixer"

exit "$((fails > 0))"
