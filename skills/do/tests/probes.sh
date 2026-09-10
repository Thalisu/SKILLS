#!/usr/bin/env bash
# probes.sh: the contract of the ticket Playbook's probes, scripts/ticket-door.sh,
# scripts/resume-state.sh, scripts/gate.sh and scripts/flows.sh, exercised in a throwaway git
# repository, and the sentences of the Playbook's reference and the shared mechanics that name
# them. Run: bash skills/do/tests/probes.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
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

g() { git -c user.email=t@example.com -c user.name=t "$@"; }
check() { # $1 label, $2 expected exit, $3 actual exit, $4.. whole lines that must appear; output in $out
  local label="$1" want="$2" rc="$3"; shift 3
  local ok=1 line
  [ "$rc" = "$want" ] || ok=0
  for line in "$@"; do grep -qxF -- "$line" <<<"$out" || ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else
    echo "FAIL  $label (exit $rc, wanted $want)"; echo "      ${out//$'\n'/$'\n'      }"; fails=$((fails + 1)); fi
}
absent() { # $1 label, $2 a line prefix that must not appear
  if grep -q "^$2" <<<"$out"; then echo "FAIL  $1 (found: $2)"; fails=$((fails + 1)); else echo "ok    $1"; fi
}
ordered() { # $1 label, $2.. key prefixes that must appear in this order in $out
  local label="$1"; shift
  local last=0 n key ok=1
  for key in "$@"; do
    n="$(grep -n "^$key" <<<"$out" | awk -F: -v l="$last" '$1 > l { print $1; exit }')"
    [ -n "$n" ] || ok=0
    last="${n:-$last}"
  done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else echo "FAIL  $label"; echo "      ${out//$'\n'/$'\n'      }"; fails=$((fails + 1)); fi
}
run() { local script="$1"; shift; rc=0; out="$(bash "$script" "$@" 2>&1)" || rc=$?; }
ticket() { # $1 file name, $2 status line(s), $3 blocked-by value
  printf '# %s: %s\n\n**What to build:** something.\n\n**Blocked by:** %s\n\n%s\n\n- [ ] one\n\n## Evidence\n' \
    "${1%%-*}" "Title of ${1%.md}" "$3" "$2" > "$issues/$1"
}

cd "$tmp" || exit 1
git init -q -b main main && cd main || exit 1
git config gc.auto 0; git config maintenance.auto false
printf '.scratch/\n' > .gitignore
printf 'one\n' > notes.txt
g add -A; g commit -q -m fixture
top="$(pwd -P)"
issues=".scratch/20260101-feat/issues"
mkdir -p "$issues"
ticket 01-first.md '**Status:** resolved' 'None (can start immediately)'
printf 'a review\n**Status:** claimed\n' > "$issues/01-first.review.md"
printf 'a digest\n' > "$issues/01-first.digest.md"
ticket 02-second.md '**Status:** ready-for-agent' '01, Title of 01-first'
ticket 03-third.md '**Status:** ready-for-agent' '01: Title of 01-first; 02 Title of 02-second'
ticket 04-claimed.md '**Status:** claimed' 'None (can start immediately).'
ticket 05-twice.md $'**Status:** ready-for-agent\n\n**Status:** resolved' 'None (can start immediately)'
ticket 06-orphan.md '**Status:** ready-for-agent' '19, A Ticket nobody wrote'
ticket 07-gone.md '**Status:** claimed' 'None (can start immediately)'
ticket 08-unwalked.md '**Status:** done' 'None (can start immediately)'
ticket 09-stale.md '**Status:** ready-for-agent' 'None (can start immediately)'
ticket 10-blind.md '**Status:** ready-for-agent' '11, A Ticket with no status'
printf '# 11: No status\n\n**What to build:** x.\n' > "$issues/11-nostatus.md"
ticket 12-one.md '**Status:** resolved' 'None (can start immediately)'
ticket 12-two.md '**Status:** resolved' 'None (can start immediately)'
ticket 13-double.md '**Status:** ready-for-agent' '12, One of two'
ticket 14-comma.md '**Status:** ready-for-agent' '01 Title of 01-first, 02 Title of 02-second'
ticket 15-and.md '**Status:** ready-for-agent' '01 and 02'
ticket 16-lines.md '**Status:** ready-for-agent' $'01 Title of 01-first\n02 Title of 02-second'
ticket 17-unsplit.md '**Status:** ready-for-agent' '01 Title of 01-first (after 02)'
echo ".claude/worktrees/" >> .git/info/exclude
git worktree add -q .claude/worktrees/do-claimed -b do/claimed
git worktree add -q .claude/worktrees/do-stale -b do/stale
wt="$top/.claude/worktrees/do-claimed"

