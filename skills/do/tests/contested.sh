#!/usr/bin/env bash
# contested.sh: the contract of scripts/contested.sh, the script that turns every contested hunk of a
# stopped rebase into one question and applies the answers, exercised in throwaway git repositories,
# one per scenario. Run: bash skills/do/tests/contested.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
door="$here/../scripts/contested.sh"
classer="$here/../scripts/conflict-class.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

# The session is interactive unless a scenario says otherwise: the harness may have set the variable.
run() {
  rc=0
  out="$(CLAUDE_CODE_ENTRYPOINT=cli bash "$door" "$@" 2>&1)" || rc=$?
}
# What a question must leave untouched: the unmerged index and the bytes of every working file.
state() {
  g ls-files -s -u
  git ls-files -z -- . | xargs -0 git hash-object --
}

# The script reads the classifier's report and matches its quoted paths back to the raw ones, so its
# copy of the quoting has to stay the classifier's, byte for byte.
body() { sed -n '/^quote_path() {/,/^}/p' "$1" 2>/dev/null; }
if [ -n "$(body "$classer")" ] && [ "$(body "$classer")" = "$(body "$door")" ]; then
  echo "ok    quote_path is the verbatim copy of conflict-class.sh's"
else
  echo "FAIL  quote_path drifted from conflict-class.sh's"
  fails=$((fails + 1))
fi

# A rebase stopped on two files whose one line both sides rewrote: the developer's branch is the
# Target, the commit being replayed the Incoming side.
fresh two-rewrites
printf 'x\ny\nz\n' >rewrite.txt
printf 'a\nb\nc\n' >second.txt
commit base
g switch -q -c do/run
printf 'x\nINCOMING\nz\n' >rewrite.txt
printf 'a\nINCOMING TOO\nc\n' >second.txt
commit incoming
g switch -q main
printf 'x\nTARGET\nz\n' >rewrite.txt
printf 'a\nTARGET TOO\nc\n' >second.txt
commit target
g switch -q do/run
g rebase main >/dev/null 2>&1
before="$(state)"

run
check "the first contested hunk is question 1 of the stop's total, with its file, location and shape" 1 "$rc" \
  "Conflict 1 of 2 · rewrite.txt · L2-L6 · rewrite-vs-rewrite"
check "each side is quoted under its own heading, the Target side being the developer's branch" 1 "$rc" \
  "### Target" "    TARGET" "### Incoming" "    INCOMING"
check "the recommendation carries the shape as its reason" 1 "$rc" \
  "Recommendation: target, because both sides rewrote the same lines of the base"
check "the question lists the four answers and already carries the undo" 1 "$rc" \
  "Answers: target · incoming · both · stop" \
  "Undo: git rebase --abort"
check "the question carries the id an answer is given against" 1 "$rc" "id "
check_absent "one question at a time: the second hunk is not asked yet" 1 "$rc" \
  "Conflict 2 of 2" "TARGET TOO"
expect "asking writes nothing: the index and the working files are as git left them" \
  test "$(state)" = "$before"

# A stop carrying three contested hunks: one in a file that also carries a mechanical hunk, one whose
# last line both sides kept without a final newline, and one whose conflict is its own last line,
# without a final newline either.
fresh three-answers
seq 1 20 >mixed.txt
printf 'a\nb\nc' >plain.txt
printf 'p\nq' >third.txt
commit base
g switch -q -c do/run
{
  seq 1 2
  echo I3
  seq 4 20
  echo INCOMING END
} >mixed.txt
printf 'a\nIB\nc' >plain.txt
printf 'p\nIQ' >third.txt
commit incoming
g switch -q main
{
  seq 1 2
  echo T3
  seq 4 20
  echo TARGET END
} >mixed.txt
printf 'a\nTB\nc' >plain.txt
printf 'p\nTQ' >third.txt
commit target
g switch -q do/run
g rebase main >/dev/null 2>&1
union_of mixed.txt >"$tmp/mixed.both"
git cat-file blob :2:plain.txt >"$tmp/plain.target"
git cat-file blob :3:third.txt >"$tmp/third.incoming"
before="$(state)"

