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
blocks_of() { # $1 file, $2 the heading whose section holds the resolution: its fenced blocks, unindented
  # Optional: $3 the opening of the line from which blocks are read, $4 n: only the nth block from it
  awk -v h="$2" -v a="${3:-}" -v n="${4:-0}" '
    $0 == h { on = 1; from = (a == ""); next }
    on && !fence && /^#+ / { exit }
    on && !fence && !from && index($0, a) == 1 { from = 1 }
    on && /^ *```/ { if (fence) fence = 0; else { fence = 1; if (from) k++; match($0, /^ */); ind = RLENGTH }; next }
    on && fence && from && (n == 0 || k == n) { print substr($0, ind + 1) }
  ' "$1"
}
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
  block="${block//"<skill-dir>"/"$repo/skills/do"}"
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
  printf '%s\n' "$mark" >"$tmp/mark.sh"

  fresh resumed-stop
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
  printf '%s\n' "$mark" >"$tmp/mark-glob.sh"

  fresh resumed-stop-glob
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
if [ "$fails" = 0 ]; then echo "PASS"; else
  echo "$fails failing"
  exit 1
fi