echo "# ticket-door.sh: a Ticket the run may start"
run "$door" "$issues/02-second.md"
check "a ready Ticket whose blocker is resolved starts" 0 "$rc" \
  "ticket=$issues/02-second.md" "title=02: Title of 02-second" "status=ready-for-agent" \
  "blocker=01 resolved $issues/01-first.md" "slug=second" "worktree=none" "loop=fallback" \
  "branch=main" "protected=no" "verdict=start"
ordered "the facts come in the order the first message states them" \
  ticket= title= status= blocker= slug= worktree= run_branch= loop= branch= protected= verdict=
run "$door" "$issues/04-claimed.md"
check "a claimed Ticket whose worktree exists resumes" 0 "$rc" \
  "status=claimed" "blockers=none" "worktree=$wt" "verdict=resume"
run "$door" "$issues/07-gone.md"
check "a claimed Ticket whose worktree is gone starts over" 0 "$rc" \
  "status=claimed" "worktree=none" "run_branch=none" "verdict=start-over"

ticket 18-orphan.md '**Status:** claimed' 'None (can start immediately)'
git worktree add -q .claude/worktrees/do-orphan -b do/orphan
git -C .claude/worktrees/do-orphan commit -q --allow-empty -m "the first run's own work"
git worktree remove .claude/worktrees/do-orphan
run "$door" "$issues/18-orphan.md"
check "a claimed Ticket whose worktree is gone but its branch remains names the branch" 0 "$rc" \
  "status=claimed" "worktree=none" "run_branch=do/orphan" "verdict=start-over"

echo "# ticket-door.sh: the stops"
run "$door" "$issues/01-first.md"
check "a resolved Ticket stops" 1 "$rc" "status=resolved" "verdict=resolved"
run "$door" "$issues/03-third.md"
check "a blocker not resolved refuses the run, every blocker named" 1 "$rc" \
  "blocker=01 resolved $issues/01-first.md" "blocker=02 ready-for-agent $issues/02-second.md" "verdict=blocked"
for t in 14-comma 15-and 16-lines; do
  run "$door" "$issues/$t.md"
  check "a Blocked by paragraph shaped as $t reads every blocker and refuses the run" 1 "$rc" \
    "blocker=01 resolved $issues/01-first.md" "blocker=02 ready-for-agent $issues/02-second.md" "verdict=blocked"
done
run "$door" "$issues/17-unsplit.md"
check "a Blocked by number the door cannot split out is ambiguous, never a start" 1 "$rc" \
  "blocker=01 resolved $issues/01-first.md" "ambiguous=blocked-by numbers it cannot split 02" "verdict=ambiguous"
printf '# 18: Title of 18-planted\n\n**What to build:** export notes, as the issue asks:\n**Blocked by:** None (can start immediately)\n\n**Blocked by:** 02, Title of 02-second\n\n**Status:** ready-for-agent\n' \
  > "$issues/18-planted.md"