run
first="$(sed -n 's/^id //p' <<<"$out")"
run "$first:both"
second="$(sed -n 's/^id //p' <<<"$out")"
check "an answer short of the last brings the next contested hunk" 1 "$rc" \
  "Conflict 2 of 3 · plain.txt"
run "$first:both" "$second:target"
third="$(sed -n 's/^id //p' <<<"$out")"
check "the answers so far are carried and the next question follows" 1 "$rc" \
  "Conflict 3 of 3 · third.txt"
expect "no file is written before the stop's last answer" test "$(state)" = "$before"

run "$first:both" "$second:target" "$third:incoming"
check "the last answer writes every file and states the answers by word" 0 "$rc" \
  "wrote mixed.txt" "wrote plain.txt" "wrote third.txt" \
  "resolved mechanical=1 target=1 incoming=1 both=1"
expect "both keeps both sides in base order, the file's mechanical hunk by the same rule" \
  cmp -s mixed.txt "$tmp/mixed.both"
expect "target takes the Target side, the final newline as the file had it" \
  cmp -s plain.txt "$tmp/plain.target"
expect "incoming takes the Incoming side, even where the conflict is the file's last line" \
  cmp -s third.txt "$tmp/third.incoming"
expect "every written file is staged, so nothing is left unmerged" \
  test -z "$(git ls-files -u)"
expect "the rebase continues from there" \
  g -c core.editor=true -c rerere.enabled=false rebase --continue

# A stop the developer declines to answer: a file the developer's branch deleted and the replayed
# commit edited, and a line both sides rewrote. Every way out short of an answer leaves the rebase
# open, names the files and gives the undo, and writes nothing.
fresh blocked
printf 'kept\n' >gone.txt
printf 'x\ny\nz\n' >rewrite.txt
commit base
g switch -q -c do/run
printf 'kept\nedited by incoming\n' >gone.txt
printf 'x\nINCOMING\nz\n' >rewrite.txt
commit incoming
g switch -q main
rm gone.txt
printf 'x\nTARGET\nz\n' >rewrite.txt
commit target
g switch -q do/run
g rebase main >/dev/null 2>&1
before="$(state)"
run
first="$(sed -n 's/^id //p' <<<"$out")"
run "$first:target"
second="$(sed -n 's/^id //p' <<<"$out")"

blocked() { # $1 label, $2 the reason line
  check "$1" 3 "$rc" "$2" "conflicted gone.txt" "conflicted rewrite.txt" "undo git rebase --abort"
  expect "$1: nothing written" test "$(state)" = "$before"
}
run "$first:stop"
blocked "stop leaves the rebase open with the files named and the undo given" "blocked stop"
run "$first:maybe"
blocked "an answer that is none of the four stops the same way" \
  "blocked maybe is none of the answers offered for $first"
run "$first:both"
blocked "both where the shape offers no union stops the same way" \
  "blocked both is none of the answers offered for $first"
run "000000000000:target"
blocked "an id that names no open hunk is never applied to another" \
  "blocked 000000000000 is no longer open"
run "$first:target" "$second:stop"
blocked "a stop after an answer writes nothing of the answer before it" "blocked stop"
run "$first:target" "$second:target" "$second:target"
blocked "more answers than the stop has hunks is never guessed at" \
  "blocked more answers than contested hunks"

# A session nobody is there to answer: `claude -p` reads sdk-cli, and the SDK's other entrypoints
# share the prefix. The script refuses before a question can be printed, so no answer is ever guessed.
fresh headless
printf 'x\ny\nz\n' >rewrite.txt
printf 'a\nb\nc\n' >second.txt
commit base
g switch -q -c do/run
printf 'x\nINCOMING\nz\n' >rewrite.txt
printf 'a\nINCOMING TOO\nc\n' >second.txt
commit incoming
g switch -q main
printf 'x\nTARGET\nz\n' >rewrite.txt
printf 'a\nTARGET TOO\nc\n' >second.txt
commit target
g switch -q do/run
g rebase main >/dev/null 2>&1
before="$(state)"
run
first="$(sed -n 's/^id //p' <<<"$out")"
headless() {
  rc=0
  out="$(CLAUDE_CODE_ENTRYPOINT="$1" bash "$door" "${@:2}" 2>&1)" || rc=$?
}

