#!/usr/bin/env bash
# integration.sh: the conflict resolution blocks that mechanics.md and fix.md hand a session, run
# over hostile, resumed and glob-named conflicted paths.
# Run: bash skills/do/tests/integration.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
repo="$(cd "$here/../../.." && pwd -P)"
refs="$repo/skills/do/references"
mech="$refs/mechanics.md"
fails=0
# Each file's resolution blocks
# are run the way a session runs them, any placeholder filled in with the path, over a conflicted
# path that carries a single quote and a command substitution: the substitution must never fire,
# and the path must come out resolved and staged.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
resolves_safely() { # $1 label, $2 file, $3 heading
  local label="$1" dir evil="x'\$(id>PWNED)'.txt" block rc
  dir="$tmp/$(basename "$2" .md)"
  mkdir -p "$dir" || return
  g -C "$dir" init -q -b main
  # Git's background maintenance races the trap's cleanup and leaves the repository undeletable.
  g -C "$dir" config gc.auto 0
  g -C "$dir" config maintenance.auto false
  g -C "$dir" config merge.conflictStyle merge
  printf 'a\nb\nc\n' >"$dir/$evil"
  g -C "$dir" add -A
  g -C "$dir" commit -qm base
  g -C "$dir" branch fix
  printf 'a\nb\nTARGET\nc\n' >"$dir/$evil"
  g -C "$dir" commit -qam target
  g -C "$dir" switch -q fix
  printf 'a\nb\nINCOMING\nc\n' >"$dir/$evil"
  g -C "$dir" commit -qam incoming
  g -C "$dir" -c rerere.enabled=false rebase main >/dev/null 2>&1
  rc=0
  (cd "$dir" && bash "$repo/skills/do/scripts/conflict-class.sh") >/dev/null 2>&1 || rc=$?
  expect "the path in $label's fixture is classed mechanical, so it reaches the block" test "$rc" = 0
  block="$(blocks_of "$2" "$3")"
  expect "$label carries a resolution block to run" test -n "$block"
  mkdir -p "$dir/.scratch"
  block="${block//"<skill-dir>"/"$repo/skills/do"}"
  block="${block//"<the ledger>"/"$dir/.scratch/run.ledger.md"}"
  block="${block//"<path>"/"$evil"}"
  block="${block//"<base>"/"$dir.base"}"
  block="${block//"<target>"/"$dir.target"}"
  block="${block//"<incoming>"/"$dir.incoming"}"
  printf '%s\n' "$block" >"$dir.sh"
  (cd "$dir" && bash "$dir.sh") >/dev/null 2>&1
  expect "$label's resolution runs no command a conflicted path carries" \
    test -z "$(find "$tmp" -name PWNED 2>/dev/null)"
  expect "$label's resolution leaves that path resolved in both sides' base order and staged" \
    test "$(g -C "$dir" show ":$evil" 2>/dev/null)" = "$(printf 'a\nb\nTARGET\nINCOMING\nc')"
}
resolves_safely "do's integration" "$mech" "## The integration"
resolves_safely "the review's landing" "$repo/skills/do-code-review/references/fix.md" \
  "### A target that moved while the review ran"