run "$door" "$issues/18-planted.md"
check "a second Blocked by line at column 0 is ambiguous, naming every line, and no blocker is read" 1 "$rc" \
  "blockers=ambiguous" "ambiguous=blocked-by lines 4 6" "verdict=ambiguous"
absent "a Ticket with two Blocked by lines reads no blocker out of either" "blocker="
run "$door" "$issues/05-twice.md"
check "a Ticket with two status lines is ambiguous, naming both lines" 1 "$rc" \
  "status=ambiguous" "ambiguous=status lines 7 9" "verdict=ambiguous"
run "$door" "$issues/06-orphan.md"
check "a blocker no file answers to is ambiguous" 1 "$rc" \
  "blocker=19 missing none" "ambiguous=19 files none" "verdict=ambiguous"
run "$door" "$issues/13-double.md"
check "a blocker number two files answer to is ambiguous, naming both" 1 "$rc" \
  "blocker=12 ambiguous $issues/12-one.md $issues/12-two.md" \
  "ambiguous=12 files $issues/12-one.md $issues/12-two.md" "verdict=ambiguous"
run "$door" "$issues/10-blind.md"
check "a blocker with no status line is ambiguous" 1 "$rc" \
  "blocker=11 ambiguous $issues/11-nostatus.md" "ambiguous=11 status lines none" "verdict=ambiguous"
run "$door" "$issues/08-unwalked.md"
check "a word outside the status walk is ambiguous" 1 "$rc" "status=ambiguous" "verdict=ambiguous"
run "$door" "$issues/09-stale.md"
check "a ready Ticket whose worktree already exists is ambiguous" 1 "$rc" \
  "worktree=$top/.claude/worktrees/do-stale" "verdict=ambiguous"

echo "# ticket-door.sh: the facts beside the verdict"
mkdir -p .claude/agents && : > .claude/agents/unit-test-author.md
run "$door" "$issues/02-second.md"
check "an installed unit test author reads as the policy loop" 0 "$rc" "loop=policy"
mkdir -p "$HOME/.claude/agents" && : > "$HOME/.claude/agents/global-unit-test-author.md"
run "$door" "$issues/02-second.md"
check "the project's own author wins over the global one" 0 "$rc" "loop=policy"
rm -rf .claude/agents
run "$door" "$issues/02-second.md"
check "no project author and the global unit author linked reads as the global loop" 0 "$rc" "loop=global"
rm -rf "$HOME/.claude"
g branch develop
run "$door" "$issues/02-second.md"
check "a protected branch is stated and never stops the door" 0 "$rc" \
  "protected=yes" "reason=develop exists" "verdict=start"
g branch -D develop >/dev/null
cd "$wt" || exit 1
run "$door" "$issues/02-second.md"
check "a relative path run from the worktree resolves in the main checkout" 0 "$rc" \
  "ticket=$issues/02-second.md" "branch=main" "verdict=start"
cd "$top" || exit 1

echo "# ticket-door.sh: usage"
run "$door"; check "no argument is a usage error" 2 "$rc"
run "$door" "$issues/99-nothing.md"; check "a Ticket that is not there is an error" 2 "$rc"
cd /; run "$door" x; check "outside a repository is an error" 2 "$rc"; cd "$top" || exit 1

echo "# resume-state.sh: a clean worktree"
resume="$skill/scripts/resume-state.sh"
fork="$(git rev-parse HEAD)"
printf 'two\n' >> "$wt/notes.txt"
g -C "$wt" commit -q -am "feat: archive a note" -m "Behaviour: Picking Archive on a note removes it from the list"
printf 'three\n' >> "$wt/notes.txt"
g -C "$wt" commit -q -am "chore: tidy the notes"
first="$(git rev-parse --short do/claimed~1)"; second="$(git rev-parse --short do/claimed)"
run "$resume" "$issues/04-claimed.md"
check "a clean worktree resumes at the build loop, every commit with its behaviour" 0 "$rc" \
  "worktree=$wt" "branch=do/claimed" "rebase=none" "base=main" "merge_base=$fork" \
  "commit=$first feat: archive a note" "behaviour=$first Picking Archive on a note removes it from the list" \
  "commit=$second chore: tidy the notes" "behaviour=$second none" "commits=2" "review=none" "verdict=build"