headless sdk-cli
check "a headless session is told no human is there, with the files it would have asked about" 4 "$rc" \
  "no human CLAUDE_CODE_ENTRYPOINT=sdk-cli" "conflicted rewrite.txt" "conflicted second.txt"
check_absent "a headless session is never asked a question" 4 "$rc" "Conflict 1 of"
expect "a headless session writes nothing" test "$(state)" = "$before"
headless sdk-ts "$first:target"
check "answers carried into a headless session are refused all the same" 4 "$rc" \
  "no human CLAUDE_CODE_ENTRYPOINT=sdk-ts"
expect "a headless session writes nothing of an answer it was handed" test "$(state)" = "$before"

# A stop whose every hunk is a whole file: a rewrite next to an addition that git's own presentation
# joins into one hunk, a file each side deleted while the other edited it, and a binary file. The
# answer takes a side's version whole, or its deletion, and the union only where both sides are text.
fresh whole-files
seq 1 6 >collapsed.txt
printf 'kept\n' >gone.txt
printf 'kept\n' >kept.txt
printf 'pixels\000\001\002\n' >picture.bin
commit base
g switch -q -c do/run
printf '1\n2i\n3\n4\ny\n5\n6\n' >collapsed.txt
printf 'kept\nedited by incoming\n' >gone.txt
rm kept.txt
printf 'pixels\000\001\004incoming\n' >picture.bin
commit incoming
g switch -q main
printf '1\n2t\n3\n4\nx\n5\n6\n' >collapsed.txt
rm gone.txt
printf 'kept\nedited by target\n' >kept.txt
printf 'pixels\000\001\003target\n' >picture.bin
commit target
g switch -q do/run
g rebase main >/dev/null 2>&1
union_of collapsed.txt >"$tmp/collapsed.both"
git cat-file blob :2:kept.txt >"$tmp/kept.target"
git cat-file blob :3:picture.bin >"$tmp/picture.incoming"

run
first="$(sed -n 's/^id //p' <<<"$out")"
check "a whole-file hunk that git's presentation joined is asked whole, with stop recommended" 1 "$rc" \
  "Conflict 1 of 4 · collapsed.txt · whole-file · unmergeable" \
  "    2t" "    x" "    2i" "    y" "Recommendation: stop, because" \
  "Answers: target · incoming · both · stop"
run "$first:both"
second="$(sed -n 's/^id //p' <<<"$out")"
check "a side that deleted the file is quoted as the deletion" 1 "$rc" \
  "Conflict 2 of 4 · gone.txt · whole-file · delete-vs-edit" \
  "    (deleted)" "    edited by incoming" "Answers: target · incoming · stop"
run "$first:both" "$second:target"
third="$(sed -n 's/^id //p' <<<"$out")"
run "$first:both" "$second:target" "$third:target"
fourth="$(sed -n 's/^id //p' <<<"$out")"
check "a binary side is named by its size and blob, never pasted" 1 "$rc" \
  "Conflict 4 of 4 · picture.bin · whole-file · binary" "    (binary, "
check_absent "no byte of a binary side reaches the question" 1 "$rc" "pixels"

run "$first:both" "$second:target" "$third:target" "$fourth:incoming"
check "whole-file answers write or remove each file and state the answers by word" 0 "$rc" \
  "wrote collapsed.txt" "removed gone.txt" "wrote kept.txt" "wrote picture.bin" \
  "resolved mechanical=0 target=2 incoming=1 both=1"
expect "both on a joined hunk is the union of the whole file" cmp -s collapsed.txt "$tmp/collapsed.both"
expect "target where the Target side deleted the file removes it" \
  test ! -e gone.txt -a -z "$(git ls-files -- gone.txt)"