# A resumed run can meet a stop the developer already worked on and never staged: one file written as
# the union of its stages, one resolved by hand. The all-mechanical blocks run as mechanics.md prints
# them: the hand resolution is the developer's answer and comes out as they wrote it, staged, and the
# union file's rewrite reaches the bytes it already held.
resumed_stop_keeps_the_hand_resolution() {
  local write mark rc
  write="$(blocks_of "$mech" "## The integration" "**A rebase that stopped.**" 1)"
  mark="$(blocks_of "$mech" "## The integration" "**A rebase that stopped.**" 2)"
  expect "the all-mechanical stop carries its union block" test -n "$write"
  expect "the all-mechanical stop carries its staging block" test -n "$mark"
  printf '%s\n' "${write//"<skill-dir>"/"$repo/skills/do"}" >"$tmp/write.sh"

  fresh resumed-stop
  mkdir -p .scratch
  mark="${mark//"<skill-dir>"/"$repo/skills/do"}"
  printf '%s\n' "${mark//"<the ledger>"/"$PWD/.scratch/run.ledger.md"}" >"$tmp/mark.sh"
  printf 'a\nb\nc\nd\ne\nf\n' >union.txt
  printf 'a\nb\nc\nd\ne\nf\n' >hand.txt
  commit base
  g branch inc
  printf 'a\nTARGET ONE\nb\nc\nd\ne\nTARGET TWO\nf\n' >union.txt
  printf 'a\nTARGET ONE\nb\nc\nd\ne\nTARGET TWO\nf\n' >hand.txt
  commit target
  g switch -q inc
  printf 'a\nINCOMING ONE\nb\nc\nd\ne\nINCOMING TWO\nf\n' >union.txt
  printf 'a\nINCOMING ONE\nb\nc\nd\ne\nINCOMING TWO\nf\n' >hand.txt
  commit incoming
  g -c rerere.enabled=false -c rerere.autoupdate=false rebase refs/heads/main >/dev/null 2>&1
  union_of union.txt >union.txt
  printf 'a\nONE, merged by hand\nb\nc\nd\ne\nTWO, merged by hand\nf\n' >hand.txt
  cp union.txt "$tmp/union.before"
  cp hand.txt "$tmp/hand.before"

  rc=0
  # shellcheck disable=SC2034  # lib.sh's check reads $out
  out="$(bash "$repo/skills/do/scripts/conflict-class.sh" 2>&1)" || rc=$?
  check "the resumed stop is classed all-mechanical with the hand-resolved file trusted, so it reaches the block" \
    0 "$rc" "trusted hand.txt whole-file hand-resolved" "verdict=mechanical mechanical=2 contested=0 trusted=1"

  bash "$tmp/write.sh" >/dev/null 2>&1
  expect "a resumed all-mechanical stop keeps the file resolved by hand byte for byte as the developer wrote it" \
    cmp -s hand.txt "$tmp/hand.before"
  expect "and rewrites the file already written as its stages' union to the bytes it already held" \
    cmp -s union.txt "$tmp/union.before"

  bash "$tmp/mark.sh" >/dev/null 2>&1
  g show ":0:hand.txt" >"$tmp/hand.staged" 2>/dev/null
  expect "and the staging block stages the file resolved by hand with the developer's bytes" \
    cmp -s "$tmp/hand.staged" "$tmp/hand.before"
  expect "after the staging block nothing at the resumed stop is left unmerged" \
    test -z "$(g ls-files -u)"
  cd "$repo" || exit 1
}
resumed_stop_keeps_the_hand_resolution