ordered "the resume state comes in its key order" \
  worktree= branch= rebase= base= merge_base= commit= behaviour= commits= review= verdict=
absent "a clean worktree lists no uncommitted file" "uncommitted="

echo "# resume-state.sh: uncommitted work"
printf 'half written\n' >> "$wt/notes.txt"; printf 'x\n' > "$wt/a b.txt"
run "$resume" "$issues/04-claimed.md"
check "uncommitted work asks before anything, one line per file" 1 "$rc" \
  "uncommitted= M notes.txt" 'uncommitted=?? "a b.txt"' "commits=2" "verdict=ask"
out="$(git -C "$wt" status --short)"
check "the probe leaves the uncommitted work where it was" 0 0 " M notes.txt" '?? "a b.txt"'
git -C "$wt" checkout -q -- notes.txt; rm "$wt/a b.txt"

# ADR 0033: the review runs once per run, so a branch whose Review already sits beside the Ticket
# resumes at the landing through fix, never at a second review.
echo "# resume-state.sh: a branch the review already read"
review_file() { # $1 the Review's Commit: sha, $2 its Security Axis line
  printf '# Review: 04\n\nCommit: %s\n\n## Axes\n\n- Correctness: 0 findings\n- Security: %s\n' "$1" "$2" \
    > "$issues/04-claimed.review.md"
}
review_file "$second" "0 findings"
run "$resume" "$issues/04-claimed.md"
check "a Review of a commit this branch has been at, every Axis run, sends the resume to the landing" 4 "$rc" \
  "review=$top/$issues/04-claimed.review.md" "commits=2" "verdict=land"
absent "a Review that counts is never reported skipped" "review_skipped="

echo "# resume-state.sh: a Review that does not count"
stale="$(g commit-tree -m "an earlier branch's commit" "HEAD^{tree}")"
review_file "$(git rev-parse --short "$stale")" "0 findings"
run "$resume" "$issues/04-claimed.md"
check "a Review of a commit this branch was never at is an earlier run's, and the review runs" 0 "$rc" \
  "review_skipped=stale $top/$issues/04-claimed.review.md" "review=none" "verdict=build"
review_file "$second" "not run, the reviewer did not return"
run "$resume" "$issues/04-claimed.md"
check "a Review with an Axis that did not run is an unfinished review, and the review runs" 0 "$rc" \
  "review_skipped=axis-not-run $top/$issues/04-claimed.review.md" "review=none" "verdict=build"
review_file "$second" "0 findings"

echo "# resume-state.sh: a rebase the integration left open"
printf 'one\nmain side\n' > notes.txt; g commit -q -am "main moves"
g -C "$wt" -c rerere.enabled=false rebase main >/dev/null 2>&1
run "$resume" "$issues/04-claimed.md"
check "a worktree left mid-rebase goes to the integration, its branch read from the rebase state" 3 "$rc" \
  "branch=do/claimed" "rebase=open" "conflicted=notes.txt" "commits=2" \
  "review=$top/$issues/04-claimed.review.md" "verdict=integration"
git -C "$wt" rebase --abort
rm "$issues/04-claimed.review.md"

echo "# resume-state.sh: a branch left behind a target that moved"
# The state a `not landed: target moved` return leaves: every behaviour committed, the tree clean, no
# rebase open, and the developer's branch ahead of the merge base. The resume reads it as a branch to
# build on, so the run re-derives its list, ticks every line and goes on at the gate.
run "$resume" "$issues/04-claimed.md"
check "a branch behind a moved target resumes with every commit and its behaviour listed" 0 "$rc" \
  "rebase=none" "merge_base=$fork" "commit=$first feat: archive a note" \
  "behaviour=$first Picking Archive on a note removes it from the list" "commits=2" "verdict=build"

