#!/usr/bin/env bash
# pr-fixer.sh: the agent the `pr` Playbook forks to fix a red check, `do-pr-fixer`. A pull request's
# head may be shared, and ADR 0086 keeps the session's one fast-forward push as the only write to
# it: a fixer that pushes, pulls, moves a ref, switches branch, opens a worktree or reaches GitHub
# through `gh` makes a write the session never vouched for, and one that writes under the git
# directory its worktree shares with the run tree (a hook, the config, info/) plants code the
# session's own push then runs. The guard is the agent's own hooks, a speed bump over the command
# text and not a sandbox, run live the way the harness runs them, since the fixer reads a check's
# log a stranger can write into. And the agent is listed wherever the repo lists what `do` ships,
# so the installer's links and the developer's docs name it.
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

# The fixture the Bash hook reads its worktrees off: a main checkout, the pull request's run tree and a
# fixer worktree under .claude/worktrees/, the way the pr Playbook cuts them.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fresh main
mkdir -p src && printf 'x\n' >src/a.py
commit "first"
main="$(pwd -P)"
g worktree add -q --detach "$main/.claude/worktrees/pr-1-abc1234" 2>/dev/null
g worktree add -q -b fixer/s/abc/w1-1 "$main/.claude/worktrees/fixer-s-abc-w1-1" 2>/dev/null
run_tree="$(cd "$main/.claude/worktrees/pr-1-abc1234" && pwd -P)"
fixer="$(cd "$main/.claude/worktrees/fixer-s-abc-w1-1" && pwd -P)"
mkdir -p "$fixer/src"
ln -s "$main/.git/hooks" "$fixer/hooklink"
mkdir "$tmp/plain"
plain="$(cd "$tmp/plain" && pwd -P)"