# A conflicted path is a name a side chose, and git reads a path argument as a glob pathspec unless
# told otherwise, `[` and `]` included: staging a trusted path literally named `[ab].txt` must never
# sweep in an unrelated untracked `a.txt` sitting beside it, the pair skills/do/scripts/contested.sh
# already uses to prove the same glob bug for its own `git add`.
resumed_stop_stages_a_glob_named_trusted_path_literally() {
  local write mark rc
  write="$(blocks_of "$mech" "## The integration" "**A rebase that stopped.**" 1)"
  mark="$(blocks_of "$mech" "## The integration" "**A rebase that stopped.**" 2)"
  expect "the all-mechanical stop's union block extracts for the glob fixture" test -n "$write"
  expect "the all-mechanical stop's staging block extracts for the glob fixture" test -n "$mark"
  printf '%s\n' "${write//"<skill-dir>"/"$repo/skills/do"}" >"$tmp/write-glob.sh"

  fresh resumed-stop-glob
  mkdir -p .scratch
  mark="${mark//"<skill-dir>"/"$repo/skills/do"}"
  printf '%s\n' "${mark//"<the ledger>"/"$PWD/.scratch/run.ledger.md"}" >"$tmp/mark-glob.sh"
  printf 'a\nb\nc\nd\ne\nf\n' >b.txt
  printf 'a\nb\nc\nd\ne\nf\n' >'[ab].txt'
  commit base
  g branch inc
  printf 'a\nTARGET ONE\nb\nc\nd\ne\nTARGET TWO\nf\n' >b.txt
  printf 'a\nTARGET ONE\nb\nc\nd\ne\nTARGET TWO\nf\n' >'[ab].txt'
  commit target
  g switch -q inc
  printf 'a\nINCOMING ONE\nb\nc\nd\ne\nINCOMING TWO\nf\n' >b.txt
  printf 'a\nINCOMING ONE\nb\nc\nd\ne\nINCOMING TWO\nf\n' >'[ab].txt'
  commit incoming
  g -c rerere.enabled=false -c rerere.autoupdate=false rebase refs/heads/main >/dev/null 2>&1
  # b.txt keeps the markers git left, so only the union loop may stage it.
  union_of b.txt >"$tmp/b.union"
  printf 'a\nONE, merged by hand\nb\nc\nd\ne\nTWO, merged by hand\nf\n' >'[ab].txt'
  # An unrelated untracked file whose literal name the trusted path's glob metacharacters would
  # also match, sitting beside it when the resolution blocks run.
  printf 'unrelated untracked content\n' >a.txt

  rc=0
  # shellcheck disable=SC2034  # lib.sh's check reads $out
  out="$(bash "$repo/skills/do/scripts/conflict-class.sh" 2>&1)" || rc=$?
  check "the glob-named path is classed trusted so it reaches the block" \
    0 "$rc" "trusted [ab].txt whole-file hand-resolved" "verdict=mechanical mechanical=2 contested=0 trusted=1"

  bash "$tmp/write-glob.sh" >/dev/null 2>&1
  bash "$tmp/mark-glob.sh" >/dev/null 2>&1

  expect "staging a trusted path named with glob metacharacters never sweeps in an unrelated untracked file" \
    test -z "$(g ls-files -- ':(literal)a.txt')"
  expect "the trusted path itself still lands in the index despite its glob-shaped name" \
    test -n "$(g ls-files -- ':(literal)[ab].txt')"
  g show ":0:b.txt" >"$tmp/b.staged" 2>/dev/null
  expect "a conflicted file the trusted path's name also matches is staged as its union, never with its markers" \
    cmp -s "$tmp/b.staged" "$tmp/b.union"
  cd "$repo" || exit 1
}
resumed_stop_stages_a_glob_named_trusted_path_literally

# A hunk classed mechanical only says both sides added lines, never that their additions cannot
# themselves collide: each side here appends its own new top-level function right after the same
# shared closing brace, and each new function ends with a closing brace of its own, identical text
# to the other's. The union block must keep both, one per function, never let the shared trailing
# line swallow one side's.
union_keeps_both_sides_closing_braces_when_each_appends_a_function() {
  local write rc
  write="$(blocks_of "$mech" "## The integration" "**A rebase that stopped.**" 1)"
  expect "the all-mechanical stop's union block extracts for the two-functions fixture" test -n "$write"
  printf '%s\n' "${write//"<skill-dir>"/"$repo/skills/do"}" >"$tmp/write-two-functions.sh"

  fresh union-two-functions
  cat >app.js <<'JS'
function create() {
  return 1;
}
JS
  commit base
  g branch inc
  cat >app.js <<'JS'
function create() {
  return 1;
}

export function titles() {
  return notes.map((n) => n.title);
}
JS
  commit target
  g switch -q inc
  cat >app.js <<'JS'
function create() {
  return 1;
}

export function count() {
  return notes.length;
}
JS
  commit incoming
  g -c rerere.enabled=false -c rerere.autoupdate=false rebase refs/heads/main >/dev/null 2>&1

  rc=0
  # shellcheck disable=SC2034  # lib.sh's check reads $out
  out="$(bash "$repo/skills/do/scripts/conflict-class.sh" 2>&1)" || rc=$?
  check "the two-functions fixture is classed mechanical, so it reaches the union block" \
    0 "$rc" "verdict=mechanical mechanical=1 contested=0 trusted=0"

  bash "$tmp/write-two-functions.sh" >/dev/null 2>&1
  cat >"$tmp/app.expected" <<'JS'
function create() {
  return 1;
}

export function titles() {
  return notes.map((n) => n.title);
}

export function count() {
  return notes.length;
}
JS
  expect "the union keeps both sides' new functions each closed with its own closing brace" \
    cmp -s app.js "$tmp/app.expected"
  cd "$repo" || exit 1
}
union_keeps_both_sides_closing_braces_when_each_appends_a_function

