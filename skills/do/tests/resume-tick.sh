#!/usr/bin/env bash
# resume-tick.sh: the contract of scripts/resume-tick.sh, the Built list and the tick of a resumed
# ticket run, exercised in a throwaway git repository. Run: bash skills/do/tests/resume-tick.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/resume-tick.sh"
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

claimed_ticket() { # $1 repository name, $2 slug: a repository holding a Ticket at issues/01-<slug>.md and its do-<slug> worktree; the worktree path in $wt, the Ticket path in $ticket_path
  fresh "$1"
  top="$(pwd -P)"
  mkdir -p issues
  printf '# 01: %s\n\n**Status:** claimed\n\n- [ ] one\n' "$2" >"issues/01-$2.md"
  printf 'notes\n' >notes.txt
  commit "chore: seed"
  ticket_path="$top/issues/01-$2.md"
  wt="$(branch_worktree "$top" "$2")"
}
behaviour_commit() { # $1 title, $2 Behaviour: text, or empty for a commit that carries none: a commit on the worktree's branch
  printf '%s\n' "$1" >>"$wt/notes.txt"
  if [ -n "$2" ]; then
    g -C "$wt" commit -q -am "$1" -m "Behaviour: $2"
  else
    g -C "$wt" commit -q -am "$1"
  fi
}

echo "# resume-tick.sh built: commits that carry Behaviour: lines, and a flow commit that carries none"
claimed_ticket built archive
behaviour_commit "feat: archive a note" "Archiving a note hides it from the list"
behaviour_commit "test: flow for archiving" ""
behaviour_commit "feat: restore a note" "Restoring a note puts it back in place"
run built "$ticket_path"
check_lines "each Behaviour: text prints as a built= line" 0 "$rc" \
  "built=Archiving a note hides it from the list" "built=Restoring a note puts it back in place"
same "the built= lines come oldest first, the commit with no Behaviour: line left out" \
  "built=Archiving a note hides it from the list
built=Restoring a note puts it back in place"

echo "# resume-tick.sh built: no commit carries a Behaviour: line"
cd "$tmp" || exit 1
claimed_ticket nothing-built export
behaviour_commit "chore: tidy the notes" ""
run built "$ticket_path"
same "a branch with no Behaviour: line prints built=none alone" "built=none"
check_lines "built=none still exits 0" 0 "$rc" "built=none"

exit "$fails"
