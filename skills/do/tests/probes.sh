#!/usr/bin/env bash
# probes.sh: the contract of the ticket Playbook's probes, scripts/ticket-door.sh,
# scripts/resume-state.sh, scripts/gate.sh and scripts/flows.sh, exercised in a throwaway git
# repository. Run: bash skills/do/tests/probes.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/.."
door="$skill/scripts/ticket-door.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT
# gate.sh keeps a red check's log under $TMPDIR, so the trap above removes it with the rest.
export TMPDIR="$tmp"
# The door reads the global unit author under $HOME, so the developer's own linked agents would
# otherwise turn every fallback case below into a global one.
export HOME="$tmp/home"
mkdir -p "$HOME"

absent_prefix() { # $1 label, $2 a line prefix that must not appear
  if grep -q "^$2" <<<"$out"; then
    echo "FAIL  $1 (found: $2)"
    fails=$((fails + 1))
  else echo "ok    $1"; fi
}
ordered_out() { # $1 label, $2.. key prefixes that must appear in this order in $out
  local label="$1"
  shift
  local last=0 n key ok=1
  for key in "$@"; do
    n="$(grep -n "^$key" <<<"$out" | awk -F: -v l="$last" '$1 > l { print $1; exit }')"
    [ -n "$n" ] || ok=0
    last="${n:-$last}"
  done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else
    echo "FAIL  $label"
    echo "      ${out//$'\n'/$'\n'      }"
    fails=$((fails + 1))
  fi
}
run() {
  local script="$1"
  shift
  rc=0
  out="$(bash "$script" "$@" 2>&1)" || rc=$?
}
ticket() { # $1 file name, $2 status line(s), $3 blocked-by value
  printf '# %s: %s\n\n**What to build:** something.\n\n**Blocked by:** %s\n\n%s\n\n- [ ] one\n\n## Evidence\n' \
    "${1%%-*}" "Title of ${1%.md}" "$3" "$2" >"$issues/$1"
}

cd "$tmp" || exit 1
git init -q -b main main && cd main || exit 1
git config gc.auto 0
git config maintenance.auto false
printf '.scratch/\n' >.gitignore
printf 'one\n' >notes.txt
g add -A
g commit -q -m fixture
top="$(pwd -P)"
issues=".scratch/20260101-feat/issues"
mkdir -p "$issues"
ticket 01-first.md '**Status:** resolved' 'None (can start immediately)'
printf 'a review\n**Status:** claimed\n' >"$issues/01-first.review.md"
printf 'a digest\n' >"$issues/01-first.digest.md"
ticket 02-second.md '**Status:** ready-for-agent' '01, Title of 01-first'
ticket 03-third.md '**Status:** ready-for-agent' '01: Title of 01-first; 02 Title of 02-second'
ticket 04-claimed.md '**Status:** claimed' 'None (can start immediately).'
ticket 05-twice.md $'**Status:** ready-for-agent\n\n**Status:** resolved' 'None (can start immediately)'
ticket 06-orphan.md '**Status:** ready-for-agent' '19, A Ticket nobody wrote'
ticket 07-gone.md '**Status:** claimed' 'None (can start immediately)'
ticket 08-unwalked.md '**Status:** done' 'None (can start immediately)'
ticket 09-stale.md '**Status:** ready-for-agent' 'None (can start immediately)'
ticket 10-blind.md '**Status:** ready-for-agent' '11, A Ticket with no status'
printf '# 11: No status\n\n**What to build:** x.\n' >"$issues/11-nostatus.md"
ticket 12-one.md '**Status:** resolved' 'None (can start immediately)'
ticket 12-two.md '**Status:** resolved' 'None (can start immediately)'
ticket 13-double.md '**Status:** ready-for-agent' '12, One of two'
ticket 14-comma.md '**Status:** ready-for-agent' '01 Title of 01-first, 02 Title of 02-second'
ticket 15-and.md '**Status:** ready-for-agent' '01 and 02'
ticket 16-lines.md '**Status:** ready-for-agent' $'01 Title of 01-first\n02 Title of 02-second'
ticket 17-unsplit.md '**Status:** ready-for-agent' '01 Title of 01-first (after 02)'
ticket 31-below.md '**Status:** ready-for-agent' $'\n01 Title of 01-first\n02 Title of 02-second'
ticket 32-bullets.md '**Status:** ready-for-agent' $'\n- 01: Title of 01-first\n- 02: Title of 02-second'
ticket 33-gap.md '**Status:** ready-for-agent' $'01: Title of 01-first\n\n02: Title of 02-second'
ticket 34-gap-bullets.md '**Status:** ready-for-agent' $'\n\n- 01: Title of 01-first\n\n- 02: Title of 02-second'
ticket 35-status-digit.md $'**Status:** ready-for-agent\n\n- [ ] Exporting 3 notes writes 3 rows' 'None (can start immediately)'
echo ".claude/worktrees/" >>.git/info/exclude
git worktree add -q .claude/worktrees/do-claimed -b do/claimed
git worktree add -q .claude/worktrees/do-stale -b do/stale
wt="$top/.claude/worktrees/do-claimed"