# A run that opened the rebase itself can meet a stop with nothing conflicted for git's own reason:
# an untracked gate artifact (out.txt, added by one of the run's own commits and removed by a later
# one) sits in the worktree when the replay tries to add it back. conflict-class.sh answers with
# "no conflicted state, nothing classed" and exit 0, since there is no hunk to class, but the
# paragraph must still route this run-opened case to a defined outcome: blocked, git's own refusal
# named, the rebase left open, `git rebase --abort` as the undo, never an unmet stop with no route.
a_rebase_the_run_opened_itself_meets_a_stop_nothing_can_class() {
  local rc paragraph
  fresh case-g
  printf 'base\n' >notes.txt
  commit base
  g branch feat
  printf 'base\nmain moves\n' >notes.txt
  commit "main moves"
  g switch -q feat
  printf 'gate output v1\n' >out.txt
  g add out.txt
  commit "adds out.txt"
  g rm -q out.txt
  commit "removes out.txt"
  printf 'gate output v2, untracked\n' >out.txt

  rc=0
  out="$(g -c rerere.enabled=false -c rerere.autoupdate=false rebase refs/heads/main 2>&1)" || rc=$?
  check "the run's own rebase stops on git's untracked-file refusal, never a merge conflict" \
    1 "$rc" "untracked working tree files would be overwritten"

  rc=0
  out="$(bash "$repo/skills/do/scripts/conflict-class.sh" 2>&1)" || rc=$?
  check "conflict-class.sh finds nothing to class at that stop" \
    0 "$rc" "no conflicted state, nothing classed"

  paragraph="$(awk '
    /^Where every hunk/ { exit }
    /^A stop the script answers with/ { on = 1 }
    on { print }
  ' "$mech")"
  expect "mechanics.md carries the paragraph on a nothing-classed stop" test -n "$paragraph"
  out="$paragraph"
  check_absent "the paragraph never leaves a run that opened the rebase itself with no route" \
    0 0 "never meets that stop"
  check "the paragraph routes a run-opened stop nothing can class to blocked, naming git's own refusal, the rebase left open and its abort undo" \
    0 0 "blocked" "git rebase --abort" "rebase left open"
  cd "$repo" || exit 1
}
a_rebase_the_run_opened_itself_meets_a_stop_nothing_can_class

