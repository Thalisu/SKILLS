#!/usr/bin/env bash
# diagnosis-undo.sh: the contract of scripts/diagnosis-undo.sh, the undo of the worktree and branch
# a refused diagnosis run cut, exercised in throwaway git repositories.
# Run: bash skills/do/tests/diagnosis-undo.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/diagnosis-undo.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT
export HOME="$tmp/home"
mkdir -p "$HOME"

# shellcheck disable=SC2034  # lib.sh's assertions read $out
run() {
  rc=0
  out="$(bash "$script" "$@" 2>&1)" || rc=$?
}

diagnosis_repo() { # $1 repository name, $2 slug: a repository holding a Ticket at issues/01-<slug>.md, entered; its path in $top, the Ticket path in $ticket_path
  fresh "$1"
  top="$(pwd -P)"
  mkdir -p issues
  printf '# 01: %s\n\n**Status:** ready-for-agent\n\n- [ ] one\n' "$2" >"issues/01-$2.md"
  printf 'notes\n' >notes.txt
  commit "chore: seed"
  ticket_path="$top/issues/01-$2.md"
}
worktree_listed() { # $1 path: whether git lists a worktree there
  g -C "$top" worktree list --porcelain | grep -qxF -- "worktree $1"
}
branch_listed() { # $1 branch: whether the main checkout holds it
  g -C "$top" show-ref --verify --quiet "refs/heads/$1"
}
gone() { # $1 label, $2.. a command that must fail
  local label="$1"
  shift
  if "$@"; then fail "$label"; else ok "$label"; fi
}

echo "# diagnosis-undo.sh: a worktree and branch this run cut, with no commit past their start"
diagnosis_repo cut-both archive
wt="$(branch_worktree "$top" archive)"
run "$ticket_path" worktree=none run_branch=none
check_lines "both are removed, exit 0" 0 "$rc" \
  "start=HEAD" "ancestry=holds" "worktree=removed $wt" "branch=removed do/archive"
gone "git lists no worktree at the path afterwards" worktree_listed "$wt"
gone "the do/archive branch is gone afterwards" branch_listed do/archive

echo "# diagnosis-undo.sh: a branch cut from a Spec branch that holds Tickets landed there"
cd "$tmp" || exit 1
fresh spec-start
top="$(pwd -P)"
mkdir -p .scratch/20260102-notes/issues
printf '# 02: restore\n\n**Status:** ready-for-agent\n\n- [ ] one\n' >.scratch/20260102-notes/issues/02-restore.md
printf 'notes\n' >notes.txt
commit "chore: seed"
ticket_path="$top/.scratch/20260102-notes/issues/02-restore.md"
bash "$here/../scripts/spec-branch.sh" cut "$ticket_path" >/dev/null 2>&1
spec="$(bash "$here/../scripts/spec-branch.sh" probe "$ticket_path" | sed -n 's/^spec_branch=//p')"
g checkout -q "$spec"
printf 'archive\n' >>notes.txt
g commit -q -am "feat: an earlier Ticket lands on the Spec branch"
g checkout -q main
wt="$top/.claude/worktrees/do-restore"
g worktree add -q "$wt" -b do/restore --track "$spec"
run "$ticket_path" worktree=none run_branch=none
check_lines "the Spec branch is the start, so the branch carrying only its landed Tickets is removed" 0 "$rc" \
  "start=$spec" "ancestry=holds" "worktree=removed $wt" "branch=removed do/restore"
gone "the Spec-branch worktree is gone afterwards" worktree_listed "$wt"
gone "the do/restore branch is gone afterwards" branch_listed do/restore

echo "# diagnosis-undo.sh: a diagnosis that committed something its start lacks"
cd "$tmp" || exit 1
diagnosis_repo ancestry-fails export
wt="$(branch_worktree "$top" export)"
printf 'probe\n' >>"$wt/notes.txt"
g -C "$wt" commit -q -am "wip: instrument the export"
run "$ticket_path" worktree=none run_branch=none
check_lines "both are kept with reason ancestry, exit 1" 1 "$rc" \
  "start=HEAD" "ancestry=fails" "worktree=kept $wt ancestry" "branch=kept do/export ancestry"
expect "the worktree is still listed" worktree_listed "$wt"
expect "the do/export branch is still there" branch_listed do/export

echo "# diagnosis-undo.sh: a worktree and branch the door already listed"
cd "$tmp" || exit 1
diagnosis_repo entered tags
wt="$(branch_worktree "$top" tags)"
run "$ticket_path" "worktree=$wt" run_branch=do/tags
check_lines "both are kept with reason entered, exit 1" 1 "$rc" \
  "worktree=kept $wt entered" "branch=kept do/tags entered"
expect "the entered worktree is still listed" worktree_listed "$wt"
expect "the entered do/tags branch is still there" branch_listed do/tags

exit "$fails"
