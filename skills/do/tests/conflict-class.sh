#!/usr/bin/env bash
# conflict-class.sh: the contract of scripts/conflict-class.sh, the door script that classes every
# conflicted hunk of a stopped rebase or merge, exercised in throwaway git repositories, one per
# scenario. Run: bash skills/do/tests/conflict-class.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
door="$here/../scripts/conflict-class.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

g() { git -c user.email=t@example.com -c user.name=t "$@"; }
commit() { g add -A >/dev/null; g commit -qm "$1"; }
fresh() { # $1 name: a new repository on main, entered
  mkdir -p "$tmp/$1" && cd "$tmp/$1" || exit 1
  git init -q -b main
  # Git's background maintenance races the trap's cleanup and leaves the repository undeletable.
  g config gc.auto 0
  g config maintenance.auto false
  # Every location below is the presentation git writes into the working file, so a fixture pins the
  # style rather than taking the machine's own merge.conflictStyle. The fixture at "the style git
  # wrote" covers the other styles.
  g config merge.conflictStyle merge
}
run() { rc=0; out="$(bash "$door" "$@" 2>&1)" || rc=$?; }
absent() { # $1 label, $2 expected exit, $3 actual exit, $4.. lines that must not appear
  local label="$1" want="$2" rc="$3"; shift 3
  local ok=1 line
  [ "$rc" = "$want" ] || ok=0
  for line in "$@"; do grep -qF -- "$line" <<<"$out" && ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else
    echo "FAIL  $label (exit $rc, wanted $want)"; echo "      ${out//$'\n'/$'\n'      }"; fails=$((fails + 1)); fi
}
check() { # $1 label, $2 expected exit, $3 actual exit, $4.. lines that must appear (fixed strings)
  local label="$1" want="$2" rc="$3"; shift 3
  local ok=1 line
  [ "$rc" = "$want" ] || ok=0
  for line in "$@"; do grep -qF -- "$line" <<<"$out" || ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else
    echo "FAIL  $label (exit $rc, wanted $want)"; echo "      ${out//$'\n'/$'\n'      }"; fails=$((fails + 1)); fi
}

# A tree whose every hunk is one both sides only added to.
fresh mechanical
printf 'a\nb\n' > adjacent.txt
printf 'a\nb\n' > identical.txt
commit base
g branch inc
printf 'a\nTARGET\nb\n' > adjacent.txt
printf 'a\nb\nSAME\nTARGET\n' > identical.txt
commit target
g switch -q inc
printf 'a\nINCOMING\nb\n' > adjacent.txt
printf 'a\nb\nSAME\nINCOMING\n' > identical.txt
commit incoming
g switch -q main
g merge inc >/dev/null 2>&1

run
check "both sides only added: mechanical, with the file and the hunk's location" 0 "$rc" \
  "mechanical adjacent.txt L2-L6"
check "identical additions are mechanical too, with neither copy of the shared line dropped" 0 "$rc" \
  "mechanical identical.txt L4-L8"
check "the last line carries the verdict" 0 "$rc" \
  "verdict=mechanical mechanical=2 contested=0"

# A tree carrying the shapes that make a hunk contested.
fresh contested
printf 'x\ny\nz\n' > rewrite.txt
printf 'kept\n' > dropped-by-incoming.txt
printf 'kept\n' > dropped-by-target.txt
printf 'one\ntwo\nthree\n' > renamed.txt
seq 1 12 > renamed-and-added-to.txt
printf 'pixels\000\001\002\n' > picture.bin
printf 'p\nq\nr\n' > half-resolved.txt
commit base
g branch inc
printf 'x\nTARGET\nz\n' > rewrite.txt
printf 'kept\nedited by target\n' > dropped-by-incoming.txt
rm dropped-by-target.txt
printf 'one\nTARGET\nthree\n' > renamed.txt
printf '%s\nTARGET\n' "$(cat renamed-and-added-to.txt)" > renamed-and-added-to.txt
printf 'pixels\000\001\003target\n' > picture.bin
printf 'p\nTARGET\nr\n' > half-resolved.txt
commit target
g switch -q inc
printf 'x\nINCOMING\nz\n' > rewrite.txt
rm dropped-by-incoming.txt
printf 'kept\nedited by incoming\n' > dropped-by-target.txt
g mv renamed.txt moved.txt >/dev/null
printf 'one\nINCOMING\nthree\n' > moved.txt
g mv renamed-and-added-to.txt moved-and-added-to.txt >/dev/null
printf '%s\nINCOMING\n' "$(cat moved-and-added-to.txt)" > moved-and-added-to.txt
printf 'pixels\000\001\004incoming\n' > picture.bin
printf 'p\nINCOMING\nr\n' > half-resolved.txt
commit incoming
g switch -q main
g merge inc >/dev/null 2>&1
# A file whose markers the developer has already taken out is no longer what git left, so the script
# can no longer align what it reconstructs with the tree and certifies nothing in it.
printf 'p\nRESOLVED BY HAND\nr\n' > half-resolved.txt