# Every hunk of the stop is mechanical, and the union the first block writes defines DENY twice in
# one scope of a `.env`: the developer's branch set it to a real deny list and the replayed commit
# emptied it. A reader of the landed file takes the last definition it meets, so the two blocks run
# as mechanics.md prints them must land the Target's definition and set the Incoming's aside in the
# ledger, and the state must route that shape to no question and no blocked stop.
an_all_mechanical_stop_whose_union_defines_a_key_twice_lands_the_targets_definition() {
  local write mark state ledger rc
  write="$(blocks_of "$mech" "## The integration" "**A rebase that stopped.**" 1)"
  mark="$(blocks_of "$mech" "## The integration" "**A rebase that stopped.**" 2)"
  expect "the all-mechanical stop's union block extracts for the duplicate-key fixture" test -n "$write"
  expect "the all-mechanical stop's staging block extracts for the duplicate-key fixture" test -n "$mark"

  fresh union-duplicate-key
  printf 'APP=one\n' >.env
  commit base
  g branch inc
  printf 'APP=one\nTARGET_ONLY=t\nDENY=admin,root\n' >.env
  commit target
  g switch -q inc
  printf 'APP=one\nINCOMING_ONLY=i\nDENY=\n' >.env
  commit incoming
  g -c rerere.enabled=false -c rerere.autoupdate=false rebase refs/heads/main >/dev/null 2>&1

  # The stop's ledger sits in its own repository's scratch, the way a run's sits in the main checkout's.
  mkdir -p .scratch
  ledger="$PWD/.scratch/run.ledger.md"
  write="${write//"<skill-dir>"/"$repo/skills/do"}"
  mark="${mark//"<skill-dir>"/"$repo/skills/do"}"
  mark="${mark//"<the ledger>"/"$ledger"}"
  printf '%s\n' "$write" >"$tmp/write-duplicate-key.sh"
  printf '%s\n' "$mark" >"$tmp/mark-duplicate-key.sh"

  rc=0
  # shellcheck disable=SC2034  # lib.sh's check reads $out
  out="$(bash "$repo/skills/do/scripts/conflict-class.sh" 2>&1)" || rc=$?
  check "the duplicate-key fixture is classed all-mechanical, so it reaches the two blocks" \
    0 "$rc" "verdict=mechanical mechanical=1 contested=0 trusted=0"

  bash "$tmp/write-duplicate-key.sh" >/dev/null 2>&1
  expect "the union block writes a .env that defines DENY twice, the Target's above the Incoming's" \
    test "$(cat .env)" = "$(printf 'APP=one\nTARGET_ONLY=t\nDENY=admin,root\nINCOMING_ONLY=i\nDENY=')"

  bash "$tmp/mark-duplicate-key.sh" >/dev/null 2>&1
  g show ":0:.env" >"$tmp/duplicate-key.staged" 2>/dev/null
  expect "the staged .env keeps the Target's DENY definition, drops the Incoming's, and keeps every other line of both sides" \
    test "$(cat "$tmp/duplicate-key.staged")" = "$(printf 'APP=one\nTARGET_ONLY=t\nDENY=admin,root\nINCOMING_ONLY=i')"
  expect "after the two blocks nothing at the duplicate-key stop is left unmerged" \
    test -z "$(g ls-files -u)"
  expect "the definition the run dropped leaves one entry in the ledger" \
    test "$(grep -c '^## ' "$ledger" 2>/dev/null)" = 1
  expect "the ledger entry sets aside the Incoming's definition" \
    test "$(ledger_part "$ledger" .env incoming 2>/dev/null)" = 'DENY='

  state="$(awk '
    /^\*\*A stop carrying a contested hunk\.\*\*/ { exit }
    /^\*\*A union that defines the same key twice\.\*\*/ { on = 1 }
    on { print }
  ' "$mech")"
  expect "mechanics.md carries the state on a union that defines one key twice" test -n "$state"
  out="$state"
  check_absent "the state routes a union's duplicate key to no blocked stop and no question for the developer" \
    0 0 "stops as blocked" "git rebase --abort" "brought to the developer"
  cd "$repo" || exit 1
}
an_all_mechanical_stop_whose_union_defines_a_key_twice_lands_the_targets_definition

