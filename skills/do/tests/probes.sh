#!/usr/bin/env bash
# probes.sh: the contract of the ticket Playbook's probes, scripts/ticket-door.sh and
# scripts/resume-state.sh, exercised in a throwaway git repository, and the sentences of the
# Playbook's reference that name them. Run: bash skills/do/tests/probes.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
skill="$here/.."
door="$skill/scripts/ticket-door.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

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
  ticket= title= status= blocker= slug= worktree= loop= branch= protected= verdict=
run "$door" "$issues/04-claimed.md"
check "a claimed Ticket whose worktree exists resumes" 0 "$rc" \
  "status=claimed" "blockers=none" "worktree=$wt" "verdict=resume"
run "$door" "$issues/07-gone.md"
check "a claimed Ticket whose worktree is gone starts over" 0 "$rc" \
  "status=claimed" "worktree=none" "verdict=start-over"

echo "# ticket-door.sh: the stops"
run "$door" "$issues/01-first.md"
check "a resolved Ticket stops" 1 "$rc" "status=resolved" "verdict=resolved"
run "$door" "$issues/03-third.md"
check "a blocker not resolved refuses the run, every blocker named" 1 "$rc" \
  "blocker=01 resolved $issues/01-first.md" "blocker=02 ready-for-agent $issues/02-second.md" "verdict=blocked"
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
rm -rf .claude/agents
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
  "commit=$second chore: tidy the notes" "behaviour=$second none" "commits=2" "verdict=build"
ordered "the resume state comes in its key order" \
  worktree= branch= rebase= base= merge_base= commit= behaviour= commits= verdict=
absent "a clean worktree lists no uncommitted file" "uncommitted="

echo "# resume-state.sh: uncommitted work"
printf 'half written\n' >> "$wt/notes.txt"; printf 'x\n' > "$wt/a b.txt"
run "$resume" "$issues/04-claimed.md"
check "uncommitted work asks before anything, one line per file" 1 "$rc" \
  "uncommitted= M notes.txt" 'uncommitted=?? "a b.txt"' "commits=2" "verdict=ask"
out="$(git -C "$wt" status --short)"
check "the probe leaves the uncommitted work where it was" 0 0 " M notes.txt" '?? "a b.txt"'
git -C "$wt" checkout -q -- notes.txt; rm "$wt/a b.txt"

echo "# resume-state.sh: a rebase the integration left open"
printf 'one\nmain side\n' > notes.txt; g commit -q -am "main moves"
g -C "$wt" -c rerere.enabled=false rebase main >/dev/null 2>&1
run "$resume" "$issues/04-claimed.md"
check "a worktree left mid-rebase goes to the integration, its branch read from the rebase state" 3 "$rc" \
  "branch=do/claimed" "rebase=open" "conflicted=notes.txt" "commits=2" "verdict=integration"
git -C "$wt" rebase --abort

echo "# resume-state.sh: nothing to resume"
git -C "$wt" checkout -q --detach
run "$resume" "$issues/04-claimed.md"; check "a detached HEAD with no rebase open is not a resumable worktree" 2 "$rc"
git -C "$wt" checkout -q do/claimed
run "$resume" "$issues/07-gone.md"; check "a Ticket with no worktree has nothing to resume" 2 "$rc"
run "$resume"; check "no argument is a usage error" 2 "$rc"

echo
if [ "$fails" = 0 ]; then echo "probes: all checks passed"; else echo "probes: $fails failed"; exit 1; fi