echo "# resume-state.sh: nothing to resume"
git -C "$wt" checkout -q --detach
run "$door" "$issues/04-claimed.md"
check "the door still says resume for a claimed Ticket's worktree on a detached HEAD" 0 "$rc" \
  "worktree=$wt" "verdict=resume"
run "$resume" "$issues/04-claimed.md"; check "a detached HEAD with no rebase open is not a resumable worktree" 2 "$rc" \
  "$wt is on a detached HEAD with no rebase open: nothing to resume"
git -C "$wt" checkout -q do/claimed
run "$resume" "$issues/07-gone.md"; check "a Ticket with no worktree has nothing to resume" 2 "$rc"
run "$resume"; check "no argument is a usage error" 2 "$rc"

echo "# a worktree list longer than one pipe read"
for i in $(seq -w 1 60); do git worktree add -q --detach --no-checkout ".claude/worktrees/zz-$i"; done
out="$(git worktree list --porcelain | grep '^worktree ' | sed -n 2p)"
check "the Ticket's worktree is the first one listed after the main checkout" 0 0 "worktree $wt"
run "$door" "$issues/04-claimed.md"
check "the door finds the Ticket's worktree listed first among sixty more and resumes" 0 "$rc" \
  "worktree=$wt" "verdict=resume"
run "$resume" "$issues/04-claimed.md"
check "the resume finds the Ticket's worktree listed first among sixty more" 0 "$rc" \
  "worktree=$wt" "verdict=build"

echo "# the reference names each probe with its command line"
ticket_md="$skill/references/ticket.md"
has() { # $1 label, $2 file, $3.. fixed strings that must appear in the file
  local label="$1" file="$2"; shift 2
  local ok=1 s
  [ -f "$file" ] || ok=0
  for s in "$@"; do [ "$ok" = 1 ] && grep -qF -- "$s" "$file" || ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else echo "FAIL  $label ($file)"; fails=$((fails + 1)); fi
}
header_has() { # $1 label, $2 file, $3 fixed string that must appear in its first $4 lines
  if sed -n "1,${4}p" "$2" | grep -qF -- "$3"; then echo "ok    $1"; else echo "FAIL  $1 ($2)"; fails=$((fails + 1)); fi
}
header_has "the door script's header carries its own command line" "$door" "#   ticket-door.sh <the Ticket's path>" 12
header_has "the resume script's header carries its own command line" "$resume" "#   resume-state.sh <the Ticket's path>" 12
header_has "this test's header carries its own command line" "$here/probes.sh" "Run: bash skills/do/tests/probes.sh" 7
has "the door runs its script, named with its command line" "$ticket_md" \
  "\`bash <skill-dir>/scripts/ticket-door.sh <the Ticket's path>\`"
has "the resume reads its script, named with its command line" "$ticket_md" \
  "\`bash <skill-dir>/scripts/resume-state.sh <the Ticket's path>\`"
has "every ambiguous verdict of the door is refused in one line naming its cause, nothing written" "$ticket_md" \
  "A Ticket whose own status the script prints as \`ambiguous\`" \
  "is refused in one line naming the cause from its \`ambiguous=\` line." \
  "Nothing is written; the developer sets the status line by hand." \
  "A \`ready-for-agent\` Ticket whose \`do/<slug>\` worktree already exists is refused in one line" \
  "naming the worktree. Nothing is written"
has "the first message states the door script's facts and marks no step skipped" "$ticket_md" \
  "off the lines the door script printed" \
  "The checklist above, verbatim, with no step marked skipped"

has "a resume the review already read goes to the Gate and the fix call, never a second review" "$ticket_md" \
  "On \`verdict=land\`" "never a second review"