expect "target where the Incoming side deleted the file keeps the Target's version" \
  cmp -s kept.txt "$tmp/kept.target"
expect "incoming on a binary file takes the Incoming side's bytes whole" \
  cmp -s picture.bin "$tmp/picture.incoming"
expect "no whole-file hunk is left unmerged" test -z "$(git ls-files -u)"
expect "the rebase continues from there too" \
  g -c core.editor=true -c rerere.enabled=false rebase --continue

# A contested stop that also carries a file whose every hunk is mechanical. No path may be typed into
# a command line, so the script resolves that file itself on its first call, and the question that
# follows is the one it would have asked without it.
fresh mixed-stop
printf 'a\nb\n' >mech.txt
printf 'x\ny\nz\n' >rewrite.txt
commit base
g switch -q -c do/run
printf 'a\nINCOMING\nb\n' >mech.txt
printf 'x\nINCOMING\nz\n' >rewrite.txt
commit incoming
g switch -q main
printf 'a\nTARGET\nb\n' >mech.txt
printf 'x\nTARGET\nz\n' >rewrite.txt
commit target
g switch -q do/run
g rebase main >/dev/null 2>&1
union_of mech.txt >"$tmp/mech.union"
untouched="$(
  g ls-files -s -u -- rewrite.txt
  git hash-object -- rewrite.txt
)"

run
first="$(sed -n 's/^id //p' <<<"$out")"
check "the first call writes the all-mechanical file before it asks the contested hunk" 1 "$rc" \
  "wrote mech.txt" "Conflict 1 of 1 · rewrite.txt · L2-L6 · rewrite-vs-rewrite"
expect "the all-mechanical file carries both sides in base order" cmp -s mech.txt "$tmp/mech.union"
expect "the all-mechanical file is staged" test -z "$(git ls-files -u -- mech.txt)"
expect "the contested file is left as git left it" \
  test "$(
    g ls-files -s -u -- rewrite.txt
    git hash-object -- rewrite.txt
  )" = "$untouched"
after_first="$(state)"
run
check "a repeated first call asks the same question" 1 "$rc" "id $first"
check_absent "a repeated first call writes nothing again" 1 "$rc" "wrote mech.txt"
expect "a repeated first call leaves the tree as the first left it" test "$(state)" = "$after_first"
run "$first:target"
check "the answer still names its hunk once the mechanical file is written" 0 "$rc" \
  "wrote rewrite.txt" "resolved mechanical=0 target=1 incoming=0 both=0"
expect "the rebase continues from a stop that mixed the two classes" \
  g -c core.editor=true -c rerere.enabled=false rebase --continue

# A mixed stop whose two additions end on the same line. Git's union keeps that shared line once,
# which the presentation the questions come from does not, so each written file is held to what
# `git merge-file --union` makes of the same hunks.
fresh shared-line
printf 'a\nb\n' >mech.txt
printf 'x\ny\nz\n' >both.txt
seq 1 10 >mixed.txt
commit base
g switch -q -c do/run
printf 'a\nI1\nCOMMON\nb\n' >mech.txt
printf 'x\nINCOMING\nCOMMON\nz\n' >both.txt
{
  seq 1 2
  printf 'I\nSHARED\n'
  seq 3 7
  echo I8
  seq 9 10
} >mixed.txt
commit incoming
g switch -q main
printf 'a\nT1\nCOMMON\nb\n' >mech.txt
printf 'x\nTARGET\nCOMMON\nz\n' >both.txt
{
  seq 1 2
  printf 'T\nSHARED\n'
  seq 3 7
  echo T8
  seq 9 10
} >mixed.txt
commit target
g switch -q do/run
g rebase main >/dev/null 2>&1
for f in mech both; do union_of "$f.txt" >"$tmp/$f.union"; done
{
  seq 1 2
  printf 'T\nI\nSHARED\n'
  seq 3 7
  echo T8
  seq 9 10
} >"$tmp/mixed.expected"
run
first="$(sed -n 's/^id //p' <<<"$out")"
check "the first call writes the all-mechanical file whose additions share a line" 1 "$rc" \
  "wrote mech.txt" "Conflict 1 of 2 · both.txt"
