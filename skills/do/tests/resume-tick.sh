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

echo "# resume-tick.sh tick: a commit no Plan behaviour covers, and a flow commit"
cd "$tmp" || exit 1
claimed_ticket stray archive
behaviour_commit "feat: archive a note" "Archiving a note hides it from the list"
behaviour_commit "feat: export tags" "Exporting a note keeps its tags"
exported="$(git -C "$wt" rev-parse --short HEAD)"
behaviour_commit "test: flow for archiving" ""
plan_file "Archiving a note hides it from the list" "Restoring a note puts it back in place"
run tick "$ticket_path" "$plan"
check_lines "a commit whose Behaviour: line matches no Plan behaviour is named on a stray= line" 0 "$rc" \
  "stray=$exported Exporting a note keeps its tags"
expect "only that commit is stray: neither the ticked one nor the one whose line reads none" \
  test "$(grep -c '^stray=' <<<"$out")" = 1

echo "# resume-tick.sh tick: where the Builder starts, and a Plan every commit already built"
cd "$tmp" || exit 1
claimed_ticket next archive
behaviour_commit "feat: restore a note" "Restoring a note puts it back in place"
plan_file "Archiving a note hides it from the list" "Restoring a note puts it back in place" "Deleting a note asks first"
run tick "$ticket_path" "$plan"
check_lines "the first open behaviour is next, routed to the build with exit 0" 0 "$rc" "next=1" "route=build"
behaviour_commit "feat: archive a note" "Archiving a note hides it from the list"
run tick "$ticket_path" "$plan"
check_lines "with the first behaviour built, the next open one is next" 0 "$rc" "next=3" "route=build"
behaviour_commit "feat: delete a note" "Deleting a note asks first"
run tick "$ticket_path" "$plan"
check_lines "every behaviour ticked prints next=none and route=resumed with exit 1" 1 "$rc" "next=none" "route=resumed"

echo "# resume-tick.sh tick: a Design fork, an Elsewhere item and a wrapped Behavior to prove"
cd "$tmp" || exit 1
claimed_ticket shapes archive
behaviour_commit "feat: archive a note" "Archiving a note hides it from the list and keeps it in the archive folder"
wrapped="$(git -C "$wt" rev-parse --short HEAD)"
plan="${ticket_path%.md}.plan.md"
cat >"$plan" <<'PLAN'
## Behaviours

1. Behavior to prove: Archiving a note hides it from the list and keeps it
   in the archive folder
   Relied on by: the developer
   Target: notes
   Origin: new feature
2. Design fork: criterion 2 reads "archived notes are exported", and the Ruling reads
   "archived notes are skipped". Built on neither side until ruled.
3. Elsewhere: Syncing an archived note to the phone
   Belongs to: notes-mobile
   Location: not known
   Traces to: criterion 3
   Shown by: the sync client lives in the mobile repository
4. Behavior to prove: Restoring a note puts it back in place
   Relied on by: the developer
   Target: notes
   Origin: new feature

## Sketch

none
PLAN
run tick "$ticket_path" "$plan"
check_lines "a Behavior to prove wrapped over two lines is joined with a single space and ticked" 0 "$rc" "item=1 $wrapped"
absent_prefix "a Design fork item prints no item= line" "item=2"
absent_prefix "an Elsewhere item prints no item= line" "item=3"
check_lines "the item after them is read, open, and next" 0 "$rc" "item=4 open" "next=4"
absent_prefix "the wrapped behaviour's commit is not stray" "stray="

echo "# skills/do/references/resume.md: the Resume section takes the Built list and the tick from the script"
flat="$(flat_section "$here/../references/resume.md" "## Resume")"
carries "the Resume section has the Planner's Built: lines printed by resume-tick.sh built" \
  "resume-tick.sh built"
carries "the Resume section has the ticks, the stray commits, the Builder's start and the all-ticked route printed by resume-tick.sh tick" \
  "resume-tick.sh tick" "item=" "stray=" "next=" "route=resumed"
out="$flat"
check_absent "the Resume section has the session strip no behaviour= prefix and drop no none line itself" 0 0 \
  "after its \`behaviour=<sha> \` prefix" "a line reading \`none\` left out"

echo "# skills/do/references/plan.md: the brief's Built: lines are printed by resume-tick.sh built"
plan_ref="$here/../references/plan.md"
flat="$(flat_section "$plan_ref" "## The brief")"
carries "the brief names resume-tick.sh built as what prints the Built: lines" "resume-tick.sh built"
out="$(tr '\n' ' ' <"$plan_ref" | tr -s ' ')"
check_absent "plan.md has the session strip no behaviour= prefix and drop no none line itself" 0 0 \
  "the session strips the \`behaviour=<sha> \` prefix" "past its \`behaviour=<sha> \`"

exit "$fails"