echo "# ticket-door.sh: a Ticket the run may start"
run "$door" "$issues/02-second.md"
check_lines "a ready Ticket whose blocker is resolved starts" 0 "$rc" \
  "ticket=$issues/02-second.md" "title=02: Title of 02-second" "status=ready-for-agent" \
  "blocker=01 resolved $issues/01-first.md" "slug=second" "worktree=none" "loop=fallback" \
  "branch=main" "protected=no" "verdict=start"
ordered_out "the facts come in the order the Reply's Run section states them" \
  ticket= title= status= blocker= slug= worktree= run_branch= loop= branch= protected= verdict=
run "$door" "$issues/04-claimed.md"
check_lines "a claimed Ticket whose worktree exists resumes" 0 "$rc" \
  "status=claimed" "blockers=none" "worktree=$wt" "verdict=resume"
run "$door" "$issues/07-gone.md"
check_lines "a claimed Ticket whose worktree is gone starts over" 0 "$rc" \
  "status=claimed" "worktree=none" "run_branch=none" "verdict=start-over"

ticket 18-orphan.md '**Status:** claimed' 'None (can start immediately)'
git worktree add -q .claude/worktrees/do-orphan -b do/orphan
git -C .claude/worktrees/do-orphan commit -q --allow-empty -m "the first run's own work"
git worktree remove .claude/worktrees/do-orphan
run "$door" "$issues/18-orphan.md"
check_lines "a claimed Ticket whose worktree is gone but its branch remains names the branch" 0 "$rc" \
  "status=claimed" "worktree=none" "run_branch=do/orphan" "verdict=start-over"

# The ticket Playbook's ground step writes <Ticket>.project-map.md and its shape step <Ticket>.sketch.md
# beside the Ticket, so a blocker that ran through them carries its own number on a second file.
ticket 20-grounded.md '**Status:** resolved' 'None (can start immediately)'
printf '# Project map\n\nmap=a project map\n' > "$issues/20-grounded.project-map.md"
ticket 21-shaped.md '**Status:** resolved' 'None (can start immediately)'
printf '# Sketch\n\nthe shape of the change\n' > "$issues/21-shaped.sketch.md"
ticket 22-after-grounded.md '**Status:** ready-for-agent' '20, Title of 20-grounded'
ticket 23-after-shaped.md '**Status:** ready-for-agent' '21, Title of 21-shaped'
for pair in 22-after-grounded:20-grounded:project-map 23-after-shaped:21-shaped:sketch; do
  IFS=: read -r t b kind <<<"$pair"
  run "$door" "$issues/$t.md"
  check "a resolved blocker with a .$kind.md beside it is read from its Ticket alone, and the run starts" 0 "$rc" \
    "blocker=${b%%-*} resolved $issues/$b.md" "verdict=start"
  absent "a .$kind.md beside a blocker never makes its number ambiguous" "ambiguous="
done

