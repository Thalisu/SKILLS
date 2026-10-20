#!/usr/bin/env bash
# pr-hooks.sh: the contract of scripts/pr-hooks.sh, which records the hooks and config of the git
# directory a pr run tree shares with its fixer worktrees and tells whether either changed since.
# Run: bash skills/do/tests/pr-hooks.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/pr-hooks.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

run() { # $1.. the script's arguments: its stdout in $out, its exit in $rc
  rc=0
  out="$(bash "$script" "$@" 2>/dev/null)" || rc=$?
}

fresh planted
main="$(pwd -P)"
printf 'base\n' >app.txt
commit base
run_tree="$main/.claude/worktrees/pr-1-x"
g worktree add -q --detach "$run_tree" HEAD
fixer="$(branch_worktree "$main" fix-1)"
run snapshot "$run_tree"
hooks_digest="$(sed -n 's/^hooks=//p' <<<"$out")"
config_digest="$(sed -n 's/^config=//p' <<<"$out")"
pre_push="$(g -C "$fixer" rev-parse --path-format=absolute --git-common-dir)/hooks/pre-push"
printf '#!/bin/sh\nexit 0\n' >"$pre_push"
chmod +x "$pre_push"
run verify "$run_tree" "$hooks_digest" "$config_digest"
check_lines "an executable pre-push hook a fixer worktree plants in the shared git directory after the snapshot reads as changed hooks: exit 1" \
  1 "$rc" "changed hooks"
absent "the planted hook leaves the config reading as unchanged" "changed config"

fresh planted-config
main="$(pwd -P)"
printf 'base\n' >app.txt
commit base
run_tree="$main/.claude/worktrees/pr-1-x"
g worktree add -q --detach "$run_tree" HEAD
fixer="$(branch_worktree "$main" fix-1)"
run snapshot "$run_tree"
hooks_digest="$(sed -n 's/^hooks=//p' <<<"$out")"
config_digest="$(sed -n 's/^config=//p' <<<"$out")"
git -C "$fixer" config core.sshCommand 'sh -c evil'
run verify "$run_tree" "$hooks_digest" "$config_digest"
check_lines "a core.sshCommand a fixer worktree writes into the shared git directory's config after the snapshot reads as changed config: exit 1" \
  1 "$rc" "changed config"
absent "the planted config setting leaves the hooks reading as unchanged" "changed hooks"

exit "$((fails > 0))"
