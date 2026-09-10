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

if [ "$fails" = 0 ]; then echo "all ok"; else echo "$fails failing"; exit 1; fi