bash_out() { # $1 the command, $2 the cwd the harness reports (the fixer's worktree by default): the Bash hook's output on that payload
  local w="${2:-$fixer}"
  jq -n --arg c "$1" --arg w "$w" '{tool_input: {command: $c}, cwd: $w}' 2>/dev/null |
    (cd "$w" && sh -c "$bash_hook") 2>/dev/null
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
  "git -C /t config user.name x" \
  "git --git-dir /t/.git status"; do
  expect "the hook denies the fixer's Bash a write to the shared head, its git dir or GitHub: $cmd" \
    deny_in "$(bash_out "$cmd")"
done

# The guard reads the command line whichever way a word in it is spelled: a fixer steered by a log it
# reads reaches gh or a git write as easily through a prefix command, a path, a quote, a variable,
# an alias, a config set for one command or an argument list an interpreter hands to gh, and a hook
# matching the literal text lets each through. A script the fixer runs is the limit pinned below.
spelled=(
  'env gh pr view'
  'command gh pr view'
  'xargs gh pr view'
  'echo 1 | xargs -I{} gh api x'
  'env -i git push origin HEAD'
  '/usr/bin/env git push'
  'time gh run rerun 7'
  'exec gh pr view'
  'bash -c "gh pr view"'
  'sh -c "cd /t; git push"'
  'eval gh pr view'
  'find . -exec gh api x ;'
  '/usr/bin/gh pr view'
  '/usr/bin/git push origin HEAD'
  './node_modules/.bin/gh x'
  $'gh\tpr view'
  $'git\tpush'
  $'g\\\nh pr view'
  '\gh pr view'
  "'gh' pr view"
  "g''h pr view"
  '"git" push'
  'g=gh; $g pr view'
  'g=git; ${g} push'
  's=push; git $s origin HEAD'
  '$(printf gh) pr view'
  '/usr/bin/g? pr view'
  '`printf gh` pr view'
  'git -c alias.p=push p origin HEAD'
  "git -c alias.p='!gh pr view' p"
  'git config alias.p push'
  'git config --global alias.p push'
  'git config core.hooksPath /tmp/h'
  'git -c core.hooksPath=/tmp/h commit -m x'
  "alias p='git push'"
  'GIT_CONFIG_COUNT=1 git status'
  'PATH=/tmp:$PATH git status'
  'git stash'
  'git tag v1'
  'git remote add o x'
  'git branch new'
  'git --no-pager push'
  'echo x > /main/.git/hooks/pre-push'
  'cp x ../../.git/hooks/pre-push'
  'git rev-parse --git-path hooks'
  $'perl -e \'system("gh", "api", "-X", "DELETE", "repos/o/r")\''
  $'perl -e \'exec "gh", "pr", "merge", "1"\''
  $'perl -e \'system("/usr/bin/env", "gh", "pr", "view")\''
  $'python3 -c \'import subprocess; subprocess.run(["gh","pr","merge","1"])\''
)
for cmd in "${spelled[@]}"; do
  expect "the hook denies the fixer's Bash gh or a git write whichever way its command word is spelled: ${cmd@Q}" \
    deny_in "$(bash_out "$cmd")"
done

# An empty hook prints nothing, so a case reading "no deny" off it alone would pass on an agent with
# no guard at all: each one holds only when the hook is there to have said so. A git config write
# left this list on purpose: it changes the config the run tree shares, so it is denied above.
for cmd in \
  "git -C $fixer status" \
  "cd $fixer && git add src/a.py && git commit -m 'fix'" \
  "bash tests/run.sh" \
  "git -C $fixer diff" \
  "git -C $fixer restore src/a.py" \
  "x=\$(git -C $fixer rev-parse HEAD)" \
  "git -C $fixer config --get user.name" \
  "git config --list" \
  "cat .gitignore" \
  "git add .gitignore .github/workflows/ci.yml" \
  "ls .githooks" \
  "git -c user.email=a@b -c user.name=n commit -m 'fix'" \
  "git branch" \
  "git config --get user.name" \
  "cd $fixer && git commit -m 'fix(ci): the gh step'" \
  "timeout 60 bash tests/run.sh" \
  "git ls-files | xargs grep -n foo" \
  'x=$(git rev-parse HEAD); echo $x' \
  "cat .github/workflows/ci.yml" \
  "git log --format=%(refname) -n1"; do
  expect "the hook lets the fixer's Bash do ordinary fix work: ${cmd//$fixer/<Tree>}" \
    bash -c '[ -n "$1" ] && ! grep -qF "\"permissionDecision\": \"deny\"" <<<"$2"' _ "$bash_hook" "$(bash_out "$cmd")"
done

# The session pushes from the run tree, and pr-guard.sh reads the fixer branches, never a commit made
# in the run tree itself: a fixer steered by a check's log that commits a CI workflow there, resets
# the branch under its picks or writes a file into it rides the session's own fast-forward push to
# the pull request head. So a git command that changes the index, the work tree or the branch is
# denied unless the directory it runs in (its -C, a cd before it, or the cwd the harness reports) is
# a fixer worktree, and a redirection into the run tree or the main checkout is denied too.
in_tree_ok=(
  "git -C $fixer commit -m x"
  "cd $fixer && git add src/a.py && git commit -m x"
  "cd $fixer && git reset --hard HEAD"
  "git -C $fixer/src restore a.py"
  "git -C $run_tree status"
  "git -C $run_tree diff HEAD"
  "git -C $run_tree log --oneline"
  "git -C $run_tree rev-list abc1234..HEAD"
  "cd $run_tree && git status"
  "cd $run_tree && git -C $fixer commit -m x"
  "echo x > $fixer/src/a.py"
  "cd $fixer && echo x >> src/a.py"
  "echo x > /dev/null 2>&1"
  "echo x > $tmp/return.txt"
  "git -C $fixer log 2>&1"
)
for cwd in "$run_tree" "$fixer"; do
  for cmd in "${in_tree_ok[@]}"; do
    expect "the hook lets the fixer change its own worktree and read the run tree (cwd ${cwd#"$tmp"/}): ${cmd//$tmp\//}" \
      bash -c '[ -n "$1" ] && ! grep -qF "\"permissionDecision\": \"deny\"" <<<"$2"' _ "$bash_hook" "$(bash_out "$cmd" "$cwd")"
  done
done

outside=(
  "git -C $run_tree commit -m x"
  "git -C $run_tree commit --allow-empty -m planted"
  "git -C $run_tree add .github/workflows/ci.yml"
  "git -C $run_tree reset --hard HEAD~1"
  "git -C $run_tree reset --soft abc1234"
  "git -C $run_tree restore ."
  "git -C $run_tree apply fix.patch"
  "git -C $run_tree rm src/a.py"
  "git -C $run_tree mv src/a.py src/b.py"
  "git -C $run_tree clean -fd"
  "git -C $main commit -m x"
  "git -C $main reset --hard"
  "git -C $main/.claude/worktrees/not-a-fixer commit -m x"
  "git -C $fixer/../pr-1-abc1234 commit -m x"
  "git -C $fixer/../../x commit -m x"
  "git -C $fixer -C .. commit -m x"
  "cd $run_tree && git commit -m x"
  "cd $run_tree && git add -A && git commit -m x"
  "cd $main && git restore ."
  "cd $fixer && cd .. && git commit -m x"
  "cd .. && git commit -m x"
  "git --work-tree $run_tree commit -m x"
  'git -C $T commit -m x'
  'cd $T && git commit -m x'
  "env git -C $run_tree commit -m x"
  "xargs git -C $run_tree add"
  "timeout 5 git -C $run_tree reset --hard"
  "echo x > $run_tree/.github/workflows/ci.yml"
  "printf x >> $run_tree/src/a.py"
  "echo x > $main/README.md"
  "echo x 2> $run_tree/err.txt"
  "echo x > $main/.claude/worktrees/not-a-fixer/y"
  "cd $run_tree && echo x > src/a.py"
  'echo x > $T/src/a.py'
  "echo x > src/*.py"
)
for cwd in "$run_tree" "$fixer"; do
  for cmd in "${outside[@]}"; do
    expect "the hook denies the fixer's Bash a git change or a redirection outside a fixer worktree (cwd ${cwd#"$tmp"/}): ${cmd//$tmp\//}" \
      deny_in "$(bash_out "$cmd" "$cwd")"
  done
done

# With the harness's cwd on the run tree, where the fixer's shell starts, a bare command is a command
# in the run tree: nothing short of a cd or a -C moves it into a worktree of its own.
for cmd in \
  "git commit -m x" \
  "git add -A" \
  "git reset --hard" \
  "git restore ." \
  "echo x > src/a.py" \
  "echo x >> .github/workflows/ci.yml"; do
  for cwd in "$run_tree" "$main"; do
    expect "the hook denies a bare git change or redirection when the cwd is the run tree or the main checkout (cwd ${cwd#"$tmp"/}): $cmd" \
      deny_in "$(bash_out "$cmd" "$cwd")"
  done
done
expect "the hook denies a git change when its cwd is in no git repository, since it cannot find the fixer worktrees" \
  deny_in "$(bash_out "git -C $fixer commit -m x" "$plain")"
expect "the hook denies a redirection when its cwd is in no git repository, for the same reason" \
  deny_in "$(bash_out "echo x > $fixer/src/a.py" "$plain")"

out="$(bash_out "git -C $run_tree commit -m x" "$run_tree")"
rc=$?
check "the hook's denial of a git change outside a fixer worktree names the run tree and says it is a speed bump" 0 "$rc" \
  '"permissionDecision": "deny"' "run tree" "fixer worktree" "speed bump"

# The guard reads the command's words, never a program the command runs: a script the fixer writes
# can start gh. A fixer or a reviewer told it is a sandbox trusts a wall that is not there, so the
# denial says what it is, and the limit stays pinned so that statement stays true.
out="$(bash_out "gh pr view 42")"
rc=$?
check "the hook's gh denial says it is a speed bump, not a sandbox, and does not read a script the fixer runs" 0 "$rc" \
  '"permissionDecision": "deny"' "speed bump" "not a sandbox" "script the fixer writes and runs is not read"
for cmd in "bash ./fix.sh" "sh run-tests.sh" "make test" "npm test"; do
  expect "the hook lets a script the fixer runs through unread, the limit its denial states: $cmd" \
    bash -c '[ -n "$1" ] && ! grep -qF "\"permissionDecision\": \"deny\"" <<<"$2"' _ "$bash_hook" "$(bash_out "$cmd")"
done

agent_hook="$(hook_command "$agent" Agent 2>/dev/null)"
expect "a PreToolUse hook scopes the fixer's Agent" test -n "$agent_hook"

agent_out() { # $1 the subagent_type: the Agent hook's output on that payload, dispatched in the foreground
  jq -n --arg t "$1" '{tool_input: {subagent_type: $t, run_in_background: false}}' 2>/dev/null | sh -c "$agent_hook" 2>/dev/null
}

expect "the hook lets the fixer dispatch unit-test-author to prove its fix" \
  bash -c '[ -n "$1" ] && ! grep -qF "\"permissionDecision\": \"deny\"" <<<"$2"' _ "$agent_hook" "$(agent_out unit-test-author)"
for type in general-purpose do-pr-fixer e2e-test-author ""; do
  expect "the hook denies the fixer forking any agent but unit-test-author: '$type'" \
    deny_in "$(agent_out "$type")"
done
# The pr Playbook session waits on the fixer's return file, and the fixer waits on its test author's
# verdict, so the author is dispatched in the foreground. One launched in the background returns no
# verdict: the fixer falls back to polling for it, and the shell it polls with outlives the fixer.
denies_background "$agent_hook" unit-test-author
foreground_out="$(printf '{"tool_input": {"subagent_type": "unit-test-author", "run_in_background": false}}' |
  sh -c "$agent_hook" 2>/dev/null)"