run
check "two sides rewriting the same lines: contested, with the shape named" 1 "$rc" \
  "contested rewrite.txt L2-L6 rewrite-vs-rewrite"
check "a delete against an edit: contested, whichever side deleted" 1 "$rc" \
  "contested dropped-by-incoming.txt whole-file delete-vs-edit" \
  "contested dropped-by-target.txt whole-file delete-vs-edit"
check "a rename against an edit: contested, named as a rename and not as a rewrite" 1 "$rc" \
  "contested moved.txt L2-L6 rename-vs-edit"
check "a rename stays contested even where both sides only added" 1 "$rc" \
  "contested moved-and-added-to.txt L13-L17 rename-vs-edit"
check "a binary file: contested, named as binary" 1 "$rc" \
  "contested picture.bin whole-file binary"
check "a file the script can no longer align with the tree: contested, named as unmergeable" 1 "$rc" \
  "contested half-resolved.txt whole-file unmergeable"
check "the verdict follows the contested hunk" 1 "$rc" \
  "verdict=contested mechanical=0 contested=7"

# A tree holding the conflicted paths git leaves no marker in: a submodule pointer moved on both
# sides, and a file whose merge driver the attributes turn off.
fresh submodule-pointer
printf 'x\n' > keep.txt
commit base
one="$(git rev-parse HEAD)"
g commit -q --allow-empty -m "a commit the target's pointer names"
two="$(git rev-parse HEAD)"
g commit -q --allow-empty -m "a commit the incoming pointer names"
three="$(git rev-parse HEAD)"
g reset -q --hard "$one"
g update-index --add --cacheinfo "160000,$one,sub"
g commit -qm "the pointer enters"
g branch inc
g update-index --add --cacheinfo "160000,$two,sub"
g commit -qm "the target moves the pointer"
g switch -q inc
g update-index --add --cacheinfo "160000,$three,sub"
g commit -qm "the incoming side moves the pointer"
g switch -q main
g merge inc >/dev/null 2>&1

run
check "a submodule pointer moved on both sides: contested, named as unmergeable" 1 "$rc" \
  "contested sub whole-file unmergeable" \
  "verdict=contested mechanical=0 contested=1"

fresh merge-driver-off
printf 'report.txt -merge\n' > .gitattributes
seq 1 10 > report.txt
commit base
g branch inc
printf 'TARGET\n%s\n' "$(cat report.txt)" > report.txt
commit target
g switch -q inc
printf '%s\nINCOMING\n' "$(cat report.txt)" > report.txt
commit incoming
g switch -q main
g merge inc >/dev/null 2>&1

run
check "a file the attributes leave with no merge driver: contested, named as unmergeable" 1 "$rc" \
  "contested report.txt whole-file unmergeable" \
  "verdict=contested mechanical=0 contested=1"

# A file whose own text shows an example conflict, renamed by the incoming side and appended to by
# both. The marker line the text carries sits above the one git wrote, so a rename read off the
# working file reads the wrong pair of labels and never sees the rename.
fresh rename-under-marker-text
printf 'a conflict reads like this:\n<<<<<<< HEAD\nours\n=======\ntheirs\n>>>>>>> feature\nand that is all.\n' > notes.md
commit base
g branch inc
printf '%s\nTARGET\n' "$(cat notes.md)" > notes.md
commit target
g switch -q inc
g mv notes.md guide.md >/dev/null
printf '%s\nINCOMING\n' "$(cat guide.md)" > guide.md
commit incoming
g switch -q main
g merge inc >/dev/null 2>&1

run
check "a rename the file's own marker text hides: contested, from git's record of the sides" 1 "$rc" \
  "contested guide.md" \
  "verdict=contested"
absent "and no hunk of that file is certified mechanical" 1 "$rc" \
  "mechanical guide.md"