echo "# the review runs once per run (ADR 0033)"
mech="$skill/references/mechanics.md"
has "the review runs once per run, and what comes after it lands through the fix call" "$mech" \
  "Run once per run" "never a second review" "\`fix\` with the Review's location" \
  "the \`command=\` line the gate printed"
has "a red flow lands through the fix call on the same Review" "$mech" \
  "handed to the fix call on the same Review"
has "a resume says why a Review beside the Ticket does not count" "$ticket_md" "review_skipped="
has "a bug-fix resume counts only a Review of this branch whose every Axis ran" "$skill/references/bug-fix.md" \
  "git log -g --format=%H refs/heads/do/<slug>" "\`not run\`"
has "a Finding the first call left not fixed goes to a Fixer again on the fix call" "$mech" \
  "left \`not fixed\` goes to a Fixer again"
for f in "$mech" "$ticket_md" "$skill/references/bug-fix.md" "$skill/references/refactoring.md"; do
  if grep -qF -- "second review call" "$f"; then echo "FAIL  no Playbook hands a red flow to a second review call ($f)"; fails=$((fails + 1))
  else echo "ok    no second review call in ${f##*/}"; fi
done

has "the resume says what the run does when the script exits 2 after the door's resume" "$ticket_md" \
  "Exit 2 after the door's \`resume\`" \
  "the run stops as blocked in one line naming the worktree and the script's reason"

echo "# the resume asks before it discards"
has "uncommitted work is asked about on the probe's ask, and nothing goes without the answer" "$ticket_md" \
  "On \`verdict=ask\`" \
  "the run asks before discarding them" \
  "A yes discards them" "restarts red-first" \
  "a no stops the run with the worktree as it is, the reply naming it and its branch" \
  "Nothing is discarded without the answer"

echo "# a resume after a landing that did not happen"
has "a resume with every behaviour committed goes on at the gate, never waiting on an empty loop" "$ticket_md" \
  "When every line of the list is ticked" \
  "step 5 reads \`done: resumed\`" \
  "the integration with the developer present"

echo "# a skip is written when its step is reached"
reply_md="$skill/references/reply.md"
has "each step of the ticket checklist writes its own skip when it is reached" "$ticket_md" \
  "Each step writes its own skip, with its reason, when the run reaches it"
has "the reply's Skipped section holds only the steps the run reached" "$reply_md" \
  "only the steps the run reached"
has "a blocked reply names where it stopped and lists no step after it" "$reply_md" \
  "names the step it stopped at" \
  "lists no step after it as skipped"

echo "# gate.sh: every check green"
gate="$skill/scripts/gate.sh"
cd "$top" || exit 1
run "$gate" "suite=printf 'ran\n'" "typecheck=true"
check "a green gate prints one key and value line per check and exits 0" 0 "$rc" \
  "suite=green" "typecheck=green" "verdict=green"
ordered "the gate prints its command line first, then each check in the order given" \
  command= suite= typecheck= verdict=
absent "a green check prints none of its output" "ran"
same() { # $1 label, $2 expected output; the whole of $out must equal it
  if [ "$out" = "$2" ]; then echo "ok    $1"; else
    echo "FAIL  $1"; echo "      ${out//$'\n'/$'\n'      }"; fails=$((fails + 1)); fi
}
rerun() { # reruns the command= line the last run printed first, the way a reviewer pastes it
  local line; line="$(sed -n '1s/^command=//p' <<<"$out")"
  rc=0; out="$(eval "$line" 2>&1)" || rc=$?
}
first_out="$out"; rerun
same "the command line the gate prints reruns it for the same answer" "$first_out"
run "$gate"; check "no check is a usage error" 2 "$rc"
run "$gate" "true"; check "a check with no key is a usage error" 2 "$rc"
header_has "the gate script's header carries its own command line" "$gate" "#   gate.sh " 12
if script -qec true /dev/null </dev/null >/dev/null 2>&1; then
  run "$gate" "stdin=test ! -t 0" </dev/null
  bare_out="$out"
  out="$(script -qec "bash $(printf %q "$gate") 'stdin=test ! -t 0'" /dev/null </dev/null 2>&1 | tr -d '\r')"
  pty_verdict="$(grep '^verdict=' <<<"$out")"
  out="$bare_out"
  check "a check probing its stdin reads the same verdict under a pty as without one" 0 "$rc" \
    "stdin=green" "$pty_verdict"
