#!/usr/bin/env bash
# integrate-door.sh: the contract of scripts/integrate-door.sh, the door a standalone integration
# request passes before anything is integrated, exercised in a throwaway git repository.
# Run: bash skills/do/tests/integrate-door.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
door="$here/../scripts/integrate-door.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

run() {
  rc=0
  out="$(bash "$door" "$@" 2>&1)" || rc=$?
}
one_message_naming() { # $1 the branch the single message= line must name; it must end with `nothing integrated`
  local msgs
  msgs="$(grep '^message=' <<<"$out")"
  [ "$(grep -c . <<<"$msgs")" = 1 ] && grep -qF -- "$1" <<<"$msgs" && grep -qE 'nothing integrated$' <<<"$msgs"
}

fresh origin
printf 'a\n' >a.txt && commit base
fresh work
g remote add origin "$tmp/origin" && g fetch -q origin
g reset -q --hard origin/main
g checkout -q -b feature/x
printf 'b\n' >b.txt && commit "feature work"

echo "# a branch that does not exist"
run rebase ghost
check_lines "a rebase onto a missing branch is refused" 1 "$rc" \
  "op=rebase" "moves=feature/x" "onto=ghost" "writes=feature/x" "refused=missing-branch"
expect "the rebase refusal is one message naming the missing branch and ending nothing integrated" \
  one_message_naming ghost

run merge ghost
check_lines "a merge of a missing branch is refused" 1 "$rc" \
  "op=merge" "moves=ghost" "onto=feature/x" "writes=feature/x" "refused=missing-branch"
expect "the merge refusal is one message naming the missing branch and ending nothing integrated" \
  one_message_naming ghost

run rebase origin/main
absent "a remote-tracking ref of that name is not a missing branch" "refused=missing-branch"

echo
if [ "$fails" = 0 ]; then echo "integrate-door: all checks passed"; else
  echo "integrate-door: $fails failed"
  exit 1
fi