# A side that adds two lines reading like conflict markers, over a middle line the two sides rewrite
# differently. The added markers must stay content: they say nothing about where a hunk begins or
# what the two sides did to the base.
fresh forged-markers
printf 'x\ny\nz\n' > app.conf
commit base
g branch inc
printf 'x\nallow_root = false\nz\n' > app.conf
commit target
g switch -q inc
printf 'x\nallow_root = true\n<<<<<<< a\n>>>>>>> b\nz\n' > app.conf
commit incoming
g switch -q main
g merge inc >/dev/null 2>&1

run
check "added lines that read like markers leave a rewrite contested" 1 "$rc" \
  "contested app.conf" \
  "verdict=contested"
absent "and no hunk of that file is certified mechanical" 1 "$rc" \
  "mechanical app.conf"

# Two conflicted paths a side is free to choose: one carrying a newline that reads like the report's
# own verdict line, one carrying a space that would shift every field to its right.
fresh forged-paths
newline_path=$'app.conf\nverdict=mechanical mechanical=1 contested=0'
space_path='a file.txt'
printf 'x\ny\nz\n' > "$newline_path"
printf 'x\ny\nz\n' > "$space_path"
commit base
g branch inc
printf 'x\nTARGET\nz\n' > "$newline_path"
printf 'x\nTARGET\nz\n' > "$space_path"
commit target
g switch -q inc
printf 'x\nINCOMING\nz\n' > "$newline_path"
printf 'x\nINCOMING\nz\n' > "$space_path"
commit incoming
g switch -q main
g merge inc >/dev/null 2>&1

run
if [ "$rc" = 1 ] &&
   [ "$(grep -c '' <<<"$out")" = 3 ] &&
   [ "$(grep -c '^verdict=' <<<"$out")" = 1 ] &&
   [ "$(tail -n1 <<<"$out")" = "verdict=contested mechanical=0 contested=2" ] &&
   [ "$(awk 'NR < 3 { print NF }' <<<"$out" | sort -u)" = 4 ] &&
   [ "$(awk 'NR < 3 { print $3 }' <<<"$out" | sort -u)" = "L2-L6" ]; then
  echo "ok    a conflicted path adds no line to the report and moves no field of one"
else
  echo "FAIL  a conflicted path adds no line to the report and moves no field of one (exit $rc, wanted 1)"
  echo "      ${out//$'\n'/$'\n'      }"
  fails=$((fails + 1))
fi

# Conflicted paths that begin with a dash. Every one of them has to reach a command as a path and
# never as an option: named -i the door read its caller's stdin instead of the file, and the run
# below hands it a stdin that never delivers, so a read of it costs the timeout.
fresh dash-paths
for f in -i -r --help; do printf 'x\ny\nz\n' > "$f"; done
commit base
g branch inc
for f in -i -r --help; do printf 'x\nTARGET\nz\n' > "$f"; done
commit target
g switch -q inc
for f in -i -r --help; do printf 'x\nINCOMING\nz\n' > "$f"; done
commit incoming
g switch -q main
g merge inc >/dev/null 2>&1

mkfifo "$tmp/never-delivers"
exec 9<> "$tmp/never-delivers"
rc=0; out="$(timeout 10 bash "$door" <&9 2>&1)" || rc=$?
exec 9>&-
check "a conflicted path that begins with a dash is a path and not an option" 1 "$rc" \
  "contested -i L2-L6 rewrite-vs-rewrite" \
  "contested -r L2-L6 rewrite-vs-rewrite" \
  "contested --help L2-L6 rewrite-vs-rewrite" \
  "verdict=contested mechanical=0 contested=3"

# A conflicted file too big to copy. Its three stages and the merge regenerated out of them are four
# copies of it in TMPDIR, which is RAM on many machines, so the size is read before anything is
# written. The run below is given a file size limit of 128 KiB: a run that copies a stage of this
# file dies on it, and a run that classes the file from its size alone never notices.
fresh oversized
seq 1 900000 > big.txt
commit base
g branch inc
{ echo TARGET; tail -n +2 big.txt; } > big.new && mv big.new big.txt
commit target
g switch -q inc
{ echo INCOMING; tail -n +2 big.txt; } > big.new && mv big.new big.txt
commit incoming
g switch -q main
g merge inc >/dev/null 2>&1

rc=0; out="$( (ulimit -f 256; bash "$door") 2>&1 )" || rc=$?
check "a conflicted file above the copy limit: contested, with no stage of it copied" 1 "$rc" \
  "contested big.txt whole-file too-large" \
  "verdict=contested mechanical=0 contested=1"

