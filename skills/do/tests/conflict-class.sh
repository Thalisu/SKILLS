#!/usr/bin/env bash
# conflict-class.sh: the contract of scripts/conflict-class.sh, the door script that classes every
# conflicted hunk of a stopped rebase or merge, exercised in a throwaway git repository.
# Run: bash skills/do/tests/conflict-class.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
door="$here/../scripts/conflict-class.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

g() { git -c user.email=t@example.com -c user.name=t "$@"; }
commit() { g add -A >/dev/null; g commit -qm "$1"; }
run() { rc=0; out="$(bash "$door" "$@" 2>&1)" || rc=$?; }
check() { # $1 label, $2 expected exit, $3 actual exit, $4.. lines that must appear (fixed strings)
  local label="$1" want="$2" rc="$3"; shift 3
  local ok=1 line
  [ "$rc" = "$want" ] || ok=0
  for line in "$@"; do grep -qF -- "$line" <<<"$out" || ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else
    echo "FAIL  $label (exit $rc, wanted $want)"; echo "      ${out//$'\n'/$'\n'      }"; fails=$((fails + 1)); fi
}

# One repository, one merge, every shape a fixture in it.
cd "$tmp" || exit 1
git init -q -b main
printf 'a\nb\n' > adjacent.txt
commit base
g branch inc

printf 'a\nTARGET\nb\n' > adjacent.txt
commit target

g switch -q inc
printf 'a\nINCOMING\nb\n' > adjacent.txt
commit incoming

g switch -q main
g merge inc >/dev/null 2>&1

run
check "both sides only added: mechanical, with the file and the hunk's location" 0 "$rc" \
  "mechanical adjacent.txt L2-L6"
check "the last line carries the verdict" 0 "$rc" \
  "verdict=mechanical mechanical=1 contested=0"

echo
if [ "$fails" = 0 ]; then echo "all ok"; else echo "$fails failed"; exit 1; fi