expect "the hook lets the fixer dispatch unit-test-author with run_in_background false" \
  bash -c '[ -n "$1" ] && ! grep -qF "\"permissionDecision\": \"deny\"" <<<"$2"' _ "$agent_hook" "$foreground_out"

echo "# skills/do/agents/do-pr-fixer.md: the fixer writes and edits inside a fixer worktree only, never a .git path"

# A fixer steered by a log a stranger wrote can aim Write or Edit anywhere: a file in the run tree or
# the main checkout lands outside the one commit the session vouches for, and a .git path (the
# shared hooks and config) runs on the session's own push. The guard is read off where the path
# resolves to, so a `..`, a symlink or a look-alike directory name must not carry a write past it.
write_hook="$(hook_command "$agent" Write 2>/dev/null)"
expect "a PreToolUse hook scopes the fixer's Write" test -n "$write_hook"
expect "the same hook scopes the fixer's Edit, on one Write|Edit matcher" \
  bash -c '[ -n "$1" ] && [ "$1" = "$2" ]' _ "$write_hook" "$(hook_command "$agent" Edit 2>/dev/null)"

write_out() { # $1 cwd, $2 file_path: the Write|Edit hook's output on that payload, run from that cwd as the harness runs it
  jq -n --arg f "$2" --arg c "$1" '{tool_input: {file_path: $f}, cwd: $c}' 2>/dev/null |
    (cd "$1" && sh -c "$write_hook") 2>/dev/null
}
# An empty hook prints nothing, so an allow case holds only when the hook is there to have said so.
write_allows() { # $1 cwd, $2 file_path: succeeds when the hook exists, exits 0 and prints no deny
  local o
  [ -n "$write_hook" ] || return 1
  o="$(write_out "$1" "$2")" || return 1
  ! deny_in "$o"
}