# A stop the developer already worked on can carry their own resolution of a file whose name the
# read-back's registry knows, and that resolution may define one key twice on purpose. The first
# block stages every `trusted` path before it writes any union, so git stops listing that file
# unmerged and the read-back the second block runs never reaches it: the file lands byte for byte as
# the developer wrote it, both definitions kept, and nothing of theirs is set aside in the ledger.
a_trusted_hand_resolution_defining_one_key_twice_is_never_read_back() {
  local write mark ledger rc
  write="$(blocks_of "$mech" "## The integration" "**A rebase that stopped.**" 1)"
  mark="$(blocks_of "$mech" "## The integration" "**A rebase that stopped.**" 2)"
  expect "the all-mechanical stop's union block extracts for the trusted duplicate-key fixture" test -n "$write"
  expect "the all-mechanical stop's staging block extracts for the trusted duplicate-key fixture" test -n "$mark"

  fresh trusted-duplicate-key
  printf 'APP=one\n' >.env
  printf 'APP=one\n' >.env.local
  commit base
  g branch inc
  printf 'APP=one\nDENY=admin,root\n' >.env
  printf 'APP=one\nTARGET_ONLY=t\nDENY=admin,root\n' >.env.local
  commit target
  g switch -q inc
  printf 'APP=one\nDENY=\n' >.env
  printf 'APP=one\nINCOMING_ONLY=i\nDENY=\n' >.env.local
  commit incoming
  g -c rerere.enabled=false -c rerere.autoupdate=false rebase refs/heads/main >/dev/null 2>&1

  # .env.local keeps the markers git left, so the union block writes it and its union defines DENY
  # twice. .env is the developer's own answer, written before the run took over and never staged:
  # they kept both sides' definitions of DENY and put the replayed commit's last, which is exactly
  # the shape the read-back rewrites when it is the run's own union it is reading.
  printf 'APP=one\nDENY=admin,root\nFEATURE=new\nDENY=\n' >.env
  cp .env "$tmp/trusted-hand.before"

  mkdir -p .scratch
  ledger="$PWD/.scratch/run.ledger.md"
  write="${write//"<skill-dir>"/"$repo/skills/do"}"
  mark="${mark//"<skill-dir>"/"$repo/skills/do"}"
  mark="${mark//"<the ledger>"/"$ledger"}"
  printf '%s\n' "$write" >"$tmp/write-trusted-duplicate-key.sh"
  printf '%s\n' "$mark" >"$tmp/mark-trusted-duplicate-key.sh"

  rc=0
  # shellcheck disable=SC2034  # lib.sh's check reads $out
  out="$(bash "$repo/skills/do/scripts/conflict-class.sh" 2>&1)" || rc=$?
  check "the trusted duplicate-key fixture is classed all-mechanical with the hand-resolved .env trusted" \
    0 "$rc" "trusted .env whole-file hand-resolved" "verdict=mechanical mechanical=1 contested=0 trusted=1"

  bash "$tmp/write-trusted-duplicate-key.sh" >/dev/null 2>&1
  bash "$tmp/mark-trusted-duplicate-key.sh" >/dev/null 2>&1

  g show ":0:.env" >"$tmp/trusted-hand.staged" 2>/dev/null
  expect "a trusted file whose name the read-back knows is staged byte for byte as the developer wrote it" \
    cmp -s "$tmp/trusted-hand.staged" "$tmp/trusted-hand.before"
  # shellcheck disable=SC2034  # lib.sh's check_lines reads $out
  out="$(cat "$tmp/trusted-hand.staged")"
  check_lines "and both definitions the developer kept of one key stand in the staged file" \
    0 0 "DENY=admin,root" "DENY="
  expect "the read-back sets no definition of the developer's own resolution aside in the ledger" \
    test -z "$(ledger_part "$ledger" .env incoming 2>/dev/null)"
  expect "while the union the run wrote itself does leave its dropped definition there" \
    test "$(ledger_part "$ledger" .env.local incoming 2>/dev/null)" = 'DENY='
  expect "after the two blocks nothing at the trusted duplicate-key stop is left unmerged" \
    test -z "$(g ls-files -u)"
  cd "$repo" || exit 1
}
a_trusted_hand_resolution_defining_one_key_twice_is_never_read_back