expect "that file is byte-equal to git's union of its three stages" cmp -s mech.txt "$tmp/mech.union"
run "$first:both"
second="$(sed -n 's/^id //p' <<<"$out")"
run "$first:both" "$second:target"
check "the answers write the files that carry a contested hunk" 0 "$rc" "wrote both.txt" "wrote mixed.txt"
expect "both on a hunk whose sides share a line is byte-equal to git's union of the stages" \
  cmp -s both.txt "$tmp/both.union"
expect "a mechanical hunk beside a contested one keeps the shared line once" \
  cmp -s mixed.txt "$tmp/mixed.expected"

# A conflicted path is a name a side chose, and git reads a path argument as a glob unless told
# otherwise: `[ab].txt` also names an untracked `a.txt`, which the run's continue would then commit.
fresh glob-name
printf 'one\n' >'[ab].txt'
printf 'x\ny\n' >c.txt
commit base
g switch -q -c do/run
printf 'one\nincoming line\n' >'[ab].txt'
printf 'x\nINCOMING\n' >c.txt
commit incoming
g switch -q main
printf 'one\ntarget line\n' >'[ab].txt'
printf 'x\nTARGET\n' >c.txt
commit target
g switch -q do/run
g rebase main >/dev/null 2>&1
printf 'AWS_SECRET=hunter2\n' >a.txt
run
check "the first call writes the glob-named mechanical file" 1 "$rc" \
  "wrote [ab].txt" "Conflict 1 of 1 · c.txt"
expect "the glob-named file is staged" test -z "$(git ls-files -u -- ':(literal)[ab].txt')"
expect "an untracked file the name matches as a glob is left unstaged" \
  test -z "$(git ls-files -- ':(literal)a.txt')"

# A side's version is taken through git by name, the deletion by `git rm` and the kept version by
# `git checkout`, and each reads a glob-named path as a glob too: `app/[ab].tsx` also names the
# tracked `app/a.tsx` and `app/b.tsx`, and `lib/[cd].ts` a `lib/c.ts` with an edit of its own.
fresh glob-whole
mkdir app lib
printf 'page\n' >'app/[ab].tsx'
printf 'route a\n' >app/a.tsx
printf 'route b\n' >app/b.tsx
printf 'module\n' >'lib/[cd].ts'
printf 'lib c\n' >lib/c.ts
commit base
g switch -q -c do/run
printf 'page\nedited by incoming\n' >'app/[ab].tsx'
g rm -q -- ':(literal)lib/[cd].ts'
commit incoming
g switch -q main
g rm -q -- ':(literal)app/[ab].tsx'
printf 'module\nedited by target\n' >'lib/[cd].ts'
commit target
g switch -q do/run
g rebase main >/dev/null 2>&1
printf 'lib c\nedited during the stop\n' >lib/c.ts
cp lib/c.ts "$tmp/c.edited"
run
first="$(sed -n 's/^id //p' <<<"$out")"
check "a glob-named file deleted by the Target side is asked whole" 1 "$rc" \
  "Conflict 1 of 2 · app/[ab].tsx · whole-file · delete-vs-edit"
run "$first:target"
second="$(sed -n 's/^id //p' <<<"$out")"
run "$first:target" "$second:target"
check "target removes the one glob-named file and keeps the other's Target version" 0 "$rc" \
  "removed app/[ab].tsx" "wrote lib/[cd].ts"
expect "the removal takes the glob-named file alone" \
  test -z "$(git ls-files -- ':(literal)app/[ab].tsx')" -a ! -e 'app/[ab].tsx'
expect "the tracked files its name matches as a glob stay tracked and on disk" \
  test "$(git ls-files -- app/a.tsx app/b.tsx | wc -l)" = 2 -a -f app/a.tsx -a -f app/b.tsx