for cwd in "$main" "$run_tree" "$fixer"; do
  for path in "$fixer/src/a.py" "$fixer/new/dir/test.sh"; do
    expect "the hook lets the fixer write inside its worktree (cwd ${cwd#"$tmp"/}): ${path#"$tmp"/}" \
      write_allows "$cwd" "$path"
  done
done
expect "the hook lets the fixer write a path relative to its worktree as cwd: src/a.py" \
  write_allows "$fixer" "src/a.py"

for cwd in "$main" "$run_tree" "$fixer"; do
  for path in \
    "$main/src/a.py" \
    "$run_tree/src/a.py" \
    "$main/.git/hooks/pre-push" \
    "$main/.git/config" \
    "$main/.git/worktrees/fixer-s-abc-w1-1/hooks/pre-push" \
    "$fixer/.git" \
    "$fixer/../../../.git/hooks/pre-push" \
    "$fixer/hooklink/pre-push" \
    "/tmp/outside.txt" \
    "$main/.claude/worktrees/not-a-fixer/x.txt" \
    "$main/.claude/worktrees/fixer-s-abc-w1-1/../pr-1-abc1234/x.txt" \
    "$main/.claude/worktrees/fixer-s-abc-w1-1evil/../../x"; do
    expect "the hook denies the fixer a write outside a fixer worktree or to a .git path (cwd ${cwd#"$tmp"/}): ${path#"$tmp"/}" \
      deny_in "$(write_out "$cwd" "$path")"
  done
