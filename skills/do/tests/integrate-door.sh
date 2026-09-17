#!/usr/bin/env bash
# integrate-door.sh: the contract of scripts/integrate-door.sh, the door a standalone integration
# request passes before anything is integrated, exercised in a throwaway git repository.
# Run: bash skills/do/tests/integrate-door.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
door="$here/../scripts/integrate-door.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

run() {
  rc=0
  out="$(bash "$door" "$@" 2>&1)" || rc=$?
}
one_message_naming() { # $1 the branch the single message= line must name; it must end with `nothing integrated`
  local msgs
  msgs="$(grep '^message=' <<<"$out")"
  [ "$(grep -c . <<<"$msgs")" = 1 ] && grep -qF -- "$1" <<<"$msgs" && grep -qE 'nothing integrated$' <<<"$msgs"
}

fresh origin
printf 'a\n' >a.txt && commit base
fresh work
g remote add origin "$tmp/origin" && g fetch -q origin
g reset -q --hard origin/main
g checkout -q -b feature/x
printf 'b\n' >b.txt && commit "feature work"

echo "# a branch that does not exist"
run rebase ghost
check_lines "a rebase onto a missing branch is refused" 1 "$rc" \
  "op=rebase" "moves=feature/x" "onto=ghost" "writes=feature/x" "refused=missing-branch"
expect "the rebase refusal is one message naming the missing branch and ending nothing integrated" \
  one_message_naming ghost

run merge ghost
check_lines "a merge of a missing branch is refused" 1 "$rc" \
  "op=merge" "moves=ghost" "onto=feature/x" "writes=feature/x" "refused=missing-branch"
expect "the merge refusal is one message naming the missing branch and ending nothing integrated" \
  one_message_naming ghost

echo "# a request the door lets through"
norerere="git -c rerere.enabled=false -c rerere.autoupdate=false"
run rebase main
check_lines "a rebase onto a local branch is let through with the commands the run uses" 0 "$rc" \
  "op=rebase" "moves=feature/x" "onto=main" "writes=feature/x" "in_progress=none" \
  "start=$norerere rebase refs/heads/main" \
  "continue=$norerere -c core.editor=true rebase --continue" \
  "abort=git rebase --abort"
absent "a rebase let through carries no refusal" "refused="

run rebase origin/main
check_lines "a rebase onto a remote-tracking branch is let through, started on its remote ref" 0 "$rc" \
  "op=rebase" "moves=feature/x" "onto=origin/main" "writes=feature/x" "in_progress=none" \
  "start=$norerere rebase refs/remotes/origin/main" \
  "continue=$norerere -c core.editor=true rebase --continue" \
  "abort=git rebase --abort"
absent "a rebase onto a remote-tracking branch carries no refusal" "refused="

run merge main
check_lines "a merge of a local branch into the current branch is let through with the commands the run uses" 0 "$rc" \
  "op=merge" "moves=main" "onto=feature/x" "writes=feature/x" "in_progress=none" \
  "start=$norerere merge --no-edit refs/heads/main" \
  "continue=$norerere -c core.editor=true merge --continue" \
  "abort=git merge --abort"
absent "a merge let through carries no refusal" "refused="

run merge origin/main
check_lines "a merge of a remote-tracking branch is let through, started on its remote ref" 0 "$rc" \
  "op=merge" "moves=origin/main" "onto=feature/x" "writes=feature/x" "in_progress=none" \
  "start=$norerere merge --no-edit refs/remotes/origin/main" \
  "continue=$norerere -c core.editor=true merge --continue" \
  "abort=git merge --abort"
absent "a merge of a remote-tracking branch carries no refusal" "refused="

echo "# a target the protected-branch rule protects"
g branch develop main
g checkout -q main
run merge feature/x
check_lines "a merge into protected main, standing on it, is refused" 1 "$rc" \
  "op=merge" "moves=feature/x" "onto=main" "writes=main" "refused=protected-target"
expect "the protected-target refusal is one message naming the target and ending nothing integrated" \
  one_message_naming main
expect "the protected-target refusal message names the branch that makes the target protected" \
  one_message_naming "develop exists"
g checkout -q feature/x

run merge feature/x main
check_lines "a merge into protected main from another branch is refused as protected, not as the wrong branch" 1 "$rc" \
  "op=merge" "moves=feature/x" "onto=main" "writes=main" "refused=protected-target"
expect "the protected-target refusal from another branch is one message naming the target and ending nothing integrated" \
  one_message_naming main
expect "the protected-target refusal from another branch names the branch that makes the target protected" \
  one_message_naming "develop exists"

run rebase main
check_absent "a rebase onto protected main is not refused for protection, since it writes the developer's own branch" 0 "$rc" \
  "refused=protected-target"
g branch -D develop >/dev/null

echo
if [ "$fails" = 0 ]; then echo "integrate-door: all checks passed"; else
  echo "integrate-door: $fails failed"
  exit 1
fi