expect "taking a side's version rewrites no other file its name matches as a glob" \
  cmp -s lib/c.ts "$tmp/c.edited"

# A symlink both sides changed, left in the tree as the Target side's link to a file outside the
# repository: a write into the path lands in that file. `l2`'s outside file carries marker lines, so
# the classifier reads it as a line hunk and the answer goes through the hunk writer, not the
# whole-file one.
fresh links
printf 'precious one\n' >"$tmp/outside1.txt"
printf 'precious two\n<<<<<<< a\n>>>>>>> b\n' >"$tmp/outside2.txt"
cp "$tmp/outside1.txt" "$tmp/outside1.before"
cp "$tmp/outside2.txt" "$tmp/outside2.before"
ln -s t0 l1
ln -s t0 l2
commit base
g switch -q -c do/run
ln -sfn t1 l1
ln -sfn t1 l2
commit incoming
g switch -q main
ln -sfn "$tmp/outside1.txt" l1
ln -sfn "$tmp/outside2.txt" l2
commit target
g switch -q do/run
g rebase main >/dev/null 2>&1
target_links="$(git ls-files -s -- ':(literal)l1' ':(literal)l2' | awk '$3 == 2 { print $1, $2 }')"
outside_same() {
  cmp -s "$tmp/outside1.txt" "$tmp/outside1.before" && cmp -s "$tmp/outside2.txt" "$tmp/outside2.before"
}
run
first="$(sed -n 's/^id //p' <<<"$out")"
check "a symlink conflict never offers both" 1 "$rc" \
  "Conflict 1 of 2 · l1 · whole-file" "Answers: target · incoming · stop"
run "$first:both"
check "both on a symlink is refused like any answer not offered" 3 "$rc" \
  "blocked both is none of the answers offered for $first"
run "$first:target"
second="$(sed -n 's/^id //p' <<<"$out")"
check "a symlink read as a line hunk never offers both either" 1 "$rc" \
  "Conflict 2 of 2 · l2 · L2-L3" "Answers: target · incoming · stop"
run "$first:target" "$second:target"
check "target writes both links" 0 "$rc" "wrote l1" "wrote l2"
expect "no answer writes into a file a link points at" outside_same
expect "each link is staged as the Target side's link" \
  test "$(git ls-files -s -- ':(literal)l1' ':(literal)l2' | awk '{ print $1, $2 }')" = "$target_links"
expect "each link is still a link in the tree" test -L l1 -a -L l2

# Sides far longer than a question can carry, the run showing every question as printed: a
# whole-file side of thousands of lines, a hunk side of thousands of lines, and a hunk side that is
# one enormous line. Each question quotes the head of each side and names its size and blob, and an
# answer still takes the whole side.
fresh long-sides
seq 1 5000 | sed 's/^/big line /' >big.txt
printf 'a\nb\nc\n' >long.txt
commit base
g switch -q -c do/run
echo 'edited by incoming' >>big.txt
{
  echo a
  head -c 100000 /dev/zero | tr '\0' x
  echo
  echo c
} >long.txt
commit incoming
g switch -q main
g rm -q big.txt
{
  echo a
  seq 1 3000 | sed 's/^/target line /'
  echo c
} >long.txt
commit target
g switch -q do/run
g rebase main >/dev/null 2>&1
git cat-file blob :3:big.txt >"$tmp/big.incoming"
git cat-file blob :2:long.txt >"$tmp/long.target"
small() { test "$(printf '%s' "$out" | wc -c)" -lt 40000; }
run
first="$(sed -n 's/^id //p' <<<"$out")"
check "a whole-file side past the limit is quoted by its head, its size and its blob" 1 "$rc" \
  "Conflict 1 of 2 · big.txt · whole-file · delete-vs-edit" "    big line 1" \
  "5001 lines, $(git cat-file -s :3:big.txt) bytes, from blob $(git rev-parse --short :3:big.txt)"