done

# The fixer's one line goes to the brief's Return file: under the session's do-pr-fix.* temp
# directory, outside every worktree. The Bash guard denies the documented printf redirect whenever
# the reason holds a backtick, a `; gh` or a .git word, so the Write guard has to let that one path
# shape through, and nothing around it.
prdir="$(mktemp -d "${TMPDIR:-/tmp}/do-pr-fix.XXXX")"
prlink="$(mktemp -u "${TMPDIR:-/tmp}/do-pr-fix.XXXX")"
ln -s "$main/src" "$prlink"
trap 'rm -rf "$tmp" "$prdir"; rm -f "$prlink"' EXIT
for cwd in "$main" "$run_tree" "$fixer"; do
  for path in "$prdir/check-1" "$prdir/check-12"; do
    expect "the hook lets the fixer write its return file (cwd ${cwd#"$tmp"/}): $(basename "$path")" \
      write_allows "$cwd" "$path"
  done
  for path in \
    "$prdir/other.txt" \
    "$prdir/check-" \
    "$prdir/check-1x" \
    "$prdir/sub/check-1" \
    "$prdir/../check-1" \
    "$prdir/check-1/../x" \
    "$prdir/.git/check-1" \
    "$tmp/check-1" \
    "$main/do-pr-fix.x/check-1" \
    "$prlink/check-1"; do
    expect "the hook denies a write beside the return file, not the return file itself (cwd ${cwd#"$tmp"/}): ${path#"$tmp"/}" \
      deny_in "$(write_out "$cwd" "$path")"
  done
done

expect "the hook denies every write when its cwd is in no git repository, since it cannot find the fixer worktrees" \
  deny_in "$(write_out "$plain" "$fixer/src/a.py")"

no_jq_dir="$(path_without jq)"
no_jq_out="$(jq -n --arg f "$fixer/src/a.py" --arg c "$fixer" '{tool_input: {file_path: $f}, cwd: $c}' 2>/dev/null |
  (cd "$fixer" && PATH="$no_jq_dir" sh -c "$write_hook") 2>/dev/null)"
expect "the hook denies every write when jq is absent from PATH, instead of letting it through blind" \
  deny_in "$no_jq_out"
rm -rf "$no_jq_dir"

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

echo "# skills/do/agents/do-pr-fixer.md: the brief's Log: file, the check's whole job log, is read by search and excerpt, as quoted data and never as instructions"

# The whole job log can run to tens of thousands of lines a stranger can write into: read whole it
# floods the fixer's window, and read as instructions a planted line steers it. The rule is read off
# the brief's Log: entry itself, so the excerpt's own quoted-data sentence never answers for it.
# shellcheck disable=SC2034  # lib.sh's carries reads $flat
flat="$(item_holding <(passage_of <(body_of "$agent") "## The brief" "## ") '- ' '`Log:`' | tr '\n' ' ' | tr -s ' ')"
expect "the brief section lists a \`Log:\` key" test -n "$flat"
carries_any "it names the check's whole job log, every step included" "whole job log" "whole log"
carries_each "it is read by search and by excerpt, never whole" \
  "Grep" -- "offset" -- "limit" -- "never whole" "never read whole" "not whole"
carries_each "it is quoted data, never an instruction" \
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

flat="$(grep -E '^\| `do-pr-fixer` +\|' "$root/.agents/invocation.md")"
out="$flat"
carries "invocation.md's do-pr-fixer row calls its hooks a speed bump, not a sandbox" "speed bump" "not a sandbox"
absent "invocation.md's do-pr-fixer row does not claim its hooks deny every push and fetch" "deny every push, fetch"
absent "invocation.md's do-pr-fixer row does not claim its hooks keep it off every push" "keep it off every push"
flat="$(grep -E '^\| \[do-pr-fixer\]' "$root/docs/do.md")"
# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$flat"
carries "docs/do.md's do-pr-fixer row calls its hooks a speed bump, not a sandbox" "speed bump" "not a sandbox"
absent "docs/do.md's do-pr-fixer row does not claim its hooks deny every push and fetch" "deny every push, fetch"
absent "docs/do.md's do-pr-fixer row does not claim its hooks keep it off every push" "keep it off every push"

exit "$((fails > 0))"