# A blocker Ticket's own slug can itself carry a dot (a version number), so the door's exclusion
# of a sidecar (<n>-<slug>.<kind>.md) must not also drop the Ticket's own dotted-slug file.
ticket 24-upgrade-to-v1.2.md '**Status:** resolved' 'None (can start immediately)'
printf '# Project map\n\nmap=a project map\n' > "$issues/24-upgrade-to-v1.2.project-map.md"
ticket 25-after-dotted.md '**Status:** ready-for-agent' '24, Upgrade'
run "$door" "$issues/25-after-dotted.md"
check "a resolved blocker whose own slug carries a dot is read as resolved, and the run starts" 0 "$rc" \
  "blocker=24 resolved $issues/24-upgrade-to-v1.2.md" "verdict=start"
absent "a .project-map.md beside a dotted-slug blocker never makes its number ambiguous" "ambiguous="

# A sidecar left behind once its blocker Ticket is gone is not the blocker: its own status line
# never stands in for the Ticket's, so the number reads as missing and the run never starts.
printf '# Project map\n\n**Status:** resolved\n' > "$issues/26-gone.project-map.md"
printf 'a review\n\n**Status:** resolved\n' > "$issues/27-gone.review.md"
ticket 28-after-lone-map.md '**Status:** ready-for-agent' '26, Gone'
ticket 29-after-lone-review.md '**Status:** ready-for-agent' '27, Gone'
for pair in 28-after-lone-map:26:project-map 29-after-lone-review:27:review; do
  IFS=: read -r t b kind <<<"$pair"
  run "$door" "$issues/$t.md"
  check_lines "a blocker whose Ticket is gone and only a .$kind.md of it remains is missing, and the run is refused" 1 "$rc" \
    "blocker=$b missing none" "ambiguous=$b files none" "verdict=ambiguous"
done

echo "# ticket-door.sh: the stops"
run "$door" "$issues/01-first.md"
check_lines "a resolved Ticket stops" 1 "$rc" "status=resolved" "verdict=resolved"
run "$door" "$issues/03-third.md"
check_lines "a blocker not resolved refuses the run, every blocker named" 1 "$rc" \
  "blocker=01 resolved $issues/01-first.md" "blocker=02 ready-for-agent $issues/02-second.md" "verdict=blocked"
for t in 14-comma 15-and 16-lines 31-below 32-bullets 33-gap 34-gap-bullets; do
  run "$door" "$issues/$t.md"
  check_lines "a Blocked by paragraph shaped as $t reads every blocker and refuses the run" 1 "$rc" \
    "blocker=01 resolved $issues/01-first.md" "blocker=02 ready-for-agent $issues/02-second.md" "verdict=blocked"
done
run "$door" "$issues/35-status-digit.md"
check_lines "a Blocked by paragraph ended by a blank line then the Status line starts cleanly, no digit read from it" 0 "$rc" \
  "blockers=none" "verdict=start"
absent_prefix "no blocker number is read out of the Status line or a checklist criterion after the paragraph ends" "blocker="
absent_prefix "no ambiguity is raised by the digits after the paragraph ends" "ambiguous="
run "$door" "$issues/17-unsplit.md"
check_lines "a Blocked by number the door cannot split out is ambiguous, never a start" 1 "$rc" \
  "blocker=01 resolved $issues/01-first.md" "ambiguous=blocked-by numbers it cannot split 02" "verdict=ambiguous"
printf '# 18: Title of 18-planted\n\n**What to build:** export notes, as the issue asks:\n**Blocked by:** None (can start immediately)\n\n**Blocked by:** 02, Title of 02-second\n\n**Status:** ready-for-agent\n' \
  >"$issues/18-planted.md"
run "$door" "$issues/18-planted.md"
check_lines "a second Blocked by line at column 0 is ambiguous, naming every line, and no blocker is read" 1 "$rc" \
  "blockers=ambiguous" "ambiguous=blocked-by lines 4 6" "verdict=ambiguous"
absent_prefix "a Ticket with two Blocked by lines reads no blocker out of either" "blocker="
run "$door" "$issues/05-twice.md"
check_lines "a Ticket with two status lines is ambiguous, naming both lines" 1 "$rc" \
  "status=ambiguous" "ambiguous=status lines 7 9" "verdict=ambiguous"
