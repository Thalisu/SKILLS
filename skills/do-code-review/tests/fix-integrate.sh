#!/usr/bin/env bash
# fix-integrate.sh: the contract of scripts/fix-integrate.sh, which brings a wave of Fixer branches
# onto the reviewed branch in Finding order and prints, per Finding, the sha it has there.
# Run: bash skills/do-code-review/tests/fix-integrate.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/fix-integrate.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

git() { g "$@"; }
run() {
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines reads $out
  out="$(cd "$tmp" && bash "$script" "$@" 2>&1)" || rc=$?
}
fixer_branch() { # $1 name, $2 file, $3 content: a branch one commit (message <name>) ahead of main, back on main
  git checkout -q -b "$1" main
  printf '%s\n' "$3" >"$2"
  commit "$1"
  git checkout -q main
}

fresh clean
main="$tmp/clean"
printf 'base\n' >README.md
commit base
fixer_branch f1 one.txt "finding one"
fixer_branch f2 two.txt "finding two"
run "$main" 2=f2 1=f1
check_lines "two clean picks passed out of order land in Finding order, each with its sha on the reviewed branch: exit 0" \
  0 "$rc" "picked 1 $(git -C "$main" rev-parse main~1 2>/dev/null)" "picked 2 $(git -C "$main" rev-parse main)"
expect "the reviewed branch carries Finding 1's commit before Finding 2's" \
  test "$(git -C "$main" log --format=%s -3 main | tr '\n' ' ')" = "f2 f1 base "

echo
if [ "$fails" = 0 ]; then echo "fix-integrate: all checks passed"; else
  echo "fix-integrate: $fails failed"
  exit 1
fi