check_absent "the whole-file side's tail stays out of the question" 1 "$rc" "edited by incoming"
expect "the whole-file question stays small" small
run "$first:incoming"
second="$(sed -n 's/^id //p' <<<"$out")"
check "hunk sides past the limit are quoted by their head, their size and their file's blob" 1 "$rc" \
  "Conflict 2 of 2 · long.txt" "    target line 1" \
  "3000 lines, " "from blob $(git rev-parse --short :2:long.txt)" \
  "1 line, 100001 bytes, from blob $(git rev-parse --short :3:long.txt)"
check_absent "a long hunk side's tail stays out of the question" 1 "$rc" "target line 3000"
expect "the hunk question stays small, the one enormous line cut too" small
run "$first:incoming" "$second:target"
check "the answers apply to the sides the questions cut short" 0 "$rc" "wrote big.txt" "wrote long.txt"
expect "incoming takes the whole Incoming side, not its quoted head" cmp -s big.txt "$tmp/big.incoming"
expect "target takes the whole Target side, not its quoted head" cmp -s long.txt "$tmp/long.target"

# A resumed stop: one file carrying a hunk both sides rewrote, and one the developer already resolved
# by hand and never staged, marker-free and neither side nor the union of its stages. That file is the
# developer's answer, so it is never asked about, and the stop's answers leave it as they wrote it.
fresh resumed-hand
printf 'x\ny\nz\n' >rewrite.txt
printf 'a\nb\nc\nd\ne\nf\n' >hand.txt
commit base
g switch -q -c do/run
printf 'x\nINCOMING\nz\n' >rewrite.txt
printf 'a\nINCOMING ONE\nb\nc\nd\ne\nINCOMING TWO\nf\n' >hand.txt
commit incoming
g switch -q main
printf 'x\nTARGET\nz\n' >rewrite.txt
printf 'a\nTARGET ONE\nb\nc\nd\ne\nTARGET TWO\nf\n' >hand.txt
commit target
g switch -q do/run
g rebase main >/dev/null 2>&1
printf 'a\nONE, merged by hand\nb\nc\nd\ne\nTWO, merged by hand\nf\n' >hand.txt
cp hand.txt "$tmp/hand.before"
expect "the hand resolution is not the union of its stages" test "$(union_of hand.txt)" != "$(cat hand.txt)"

run
first="$(sed -n 's/^id //p' <<<"$out")"
check "a resumed stop asks the contested hunk alone, the hand-resolved file never counted in" 1 "$rc" \
  "Conflict 1 of 1 · rewrite.txt · L2-L6 · rewrite-vs-rewrite"
check_absent "no question is put about the file resolved by hand" 1 "$rc" "· hand.txt"
expect "asking leaves the hand resolution as the developer wrote it" cmp -s hand.txt "$tmp/hand.before"

run "$first:target"
check "the answer writes the contested file" 0 "$rc" "wrote rewrite.txt"
check_lines "the answer names the hand-resolved file on a trusted line" 0 "$rc" "trusted hand.txt"
expect "the final line counts the hand-resolved file last, as trusted" \
  test "$(tail -n 1 <<<"$out")" = "resolved mechanical=0 target=1 incoming=0 both=0 trusted=1"
expect "the hand resolution comes out byte for byte as the developer wrote it" \
  cmp -s hand.txt "$tmp/hand.before"
git cat-file blob :0:hand.txt >"$tmp/hand.staged" 2>/dev/null
expect "and it is staged with those bytes" cmp -s "$tmp/hand.staged" "$tmp/hand.before"
expect "nothing at the resumed stop is left unmerged" test -z "$(git ls-files -u)"

# A merge stopped on a line both sides rewrote: the branch merged into is the Target, the branch
# being merged the Incoming side. The question, the answer and the stop are the rebase's, and the
# undo is the merge's own.
fresh merge-stop
printf 'x\ny\nz\n' >rewrite.txt
commit base
g switch -q -c do/run
printf 'x\nINCOMING\nz\n' >rewrite.txt
commit incoming
g switch -q main
printf 'x\nTARGET\nz\n' >rewrite.txt
commit target
g merge do/run >/dev/null 2>&1
git cat-file blob :2:rewrite.txt >"$tmp/merge.target"
before="$(state)"