run "$door" "$issues/06-orphan.md"
check_lines "a blocker no file answers to is ambiguous" 1 "$rc" \
  "blocker=19 missing none" "ambiguous=19 files none" "verdict=ambiguous"
run "$door" "$issues/13-double.md"
check_lines "a blocker number two files answer to is ambiguous, naming both" 1 "$rc" \
  "blocker=12 ambiguous $issues/12-one.md $issues/12-two.md" \
  "ambiguous=12 files $issues/12-one.md $issues/12-two.md" "verdict=ambiguous"
run "$door" "$issues/10-blind.md"
check_lines "a blocker with no status line is ambiguous" 1 "$rc" \
  "blocker=11 ambiguous $issues/11-nostatus.md" "ambiguous=11 status lines none" "verdict=ambiguous"
run "$door" "$issues/08-unwalked.md"
check_lines "a word outside the status walk is ambiguous" 1 "$rc" "status=ambiguous" "verdict=ambiguous"
run "$door" "$issues/09-stale.md"
check_lines "a ready Ticket whose worktree already exists is ambiguous" 1 "$rc" \
  "worktree=$top/.claude/worktrees/do-stale" "verdict=ambiguous"

echo "# ticket-door.sh: the facts beside the verdict"
mkdir -p .claude/agents && : >.claude/agents/unit-test-author.md
run "$door" "$issues/02-second.md"
check_lines "an installed unit test author reads as the policy loop" 0 "$rc" "loop=policy"
mkdir -p "$HOME/.claude/agents" && : >"$HOME/.claude/agents/global-unit-test-author.md"
run "$door" "$issues/02-second.md"
check_lines "the project's own author wins over the global one" 0 "$rc" "loop=policy"
rm -rf .claude/agents
run "$door" "$issues/02-second.md"
check_lines "no project author and the global unit author linked reads as the global loop" 0 "$rc" "loop=global"
rm -rf "$HOME/.claude"
g branch develop
run "$door" "$issues/02-second.md"
check_lines "a protected branch is stated and never stops the door" 0 "$rc" \
  "protected=yes" "reason=develop exists" "verdict=start"
g branch -D develop >/dev/null
cd "$wt" || exit 1
run "$door" "$issues/02-second.md"
check_lines "a relative path run from the worktree resolves in the main checkout" 0 "$rc" \
  "ticket=$issues/02-second.md" "branch=main" "verdict=start"
cd "$top" || exit 1

echo "# ticket-door.sh: usage"
run "$door"
check_lines "no argument is a usage error" 2 "$rc"
run "$door" "$issues/99-nothing.md"
check_lines "a Ticket that is not there is an error" 2 "$rc"
cd /
run "$door" x
check_lines "outside a repository is an error" 2 "$rc"
cd "$top" || exit 1

echo "# resume-state.sh: a clean worktree"
resume="$skill/scripts/resume-state.sh"
fork="$(git rev-parse HEAD)"
printf 'two\n' >>"$wt/notes.txt"
g -C "$wt" commit -q -am "feat: archive a note" -m "Behaviour: Picking Archive on a note removes it from the list"
printf 'three\n' >>"$wt/notes.txt"
g -C "$wt" commit -q -am "chore: tidy the notes"
first="$(git rev-parse --short do/claimed~1)"
second="$(git rev-parse --short do/claimed)"
run "$resume" "$issues/04-claimed.md"
check_lines "a clean worktree resumes at the build loop, every commit with its behaviour" 0 "$rc" \
  "worktree=$wt" "branch=do/claimed" "rebase=none" "base=main" "merge_base=$fork" \
  "commit=$first feat: archive a note" "behaviour=$first Picking Archive on a note removes it from the list" \
  "commit=$second chore: tidy the notes" "behaviour=$second none" "commits=2" "review=none" "verdict=build"
ordered_out "the resume state comes in its key order" \
  worktree= branch= rebase= base= merge_base= commit= behaviour= commits= review= verdict=
absent_prefix "a clean worktree lists no uncommitted file" "uncommitted="

