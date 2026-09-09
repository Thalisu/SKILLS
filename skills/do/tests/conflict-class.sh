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
}
run() { rc=0; out="$(bash "$door" "$@" 2>&1)" || rc=$?; }
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
commit base
g branch inc
printf 'x\nTARGET\nz\n' > rewrite.txt
commit target
g switch -q inc
printf 'x\nINCOMING\nz\n' > rewrite.txt
commit incoming
g switch -q main
g merge inc >/dev/null 2>&1

run
check "two sides rewriting the same lines: contested, with the shape named" 1 "$rc" \
  "contested rewrite.txt L2-L6 rewrite-vs-rewrite"
check "the verdict follows the contested hunk" 1 "$rc" \
  "verdict=contested mechanical=0 contested=1"

echo
if [ "$fails" = 0 ]; then echo "all ok"; else echo "$fails failed"; exit 1; fi