# The resolution of a stop can leave the replayed commit with nothing left to apply: the developer's
# branch already carries that change in its own wording, and taking the Target side stages a tree
# identical to HEAD. Git refuses to commit that, so the continue the run runs at every stop must name
# the commit, skip it, and carry the rebase to its end with the run's remaining work replayed on top.
a_replayed_commit_the_resolution_left_empty_is_named_skipped_and_the_rebase_finishes() {
  local cont ledger short rc
  cont="$(blocks_of "$mech" "## The integration" "**A replayed commit that is empty after the resolution.**" 1)"
  expect "the empty-after-resolution state carries the continue block the run runs at every stop" \
    test -n "$cont"
  printf '%s\n' "$cont" >"$tmp/continue-empty.sh"

  fresh empty-after-resolution
  # The block's own git commits what is left to replay, which needs an identity in the fixture.
  g config user.email t@example.com
  g config user.name t
  printf 'const FLAG = false;\nconst OTHER = 1;\n' >flag.js
  commit base
  g switch -q -c do/run
  printf 'const FLAG = true; // enabled\nconst OTHER = 1;\n' >flag.js
  commit "turns the flag on"
  printf 'note\n' >notes.txt
  commit "adds a note"
  g switch -q main
  printf 'const FLAG = true;\nconst OTHER = 1;\n' >flag.js
  commit "the developer turns the flag on too"
  g switch -q do/run
  g -c rerere.enabled=false -c rerere.autoupdate=false rebase refs/heads/main >/dev/null 2>&1
  short="$(g rev-parse --short REBASE_HEAD)"

  rc=0
  # shellcheck disable=SC2034  # lib.sh's check reads $out
  out="$(bash "$repo/skills/do/scripts/conflict-class.sh" 2>&1)" || rc=$?
  check "the flag fixture stops on a contested hunk, so the stop is resolved by the script" \
    1 "$rc" "verdict=contested mechanical=0 contested=1 trusted=0"

  mkdir -p .scratch
  ledger="$PWD/.scratch/run.ledger.md"
  rc=0
  out="$(bash "$repo/skills/do/scripts/contested.sh" "$ledger" 2>&1)" || rc=$?
  check "the Target side resolves the stop, leaving the replayed commit nothing left to apply" \
    0 "$rc" "wrote flag.js" "resolved mechanical=0 contested=1"

  rc=0
  # GIT_EDITOR so a continue that does reach git never waits on an editor and hangs the suite.
  out="$(GIT_EDITOR=true bash "$tmp/continue-empty.sh" 2>&1)" || rc=$?
  check_lines "the continue names the replayed commit the resolution left empty and skips it" \
    0 "$rc" "skipped $short turns the flag on"

  # shellcheck disable=SC2034  # lib.sh's check_absent reads $out
  out="$(g status 2>&1)"
  check_absent "the rebase is no longer stopped once that commit is skipped" 0 0 \
    "rebase in progress" "You are currently rebasing"
  expect "and git is left no rebase state at all" \
    test ! -d "$(g rev-parse --git-path rebase-merge)" -a ! -d "$(g rev-parse --git-path rebase-apply)"
  expect "the rebase carried on to its end, the run's later commit replayed and the empty one gone" \
    test "$(g log --format=%s refs/heads/main..HEAD)" = "adds a note"
  expect "the developer's own version of the file the skipped commit touched stands on the branch" \
    test "$(cat flag.js)" = "$(g cat-file blob main:flag.js)"
  cd "$repo" || exit 1
}
a_replayed_commit_the_resolution_left_empty_is_named_skipped_and_the_rebase_finishes

if [ "$fails" = 0 ]; then echo "PASS"; else
  echo "$fails failing"
  exit 1
fi