# A tree holding one hunk of each class.
fresh mixed
printf 'a\nb\n' > added-to.txt
printf 'x\ny\nz\n' > rewritten.txt
commit base
g branch inc
printf 'a\nTARGET\nb\n' > added-to.txt
printf 'x\nTARGET\nz\n' > rewritten.txt
commit target
g switch -q inc
printf 'a\nINCOMING\nb\n' > added-to.txt
printf 'x\nINCOMING\nz\n' > rewritten.txt
commit incoming
g switch -q main
g merge inc >/dev/null 2>&1

run
check "one contested hunk among mechanical ones makes the verdict contested and the exit 1" 1 "$rc" \
  "mechanical added-to.txt L2-L6" \
  "contested rewritten.txt L2-L6 rewrite-vs-rewrite" \
  "verdict=contested mechanical=1 contested=1"

# The style git wrote. The class is read from the stages, so it holds whatever the machine's
# merge.conflictStyle is, and the location follows the presentation, whose base section moves the
# closing marker down a line or two.
for style in diff3 zdiff3; do
  fresh "style-$style"
  g config merge.conflictStyle "$style"
  printf 'a\nb\n' > added-to.txt
  printf 'x\ny\nz\n' > rewritten.txt
  commit base
  g branch inc
  printf 'a\nTARGET\nb\n' > added-to.txt
  printf 'x\nTARGET\nz\n' > rewritten.txt
  commit target
  g switch -q inc
  printf 'a\nINCOMING\nb\n' > added-to.txt
  printf 'x\nINCOMING\nz\n' > rewritten.txt
  commit incoming
  g switch -q main
  g merge inc >/dev/null 2>&1

  run
  check "under $style the class holds and the location follows the presentation" 1 "$rc" \
    "mechanical added-to.txt L2-L7" \
    "contested rewritten.txt L2-L8 rewrite-vs-rewrite" \
    "verdict=contested mechanical=1 contested=1"
done

# The same pair of sides, once as a merge and once as a rebase.
fresh rebase-equals-merge
printf 'a\nb\n' > added-to.txt
printf 'x\ny\nz\n' > rewritten.txt
commit base
g branch inc
printf 'a\nTARGET\nb\n' > added-to.txt
printf 'x\nTARGET\nz\n' > rewritten.txt
commit target
g switch -q inc
printf 'a\nINCOMING\nb\n' > added-to.txt
printf 'x\nINCOMING\nz\n' > rewritten.txt
commit incoming

g switch -q main
g merge inc >/dev/null 2>&1
run; merged_out="$out"; merged_rc="$rc"
g merge --abort
g switch -q inc
g rebase main >/dev/null 2>&1
run; rebased_out="$out"; rebased_rc="$rc"
g rebase --abort >/dev/null 2>&1

out="$merged_out"; rc="$merged_rc"
check "the merge classes both hunks before the two runs are compared" 1 "$rc" \
  "mechanical added-to.txt L2-L6" \
  "contested rewritten.txt L2-L6 rewrite-vs-rewrite"
if [ "$merged_out" = "$rebased_out" ] && [ "$merged_rc" = "$rebased_rc" ]; then
  echo "ok    the class reads the same in a stopped rebase as in a stopped merge"
else
  echo "FAIL  the class reads the same in a stopped rebase as in a stopped merge"
  echo "      merge  (exit $merged_rc): ${merged_out//$'\n'/$'\n'      }"
  echo "      rebase (exit $rebased_rc): ${rebased_out//$'\n'/$'\n'      }"
  fails=$((fails + 1))
fi

# The same additive shape twice, in a repository whose config turns git's conflict-resolution reuse
# on. Reuse is the developer's own setting and everything the integration runs would run under it: a
# resolution recorded at one stop is replayed at the next stop of the same shape, which leaves the
# index staged out of the cache and the door with nothing to class, so the mechanical path works
# once and never again on that machine. The two rounds below play the invocation the integration
# documents, its rebase, its continue and its skip with reuse off, and the class has to read the
# same both times.
step() { g -c rerere.enabled=false -c rerere.autoupdate=false "$@"; }
fresh rerere
g config rerere.enabled true
printf 'a\nb\n' > added-to.txt
commit base
g branch inc
printf 'a\nb\nTARGET\n' > added-to.txt
commit target
g switch -q inc
printf 'a\nb\nINCOMING\n' > added-to.txt
commit incoming
incoming="$(g rev-parse HEAD)"

