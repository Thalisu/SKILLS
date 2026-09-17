#!/usr/bin/env bash
# last-wins.sh: the contract of scripts/last-wins.sh, the script that reads back the unions a stopped
# rebase left, drops the Incoming's duplicate definition of a key whose format takes the last one it
# meets, and leaves that definition in the Loss ledger. Exercised in a throwaway git repository
# stopped on a real rebase. Run: bash skills/do/tests/last-wins.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
door="$here/../scripts/last-wins.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

# The stop's ledger sits in its own repository's scratch, the way a run's sits in the main checkout's.
# The paths reach the script on stdin NUL-delimited, the way the integration's second block pipes them.
run() {
  mkdir -p .scratch
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check reads $out
  out="$(git diff --name-only --diff-filter=U -z | bash "$door" "$PWD/.scratch/run.ledger.md" 2>&1)" || rc=$?
}

# A rebase stopped on a `.env` both sides appended to at the same anchor: the developer's branch is
# the Target and set DENY to a real deny list, the commit being replayed is the Incoming and emptied
# it. Each side also appended a line of its own that no other side defines.
fresh env-duplicate
printf 'APP=one\n' >.env
commit base
g switch -q -c do/run
printf 'APP=one\nINCOMING_ONLY=i\nDENY=\n' >.env
commit incoming
g switch -q main
printf 'APP=one\nTARGET_ONLY=t\nDENY=admin,root\n' >.env
commit target
g switch -q do/run
g rebase main >/dev/null 2>&1

# The union block of `references/mechanics.md`, `## The integration`, verbatim: what the session has
# already run at an all-mechanical stop by the time the script reads anything back. It leaves a
# `.env` that defines DENY twice, the Target's definition above the Incoming's.
stages="$(mktemp -d)"
git diff --name-only --diff-filter=U -z | while IFS= read -r -d '' file; do
  git show ":1:$file" >"$stages/base" && git show ":2:$file" >"$stages/target" &&
    git show ":3:$file" >"$stages/incoming" &&
    git merge-file --union --diff3 -p "$stages/target" "$stages/base" "$stages/incoming" >"$file"
done
rm -rf "$stages"
expect "the union the integration wrote defines DENY twice" \
  test "$(cat .env)" = "$(printf 'APP=one\nTARGET_ONLY=t\nDENY=admin,root\nINCOMING_ONLY=i\nDENY=')"

run
ledger="$PWD/.scratch/run.ledger.md"

check_lines "the read-back names the key it kept and counts the file it read" 0 "$rc" \
  "kept .env DENY" "read-back files=1 kept=1 deduped=0"
expect "the .env keeps the Target's DENY definition, drops the Incoming's, and keeps every other line of both sides" \
  test "$(cat .env)" = "$(printf 'APP=one\nTARGET_ONLY=t\nDENY=admin,root\nINCOMING_ONLY=i')"
expect "the Target's DENY definition stands in the landed .env" grep -qxF -- 'DENY=admin,root' .env
expect "the Incoming's DENY definition is gone from the landed .env" test -z "$(grep -xF -- 'DENY=' .env)"

expect "the dropped definition leaves one entry in the ledger" \
  test "$(grep -c '^## ' "$ledger" 2>/dev/null)" = 1
keys="$(ledger_part "$ledger" .env keys 2>/dev/null)"
expect "the entry names the file the definition was dropped from" grep -qxF -- '- file: .env' <<<"$keys"
expect "the entry is shaped last-wins-duplicate" grep -qxF -- '- shape: last-wins-duplicate' <<<"$keys"
expect "the entry sets aside the Incoming's definition" \
  test "$(ledger_part "$ledger" .env incoming 2>/dev/null)" = 'DENY='

if [ "$fails" = 0 ]; then echo "all ok"; else
  echo "$fails failing"
  exit 1
fi