else
  echo "skip  a check probing its stdin reads the same verdict under a pty as without one (no util-linux script)"
fi

echo "# gate.sh: a red check"
run "$gate" "suite=true" "lint=seq 1 100; echo broke >&2; exit 4" "typecheck=echo 'x.ts:3 error'; exit 2" "format=true"
log="$(sed -n 's/^lint=red exit=4 log=//p' <<<"$out")"
tlog="$(sed -n 's/^typecheck=red exit=2 log=//p' <<<"$out")"
check "a red check prints its key, its exit and the file holding its full output, and the gate exits 1" 1 "$rc" \
  "suite=green" "lint=red exit=4 log=$log" "typecheck=red exit=2 log=$tlog" "format=green" "verdict=red" \
  "  [capped: the last 20 of 101 lines]" "  99" "  broke" "  x.ts:3 error"
ordered "the checks after a red one still run, in the order given" command= suite= lint= typecheck= format= verdict=
absent "the capped block leaves out the lines before its last twenty" "  80$"
[ "$(grep -c '^  ' <<<"$out")" = 22 ] && echo "ok    the failing blocks are capped, and a short one is printed whole" ||
  { echo "FAIL  the failing blocks are capped, and a short one is printed whole"; fails=$((fails + 1)); }
gate_out="$out"
out="$(cat "$log" 2>/dev/null)"
check "the file the red line names holds the full output" 0 0 "1" "50" "100" "broke"
case "$log" in "$tmp"/do-gate.*) echo "ok    the gate's red logs stay inside this run's temp dir" ;;
  *) echo "FAIL  the gate's red logs stay inside this run's temp dir (log=$log)"; fails=$((fails + 1)) ;; esac
out="$(git status --short)"; same "the gate writes nothing in the tree it checks" ""
out="$gate_out"
run "$gate" "unit=printf 'boom'; exit 1" "lint=true"
check "a red check whose output ends without a newline leaves the next key and the verdict on lines of their own" 1 "$rc" \
  "  boom" "lint=green" "verdict=red"

echo "# gate.sh: a check the environment stops"
logof() { sed -n "s/^$1=[a-z]* exit=[0-9]* log=\([^ ]*\).*/\1/p" <<<"$out"; }
run "$gate" --infra 'test database is not up' "suite=exit 1" "e2e=no-such-runner-for-the-gate" \
  "api=echo 'connect ECONNREFUSED 127.0.0.1:5432'; exit 1" "db=echo 'FATAL: the test database is not up'; exit 1"
check "a runner that cannot start and a service down are blocked, each cause named, and blocked outweighs red" 3 "$rc" \
  "suite=red exit=1 log=$(logof suite)" \
  "e2e=blocked exit=127 log=$(logof e2e) cause=runner cannot start" \
  "api=blocked exit=1 log=$(logof api) cause=connect ECONNREFUSED 127.0.0.1:5432" \
  "db=blocked exit=1 log=$(logof db) cause=FATAL: the test database is not up" \
  "verdict=blocked"
run "$gate" --infra; check "an --infra with no pattern is a usage error" 2 "$rc"
header_has "the gate script's header carries its full command line" "$gate" \
  "#   gate.sh [--infra <pattern>]... <key>=<command>..." 12