for round in 1 2; do
  step reset -q --hard "$incoming"
  step rebase main >/dev/null 2>&1
  run
  check "round $round of the same additive shape classes mechanical under rerere.enabled" 0 "$rc" \
    "mechanical added-to.txt L3-L7" \
    "verdict=mechanical mechanical=1 contested=0"
  # The step's own resolution, so what the second round meets is what a real first round leaves.
  step show ":1:added-to.txt" > "$tmp/stage1"
  step show ":2:added-to.txt" > "$tmp/stage2"
  step show ":3:added-to.txt" > "$tmp/stage3"
  step merge-file --union -p "$tmp/stage2" "$tmp/stage1" "$tmp/stage3" > added-to.txt
  step add -- added-to.txt
  step -c core.editor=true rebase --continue >/dev/null 2>&1
done
if [ -z "$(ls -A .git/rr-cache 2>/dev/null)" ]; then
  echo "ok    nothing the two rounds resolved is recorded into the developer's reuse cache"
else
  echo "FAIL  nothing the two rounds resolved is recorded into the developer's reuse cache"
  fails=$((fails + 1))
fi

# A tree git stopped nothing in.
fresh unconflicted
printf 'a\nb\n' > settled.txt
commit base

run
check "a tree carrying no conflicted state gets one line saying so" 0 "$rc" \
  "no conflicted state, nothing classed"
absent "and nothing is classed" 0 "$rc" "mechanical" "contested" "verdict="

# The doors, and the promise that no path writes.
mkdir -p "$tmp/plain" && cd "$tmp/plain" || exit 1

run classify
check "a mistyped command gets the usage line" 2 "$rc" \
  "usage: conflict-class.sh"
absent "and nothing is read, so the place is never reported on" 2 "$rc" \
  "not a git repository"

run
check "a place that is not a git repository gets its own line" 2 "$rc" \
  "not a git repository"

# A conflicted repository the script has not been run in, so a write from this run has nowhere to
# hide behind an earlier one.
fresh untouched
printf 'x\ny\nz\n' > rewrite.txt
commit base
g branch inc
printf 'x\nTARGET\nz\n' > rewrite.txt
commit target
g switch -q inc
printf 'x\nINCOMING\nz\n' > rewrite.txt
commit incoming
g switch -q main
g merge inc >/dev/null 2>&1

state() { git status --porcelain=v2; find . -path ./.git -prune -o -type f -print | sort | xargs sha256sum; }
before="$(state)"
run
after="$(state)"
check "the run still classes, so the comparison below is over a real run" 1 "$rc" \
  "contested rewrite.txt L2-L6 rewrite-vs-rewrite"
if [ "$before" = "$after" ]; then
  echo "ok    the tree is left as git left it"
else
  echo "FAIL  the tree is left as git left it"
  diff <(echo "$before") <(echo "$after") | sed 's/^/      /'
  fails=$((fails + 1))
fi

# A run from a directory that is not the top.
fresh subdirectory
mkdir -p nested/deeper
printf 'x\ny\nz\n' > nested/deeper/rewrite.txt
commit base
g branch inc
printf 'x\nTARGET\nz\n' > nested/deeper/rewrite.txt
commit target
g switch -q inc
printf 'x\nINCOMING\nz\n' > nested/deeper/rewrite.txt
commit incoming
g switch -q main
g merge inc >/dev/null 2>&1
cd nested || exit 1

run
check "run from a subdirectory, the file is named from the repository top" 1 "$rc" \
  "contested nested/deeper/rewrite.txt L2-L6 rewrite-vs-rewrite"

# The review's landing classes a moved target with its own copy, so a copy that drifts gives the
# review back a judgement ADR 0028 took out of every agent.
copy="$here/../../do-code-review/scripts/conflict-class.sh"
if cmp -s "$door" "$copy"; then
  echo "ok    do-code-review's conflict-class.sh is the verbatim copy of do's"
else
  echo "FAIL  do-code-review's conflict-class.sh drifted from do's, or is missing"; fails=$((fails + 1))
fi
if [ -x "$copy" ]; then echo "ok    do-code-review's copy is executable"; else
  echo "FAIL  do-code-review's copy is not executable"; fails=$((fails + 1)); fi

echo
if [ "$fails" = 0 ]; then echo "all ok"; else echo "$fails failed"; exit 1; fi
