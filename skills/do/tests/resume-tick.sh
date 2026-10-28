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

plan_file() { # $1.. one Behavior to prove text per item: a Plan beside the Ticket whose ## Behaviours lists them in order; its path in $plan
  plan="${ticket_path%.md}.plan.md"
  local n=0 text
  {
    printf '## Sources\n\nticket: %s\n\n## Behaviours\n\n' "$ticket_path"
    for text in "$@"; do
      n=$((n + 1))
      printf '%s. Behavior to prove: %s\n   Relied on by: the developer\n   Target: notes\n   Origin: new feature\n' "$n" "$text"
    done
    printf '\n## Sketch\n\nnone\n'
  } >"$plan"
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

echo "# resume-tick.sh tick: a Plan with one behaviour committed and one still to build"
cd "$tmp" || exit 1
claimed_ticket ticked archive
behaviour_commit "feat: archive a note" "Archiving a note hides it from the list"
archived="$(git -C "$wt" rev-parse --short HEAD)"
plan_file "Archiving a note hides it from the list" "Restoring a note puts it back in place"
run tick "$ticket_path" "$plan"
check_lines "a behaviour a commit's Behaviour: line carries word for word is ticked with that commit's short sha" 0 "$rc" \
  "item=1 $archived"
check_lines "a behaviour no commit carries prints open" 0 "$rc" "item=2 open"

echo "# resume-tick.sh tick: the only commit near a behaviour words it differently"
cd "$tmp" || exit 1
claimed_ticket reworded archive
behaviour_commit "feat: archive a note" "Archiving a note hides it from the list view"
behaviour_commit "feat: restore a note" "restoring a note puts it back in place"
plan_file "Archiving a note hides it from the list" "Restoring a note puts it back in place"
run tick "$ticket_path" "$plan"
check_lines "a commit whose Behaviour: line adds words to the behaviour leaves it open" 0 "$rc" "item=1 open"
check_lines "a commit whose Behaviour: line differs from the behaviour in case alone leaves it open" 0 "$rc" "item=2 open"

exit "$fails"
