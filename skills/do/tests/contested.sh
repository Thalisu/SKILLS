#!/usr/bin/env bash
# contested.sh: the contract of scripts/contested.sh, the script that turns every contested hunk of a
# stopped rebase into one question and applies the answers, exercised in throwaway git repositories,
# one per scenario. Run: bash skills/do/tests/contested.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
door="$here/../scripts/contested.sh"
classer="$here/../scripts/conflict-class.sh"
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
  g config rerere.enabled false
  # The locations the questions name are the presentation git writes into the working file, so the
  # fixture pins the style rather than taking the machine's own merge.conflictStyle.
  g config merge.conflictStyle merge
}
# The session is interactive unless a scenario says otherwise: the harness may have set the variable.
run() { rc=0; out="$(CLAUDE_CODE_ENTRYPOINT=cli bash "$door" "$@" 2>&1)" || rc=$?; }
check() { # $1 label, $2 expected exit, $3 actual exit, $4.. lines that must appear (fixed strings)
  local label="$1" want="$2" rc="$3"; shift 3
  local ok=1 line
  [ "$rc" = "$want" ] || ok=0
  for line in "$@"; do grep -qF -- "$line" <<<"$out" || ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else
    echo "FAIL  $label (exit $rc, wanted $want)"; echo "      ${out//$'\n'/$'\n'      }"; fails=$((fails + 1)); fi
}
absent() { # $1 label, $2 expected exit, $3 actual exit, $4.. lines that must not appear
  local label="$1" want="$2" rc="$3"; shift 3
  local ok=1 line
  [ "$rc" = "$want" ] || ok=0
  for line in "$@"; do grep -qF -- "$line" <<<"$out" && ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else
    echo "FAIL  $label (exit $rc, wanted $want)"; echo "      ${out//$'\n'/$'\n'      }"; fails=$((fails + 1)); fi
}
expect() { # $1 label, $2.. a command that must succeed
  local label="$1"; shift
  if "$@"; then echo "ok    $label"; else echo "FAIL  $label"; fails=$((fails + 1)); fi
}
# What a question must leave untouched: the unmerged index and the bytes of every working file.
state() { g ls-files -s -u; git ls-files -z -- . | xargs -0 git hash-object --; }

# The script reads the classifier's report and matches its quoted paths back to the raw ones, so its
# copy of the quoting has to stay the classifier's, byte for byte.
body() { sed -n '/^quote_path() {/,/^}/p' "$1" 2>/dev/null; }
if [ -n "$(body "$classer")" ] && [ "$(body "$classer")" = "$(body "$door")" ]; then
  echo "ok    quote_path is the verbatim copy of conflict-class.sh's"
else
  echo "FAIL  quote_path drifted from conflict-class.sh's"; fails=$((fails + 1))
fi

# A rebase stopped on two files whose one line both sides rewrote: the developer's branch is the
# Target, the commit being replayed the Incoming side.
fresh two-rewrites
printf 'x\ny\nz\n' > rewrite.txt
printf 'a\nb\nc\n' > second.txt
commit base
g switch -q -c do/run
printf 'x\nINCOMING\nz\n' > rewrite.txt
printf 'a\nINCOMING TOO\nc\n' > second.txt
commit incoming
g switch -q main
printf 'x\nTARGET\nz\n' > rewrite.txt
printf 'a\nTARGET TOO\nc\n' > second.txt
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
absent "one question at a time: the second hunk is not asked yet" 1 "$rc" \
  "Conflict 2 of 2" "TARGET TOO"
expect "asking writes nothing: the index and the working files are as git left them" \
  test "$(state)" = "$before"

# A stop carrying three contested hunks: one in a file that also carries a mechanical hunk, one whose
# last line both sides kept without a final newline, and one whose conflict is its own last line,
# without a final newline either.
fresh three-answers
seq 1 20 > mixed.txt
printf 'a\nb\nc' > plain.txt
printf 'p\nq' > third.txt
commit base
g switch -q -c do/run
{ seq 1 2; echo I3; seq 4 20; echo INCOMING END; } > mixed.txt
printf 'a\nIB\nc' > plain.txt
printf 'p\nIQ' > third.txt
commit incoming
g switch -q main
{ seq 1 2; echo T3; seq 4 20; echo TARGET END; } > mixed.txt
printf 'a\nTB\nc' > plain.txt
printf 'p\nTQ' > third.txt
commit target
g switch -q do/run
g rebase main >/dev/null 2>&1
for s in 1 2 3; do git cat-file blob ":$s:mixed.txt" > "$tmp/mixed.$s"; done
git merge-file --union -p "$tmp/mixed.2" "$tmp/mixed.1" "$tmp/mixed.3" > "$tmp/mixed.both"
git cat-file blob :2:plain.txt > "$tmp/plain.target"
git cat-file blob :3:third.txt > "$tmp/third.incoming"
before="$(state)"

run; first="$(sed -n 's/^id //p' <<<"$out")"
run "$first:both"; second="$(sed -n 's/^id //p' <<<"$out")"
check "an answer short of the last brings the next contested hunk" 1 "$rc" \
  "Conflict 2 of 3 · plain.txt"
run "$first:both" "$second:target"; third="$(sed -n 's/^id //p' <<<"$out")"
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
printf 'kept\n' > gone.txt
printf 'x\ny\nz\n' > rewrite.txt
commit base
g switch -q -c do/run
printf 'kept\nedited by incoming\n' > gone.txt
printf 'x\nINCOMING\nz\n' > rewrite.txt
commit incoming
g switch -q main
rm gone.txt
printf 'x\nTARGET\nz\n' > rewrite.txt
commit target
g switch -q do/run
g rebase main >/dev/null 2>&1
before="$(state)"
run; first="$(sed -n 's/^id //p' <<<"$out")"
run "$first:target"; second="$(sed -n 's/^id //p' <<<"$out")"

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
printf 'x\ny\nz\n' > rewrite.txt
printf 'a\nb\nc\n' > second.txt
commit base
g switch -q -c do/run
printf 'x\nINCOMING\nz\n' > rewrite.txt
printf 'a\nINCOMING TOO\nc\n' > second.txt
commit incoming
g switch -q main
printf 'x\nTARGET\nz\n' > rewrite.txt
printf 'a\nTARGET TOO\nc\n' > second.txt
commit target
g switch -q do/run
g rebase main >/dev/null 2>&1
before="$(state)"
run; first="$(sed -n 's/^id //p' <<<"$out")"
headless() { rc=0; out="$(CLAUDE_CODE_ENTRYPOINT="$1" bash "$door" "${@:2}" 2>&1)" || rc=$?; }

headless sdk-cli
check "a headless session is told no human is there, with the files it would have asked about" 4 "$rc" \
  "no human CLAUDE_CODE_ENTRYPOINT=sdk-cli" "conflicted rewrite.txt" "conflicted second.txt"
absent "a headless session is never asked a question" 4 "$rc" "Conflict 1 of"
expect "a headless session writes nothing" test "$(state)" = "$before"
headless sdk-ts "$first:target"
check "answers carried into a headless session are refused all the same" 4 "$rc" \
  "no human CLAUDE_CODE_ENTRYPOINT=sdk-ts"
expect "a headless session writes nothing of an answer it was handed" test "$(state)" = "$before"

if [ "$fails" = 0 ]; then echo "all ok"; else echo "$fails failing"; exit 1; fi