echo "# resume-state.sh: uncommitted work"
printf 'half written\n' >>"$wt/notes.txt"
printf 'x\n' >"$wt/a b.txt"
run "$resume" "$issues/04-claimed.md"
check_lines "uncommitted work asks before anything, one line per file" 1 "$rc" \
  "uncommitted= M notes.txt" 'uncommitted=?? "a b.txt"' "commits=2" "verdict=ask"
out="$(git -C "$wt" status --short)"
check_lines "the probe leaves the uncommitted work where it was" 0 0 " M notes.txt" '?? "a b.txt"'
git -C "$wt" checkout -q -- notes.txt
rm "$wt/a b.txt"

# ADR 0033: the review runs once per run, so a branch whose Review already sits beside the Ticket
# resumes at the landing through fix, never at a second review.
echo "# resume-state.sh: a branch the review already read"
review_file() { # $1 the Review's Commit: sha, $2 its Security Axis line, $3 the review file path (default 04-claimed's)
  printf '# Review: 04\n\nCommit: %s\n\n## Axes\n\n- Correctness: 0 findings\n- Security: %s\n' "$1" "$2" \
    >"${3:-$issues/04-claimed.review.md}"
}
review_file "$second" "0 findings"
run "$resume" "$issues/04-claimed.md"
check_lines "a Review of a commit this branch has been at, every Axis run, sends the resume to the landing" 4 "$rc" \
  "review=$top/$issues/04-claimed.review.md" "commits=2" "verdict=land"
absent_prefix "a Review that counts is never reported skipped" "review_skipped="

echo "# resume-state.sh: a Review that does not count"
stale="$(g commit-tree -m "an earlier branch's commit" "HEAD^{tree}")"
review_file "$(git rev-parse --short "$stale")" "0 findings"
run "$resume" "$issues/04-claimed.md"
check_lines "a Review of a commit this branch was never at is an earlier run's, and the review runs" 0 "$rc" \
  "review_skipped=stale $top/$issues/04-claimed.review.md" "review=none" "verdict=build"
review_file "$second" "not run, the reviewer did not return"
run "$resume" "$issues/04-claimed.md"
check_lines "a Review with an Axis that did not run is an unfinished review, and the review runs" 0 "$rc" \
  "review_skipped=axis-not-run $top/$issues/04-claimed.review.md" "review=none" "verdict=build"
review_file "$second" "0 findings"

# A `do/<slug>` branch reviewed, landed and deleted, then made again from the same commit, starts
# a fresh reflog whose first entry is the commit the old run's leftover Review still names.
echo "# resume-state.sh: a stale Review from a branch recreated at the same HEAD"
rt="$top/.claude/worktrees/do-recreated"
ticket 30-recreated.md '**Status:** claimed' 'None (can start immediately)'
g worktree add -q .claude/worktrees/do-recreated -b do/recreated "$fork"
review_file "$(git rev-parse --short "$fork")" "0 findings" "$issues/30-recreated.review.md"
printf 'four\n' >>"$rt/notes.txt"
g -C "$rt" commit -q -am "fix: two, never reviewed"
new="$(git rev-parse --short do/recreated)"
run "$resume" "$issues/30-recreated.md"
check_lines "a Review naming the commit a recreated branch's fresh reflog begins at is stale, never the landing" 0 "$rc" \
  "review_skipped=stale $top/$issues/30-recreated.review.md" "review=none" \
  "commit=$new fix: two, never reviewed" "verdict=build"
git worktree remove --force .claude/worktrees/do-recreated
g branch -D do/recreated >/dev/null
rm "$issues/30-recreated.review.md" "$issues/30-recreated.md"

# The extreme paragraph of mechanics.md: a rerun on an unchanged Spec must meet the same Extreme
# fork and print the same /discuss command, never fork a choice-taker a second time. The sidecar
# is the record a first run's stop left beside the Ticket, the way a Review or a Digest is.
echo "# resume-state.sh: an Extreme stop's persisted record"
discuss_line="/discuss Ticket $issues/04-claimed.md, Spec .scratch/20260101-feat/spec.md: the do run stopped at the build step on an Extreme fork, delete the note or keep it archived; delete the note would give up recoverability (data loss). Which side does the Spec take?"
printf '%s\n' "$discuss_line" >"$issues/04-claimed.extreme.md"
run "$resume" "$issues/04-claimed.md"
check_lines "an Extreme stop's persisted record resumes on its own /discuss command, never the landing a Review would give" 5 "$rc" \
  "extreme=$top/$issues/04-claimed.extreme.md" "discuss=$discuss_line" "commits=2" "verdict=extreme"
