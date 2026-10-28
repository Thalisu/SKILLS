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

exit "$fails"