echo "# flows.sh: the affected flows, from the main checkout"
# A flow key holds a slash, so this reading takes `|` as its sed delimiter where logof takes `/`.
flowlog() { sed -n "s|^$1=[a-z]* exit=[0-9]* log=\([^ ]*\).*|\1|p" <<<"$out"; }
flows="$skill/scripts/flows.sh"
mkdir -p e2e
printf 'exit 0\n' > e2e/login.flow
printf 'echo "ran in $(pwd -P)"; exit 1\n' > e2e/export.flow
cd "$wt" || exit 1
run "$flows" 'bash {}' e2e/login.flow e2e/export.flow
check "each flow runs from the main checkout through the single-flow command, a red one with its block" 1 "$rc" \
  "e2e/login.flow=green" "e2e/export.flow=red exit=1 log=$(flowlog e2e/export.flow)" "  ran in $top" "verdict=red"
ordered "the flows print their command line first, then each flow in the order given" \
  "command=bash $(printf %q "$(cd "$skill/scripts" && pwd -P)/flows.sh") " e2e/login.flow= e2e/export.flow= verdict=
run "$flows" 'bash {}' e2e/login.flow
first_out="$out"; rerun
same "the command line the flows print reruns them for the same answer" "$first_out"
run "$flows" bash e2e/login.flow
check "a single-flow command with no {} takes the flow at its end" 0 "$rc" "e2e/login.flow=green" "verdict=green"
run "$flows" 'no-such-flow-runner {}' e2e/login.flow
check "a flow runner that cannot start is blocked, its cause named" 3 "$rc" \
  "e2e/login.flow=blocked exit=127 log=$(flowlog e2e/login.flow) cause=runner cannot start" "verdict=blocked"
run "$flows"; check "no single-flow command is a usage error" 2 "$rc"
run "$flows" 'bash {}'; check "no flow is a usage error" 2 "$rc"
marker="$tmp/flow-injected"
run "$flows" 'bash {}' "e2e/x=\$(touch $marker).flow"
check "a flow name holding = is a usage error" 2 "$rc"
[ ! -e "$marker" ] && echo "ok    a flow name holding = runs nothing it carries" ||
  { echo "FAIL  a flow name holding = runs nothing it carries ($marker exists)"; fails=$((fails + 1)); }
header_has "the flows script's header carries its own command line" "$flows" \
  "#   flows.sh [--infra <pattern>]... <single-flow command> <flow>..." 12
cd "$top" || exit 1

echo "# the shared mechanics run the gate and the flows from their scripts"
mechanics_md="$skill/references/mechanics.md"
has "the gate runs from its script, named with its command line" "$mechanics_md" \
  "\`bash <skill-dir>/scripts/gate.sh [--infra <pattern>]... <key>=<command>...\`"
has "the affected flows run from their script, named with its command line and printed first" "$mechanics_md" \
  "\`bash <skill-dir>/scripts/flows.sh [--infra <pattern>]... <single-flow command> <flow>...\`" \
  "its \`command=\` line printed first"
has "a red gate goes back to the loop on the block already in the thread, never a rerun" "$mechanics_md" \
  "the failing block is already in the thread, so the work goes back to the build loop as one more" \
  "unit without rerunning the command, then the whole gate again"
has "an environment failure the script reads as blocked stops the run, and a waiver is debt" "$mechanics_md" \
  "\`verdict=blocked\`" "stops as blocked and names the cause from its \`cause=\` line" \
  "a waiver is recorded as debt in the reply, never as green"
has "the full suite or remote run stays the session's question, and a no is debt with the close still made" "$mechanics_md" \
  "The script asks nothing" \
  "A no records each flow that needed it as not run, leaves the criterion it would have proven" \
  "records the waiver as debt in the reply; the close still happens"
has "the ticket Playbook's gate and verification steps name the scripts" "$ticket_md" \
  "\`scripts/gate.sh\`" "\`scripts/flows.sh\`"

echo
if [ "$fails" = 0 ]; then echo "probes: all checks passed"; else echo "probes: $fails failed"; exit 1; fi