rm "$issues/04-claimed.extreme.md"

# The write side of the same paragraph: the /discuss shape mechanics.md fixes, filled the way a
# real stop fills it and written as the one-line sidecar the paragraph now instructs, must round
# trip through resume-state.sh exactly, proving the write and the read agree on the same shape.
echo "# resume-state.sh: the /discuss shape mechanics.md fixes, written as the sidecar a stop leaves"
template="$(awk '
  /^```$/ { fence = !fence; next }
  fence && /^\/discuss Ticket/ { print; exit }
' "$skill/references/mechanics.md")"
[ -n "$template" ] || { echo "FAIL  mechanics.md carries no /discuss template to fill"; fails=$((fails + 1)); }
filled="$(printf '%s\n' "$template" | sed \
  -e "s#<the Ticket's path or reference>#$issues/04-claimed.md#" \
  -e "s#<the Spec's path or reference>#.scratch/20260101-feat/spec.md#" \
  -e 's#<the step>#build#' \
  -e 's#<side A> or <side B>#delete the note or keep it archived#' \
  -e 's#<the weaker side> would give up <the guarantee> (<the risk class>)#delete the note would give up recoverability (data loss)#')"
printf '%s\n' "$filled" >"$issues/04-claimed.extreme.md"
expect "the filled template writes as a single line, per the paragraph's one-line sidecar" \
  test "$(wc -l <"$issues/04-claimed.extreme.md")" = 1
run "$resume" "$issues/04-claimed.md"
check_lines "the sidecar written from mechanics.md's own template reads back byte for byte" 5 "$rc" \
  "extreme=$top/$issues/04-claimed.extreme.md" "discuss=$filled" "verdict=extreme"
rm "$issues/04-claimed.extreme.md"

echo "# resume-state.sh: a rebase the integration left open"
printf 'one\nmain side\n' >notes.txt
g commit -q -am "main moves"
g -C "$wt" -c rerere.enabled=false rebase main >/dev/null 2>&1
run "$resume" "$issues/04-claimed.md"
check_lines "a worktree left mid-rebase goes to the integration, its branch read from the rebase state" 3 "$rc" \
  "branch=do/claimed" "rebase=open" "conflicted=notes.txt" "commits=2" \
  "review=$top/$issues/04-claimed.review.md" "verdict=integration"
git -C "$wt" rebase --abort
rm "$issues/04-claimed.review.md"

echo "# resume-state.sh: a branch left behind a target that moved"
# The state a `not landed: target moved` return leaves: every behaviour committed, the tree clean, no
# rebase open, and the developer's branch ahead of the merge base. The resume reads it as a branch to
# build on, so the run re-derives its list, ticks every line and goes on at the gate.
run "$resume" "$issues/04-claimed.md"
check_lines "a branch behind a moved target resumes with every commit and its behaviour listed" 0 "$rc" \
  "rebase=none" "merge_base=$fork" "commit=$first feat: archive a note" \
  "behaviour=$first Picking Archive on a note removes it from the list" "commits=2" "verdict=build"

echo "# resume-state.sh: nothing to resume"
git -C "$wt" checkout -q --detach
run "$door" "$issues/04-claimed.md"
check_lines "the door still says resume for a claimed Ticket's worktree on a detached HEAD" 0 "$rc" \
  "worktree=$wt" "verdict=resume"
run "$resume" "$issues/04-claimed.md"
check_lines "a detached HEAD with no rebase open is not a resumable worktree" 2 "$rc" \
  "$wt is on a detached HEAD with no rebase open: nothing to resume"
git -C "$wt" checkout -q do/claimed
run "$resume" "$issues/07-gone.md"
check_lines "a Ticket with no worktree has nothing to resume" 2 "$rc"
run "$resume"
check_lines "no argument is a usage error" 2 "$rc"

echo "# a worktree list longer than one pipe read"
for i in $(seq -w 1 60); do git worktree add -q --detach --no-checkout ".claude/worktrees/zz-$i"; done
out="$(git worktree list --porcelain | grep '^worktree ' | sed -n 2p)"
check_lines "the Ticket's worktree is the first one listed after the main checkout" 0 0 "worktree $wt"
run "$door" "$issues/04-claimed.md"
check_lines "the door finds the Ticket's worktree listed first among sixty more and resumes" 0 "$rc" \
  "worktree=$wt" "verdict=resume"
run "$resume" "$issues/04-claimed.md"
check_lines "the resume finds the Ticket's worktree listed first among sixty more" 0 "$rc" \
  "worktree=$wt" "verdict=build"

echo "# gate.sh: every check green"
gate="$skill/scripts/gate.sh"
cd "$top" || exit 1
run "$gate" "suite=printf 'ran\n'" "typecheck=true"
check_lines "a green gate prints one key and value line per check and exits 0" 0 "$rc" \
  "suite=green" "typecheck=green" "verdict=green"
ordered_out "the gate prints its command line first, then each check in the order given" \
  command= suite= typecheck= verdict=
absent_prefix "a green check prints none of its output" "ran"
same() { # $1 label, $2 expected output; the whole of $out must equal it
  if [ "$out" = "$2" ]; then echo "ok    $1"; else
    echo "FAIL  $1"
    echo "      ${out//$'\n'/$'\n'      }"
    fails=$((fails + 1))
  fi
}
rerun() { # reruns the command= line the last run printed first, the way a reviewer pastes it
  local line
  line="$(sed -n '1s/^command=//p' <<<"$out")"
  rc=0
  out="$(eval "$line" 2>&1)" || rc=$?
}
first_out="$out"
rerun
same "the command line the gate prints reruns it for the same answer" "$first_out"
run "$gate"
check_lines "no check is a usage error" 2 "$rc"
run "$gate" "true"
check_lines "a check with no key is a usage error" 2 "$rc"
if script -qec true /dev/null </dev/null >/dev/null 2>&1; then
  run "$gate" "stdin=test ! -t 0" </dev/null
  bare_out="$out"
  out="$(script -qec "bash $(printf %q "$gate") 'stdin=test ! -t 0'" /dev/null </dev/null 2>&1 | tr -d '\r')"
  pty_verdict="$(grep '^verdict=' <<<"$out")"
  out="$bare_out"
  check_lines "a check probing its stdin reads the same verdict under a pty as without one" 0 "$rc" \
    "stdin=green" "$pty_verdict"
else
  echo "skip  a check probing its stdin reads the same verdict under a pty as without one (no util-linux script)"
fi

echo "# gate.sh: a red check"
run "$gate" "suite=true" "lint=seq 1 100; echo broke >&2; exit 4" "typecheck=echo 'x.ts:3 error'; exit 2" "format=true"
log="$(sed -n 's/^lint=red exit=4 log=//p' <<<"$out")"
tlog="$(sed -n 's/^typecheck=red exit=2 log=//p' <<<"$out")"
check_lines "a red check prints its key, its exit and the file holding its full output, and the gate exits 1" 1 "$rc" \
  "suite=green" "lint=red exit=4 log=$log" "typecheck=red exit=2 log=$tlog" "format=green" "verdict=red" \
  "  [capped: the last 20 of 101 lines]" "  99" "  broke" "  x.ts:3 error"
ordered_out "the checks after a red one still run, in the order given" command= suite= lint= typecheck= format= verdict=
absent_prefix "the capped block leaves out the lines before its last twenty" "  80$"
[ "$(grep -c '^  ' <<<"$out")" = 22 ] && echo "ok    the failing blocks are capped, and a short one is printed whole" ||
  {
    echo "FAIL  the failing blocks are capped, and a short one is printed whole"
    fails=$((fails + 1))
  }
gate_out="$out"
out="$(cat "$log" 2>/dev/null)"
check_lines "the file the red line names holds the full output" 0 0 "1" "50" "100" "broke"
case "$log" in "$tmp"/do-gate.*) echo "ok    the gate's red logs stay inside this run's temp dir" ;;
*)
  echo "FAIL  the gate's red logs stay inside this run's temp dir (log=$log)"
  fails=$((fails + 1))
  ;;
esac
out="$(git status --short)"
same "the gate writes nothing in the tree it checks" ""
out="$gate_out"
run "$gate" "unit=printf 'boom'; exit 1" "lint=true"
check_lines "a red check whose output ends without a newline leaves the next key and the verdict on lines of their own" 1 "$rc" \
  "  boom" "lint=green" "verdict=red"

echo "# gate.sh: a check the environment stops"
logof() { sed -n "s/^$1=[a-z]* exit=[0-9]* log=\([^ ]*\).*/\1/p" <<<"$out"; }
run "$gate" --infra 'test database is not up' "suite=exit 1" "e2e=no-such-runner-for-the-gate" \
  "api=echo 'connect ECONNREFUSED 127.0.0.1:5432'; exit 1" "db=echo 'FATAL: the test database is not up'; exit 1"
check_lines "a runner that cannot start and a service down are blocked, each cause named, and blocked outweighs red" 3 "$rc" \
  "suite=red exit=1 log=$(logof suite)" \
  "e2e=blocked exit=127 log=$(logof e2e) cause=runner cannot start" \
  "api=blocked exit=1 log=$(logof api) cause=connect ECONNREFUSED 127.0.0.1:5432" \
  "db=blocked exit=1 log=$(logof db) cause=FATAL: the test database is not up" \
  "verdict=blocked"
run "$gate" --infra
check_lines "an --infra with no pattern is a usage error" 2 "$rc"

echo "# flows.sh: the affected flows, from the main checkout"
# A flow key holds a slash, so this reading takes `|` as its sed delimiter where logof takes `/`.
flowlog() { sed -n "s|^$1=[a-z]* exit=[0-9]* log=\([^ ]*\).*|\1|p" <<<"$out"; }
flows="$skill/scripts/flows.sh"
mkdir -p e2e
printf 'exit 0\n' >e2e/login.flow
printf 'echo "ran in $(pwd -P)"; exit 1\n' >e2e/export.flow
cd "$wt" || exit 1
run "$flows" 'bash {}' e2e/login.flow e2e/export.flow
check_lines "each flow runs from the main checkout through the single-flow command, a red one with its block" 1 "$rc" \
  "e2e/login.flow=green" "e2e/export.flow=red exit=1 log=$(flowlog e2e/export.flow)" "  ran in $top" "verdict=red"
ordered_out "the flows print their command line first, then each flow in the order given" \
  "command=bash $(printf %q "$(cd "$skill/scripts" && pwd -P)/flows.sh") " e2e/login.flow= e2e/export.flow= verdict=
run "$flows" 'bash {}' e2e/login.flow
first_out="$out"
rerun
same "the command line the flows print reruns them for the same answer" "$first_out"
run "$flows" bash e2e/login.flow
check_lines "a single-flow command with no {} takes the flow at its end" 0 "$rc" "e2e/login.flow=green" "verdict=green"
run "$flows" 'no-such-flow-runner {}' e2e/login.flow
check_lines "a flow runner that cannot start is blocked, its cause named" 3 "$rc" \
  "e2e/login.flow=blocked exit=127 log=$(flowlog e2e/login.flow) cause=runner cannot start" "verdict=blocked"
run "$flows"
check_lines "no single-flow command is a usage error" 2 "$rc"
run "$flows" 'bash {}'
check_lines "no flow is a usage error" 2 "$rc"
marker="$tmp/flow-injected"
run "$flows" 'bash {}' "e2e/x=\$(touch $marker).flow"
check_lines "a flow name holding = is a usage error" 2 "$rc"
[ ! -e "$marker" ] && echo "ok    a flow name holding = runs nothing it carries" ||
  {
    echo "FAIL  a flow name holding = runs nothing it carries ($marker exists)"
    fails=$((fails + 1))
  }
cd "$top" || exit 1

echo
if [ "$fails" = 0 ]; then echo "probes: all checks passed"; else
  echo "probes: $fails failed"
  exit 1
fi