run
first="$(sed -n 's/^id //p' <<<"$out")"
check "a stopped merge asks its contested hunk as a stopped rebase does" 1 "$rc" \
  "Conflict 1 of 1 · rewrite.txt · L2-L6 · rewrite-vs-rewrite" \
  "### Target" "### Incoming" "Answers: target · incoming · both · stop" "id "
expect "the merge's target branch is quoted as the Target side" \
  grep -qxF '    TARGET' <(sed -n '/^### Target$/,/^### Incoming$/p' <<<"$out")
expect "the merged branch is quoted as the Incoming side" \
  grep -qxF '    INCOMING' <(sed -n '/^### Incoming$/,/^Recommendation/p' <<<"$out")
expect "asking at a stopped merge writes nothing" test "$(state)" = "$before"

run "$first:stop"
check "stop at a stopped merge blocks with the merge's undo" 3 "$rc" \
  "blocked stop" "conflicted rewrite.txt" "undo git merge --abort"
check_absent "stop at a stopped merge never offers the rebase's undo" 3 "$rc" "undo git rebase --abort"
expect "stop leaves the merge open and writes nothing" \
  test -n "$(git rev-parse -q --verify MERGE_HEAD)" -a "$(state)" = "$before"

run "$first:target"
check "target at a stopped merge writes the file and resolves" 0 "$rc" \
  "wrote rewrite.txt" "resolved mechanical=0 target=1 incoming=0 both=0"
expect "target at a stopped merge takes the target branch's side" cmp -s rewrite.txt "$tmp/merge.target"
expect "the written file is staged, so the merge has nothing unmerged" test -z "$(git ls-files -u)"

# A stopped merge in a repository where an earlier rebase already finished: git 2.55 leaves a stale
# REBASE_HEAD behind after `rebase --continue` completes, even though no rebase-merge or rebase-apply
# directory remains. The stop is still the merge's, and its undo is the merge's own.
fresh stale-rebase-head
printf 'x\ny\nz\n' >rewrite.txt
commit base
g switch -q -c feature
printf 'x\nFEATURE\nz\n' >rewrite.txt
commit feature
g switch -q main
printf 'x\nMAIN\nz\n' >rewrite.txt
commit main-edit
g switch -q feature
g rebase main >/dev/null 2>&1
printf 'x\nMAIN\nz\n' >rewrite.txt
g add rewrite.txt
g -c core.editor=true -c rerere.enabled=false rebase --continue >/dev/null 2>&1
expect "the finished rebase leaves REBASE_HEAD behind, the git 2.55 quirk this scenario covers" \
  git rev-parse -q --verify REBASE_HEAD
expect "no rebase state directory survives the finished rebase" \
  test ! -e .git/rebase-merge -a ! -e .git/rebase-apply

g switch -q -c topic
printf 'x\nTOPIC\nz\n' >rewrite.txt
commit topic
g switch -q feature
printf 'x\nFEATURE AGAIN\nz\n' >rewrite.txt
commit feature-again
g merge topic >/dev/null 2>&1
expect "the merge actually stops with a real conflict" test -n "$(git ls-files -u)"

run
first="$(sed -n 's/^id //p' <<<"$out")"
check "a stopped merge after a finished rebase's stale REBASE_HEAD carries the merge's own undo" 1 "$rc" \
  "Undo: git merge --abort"
check_absent "the question never offers the finished rebase's undo, stale REBASE_HEAD or not" 1 "$rc" \
  "Undo: git rebase --abort"

run "$first:stop"
check "stop after a finished rebase's stale REBASE_HEAD blocks with the merge's undo" 3 "$rc" \
  "undo git merge --abort"
check_absent "stop never reports the operation as a rebase because of a stale REBASE_HEAD" 3 "$rc" \
  "undo git rebase --abort"

if [ "$fails" = 0 ]; then echo "all ok"; else
  echo "$fails failing"
  exit 1
fi
