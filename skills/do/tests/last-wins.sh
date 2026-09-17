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

# The union block of `references/mechanics.md`, `## The integration`, verbatim: what the session has
# already run at an all-mechanical stop by the time the script reads anything back. Every conflicted
# file comes out holding the union of its three stages, the Target's added lines above the Incoming's.
write_unions() {
  local stages
  stages="$(mktemp -d)"
  git diff --name-only --diff-filter=U -z | while IFS= read -r -d '' file; do
    git show ":1:$file" >"$stages/base" && git show ":2:$file" >"$stages/target" &&
      git show ":3:$file" >"$stages/incoming" &&
      git merge-file --union --diff3 -p "$stages/target" "$stages/base" "$stages/incoming" >"$file"
  done
  rm -rf "$stages"
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

# The union the integration wrote leaves a `.env` that defines DENY twice, the Target's above the
# Incoming's.
write_unions
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

# A rebase stopped on a `*.json` whose base commit carries one `services.web` object: the Target set
# `deny` to a real deny list inside it, the commit being replayed emptied `deny` inside the same
# object, and each side added one key of its own at the same anchor. One scope, one key, two
# definitions, and a JSON reader takes the last one it meets.
fresh json-same-scope
mkdir -p config
cat >config/settings.json <<'JSON'
{
  "services": {
    "web": {
      "image": "web:1",
      "port": 80
    }
  }
}
JSON
commit base
g switch -q -c do/run
cat >config/settings.json <<'JSON'
{
  "services": {
    "web": {
      "image": "web:1",
      "incoming_only": "i",
      "deny": [],
      "port": 80
    }
  }
}
JSON
commit incoming
g switch -q main
cat >config/settings.json <<'JSON'
{
  "services": {
    "web": {
      "image": "web:1",
      "target_only": "t",
      "deny": ["admin", "root"],
      "port": 80
    }
  }
}
JSON
commit target
g switch -q do/run
g rebase main >/dev/null 2>&1

write_unions
expect "the union the integration wrote defines services.web.deny twice in one object" \
  test "$(grep -c '"deny":' config/settings.json)" = 2

run
ledger="$PWD/.scratch/run.ledger.md"

check_lines "the read-back names the key path it kept from the document root and counts the file it read" 0 "$rc" \
  "kept config/settings.json services.web.deny" "read-back files=1 kept=1 deduped=0"
expect "the JSON keeps the Target's deny definition, drops the Incoming's, and keeps every other line of both sides" \
  test "$(cat config/settings.json)" = "$(
    cat <<'JSON'
{
  "services": {
    "web": {
      "image": "web:1",
      "target_only": "t",
      "deny": ["admin", "root"],
      "incoming_only": "i",
      "port": 80
    }
  }
}
JSON
  )"
expect "the Target's deny definition stands in the landed JSON" \
  grep -qxF -- '      "deny": ["admin", "root"],' config/settings.json
expect "the Incoming's deny definition is gone from the landed JSON" \
  test -z "$(grep -xF -- '      "deny": [],' config/settings.json)"

expect "the dropped definition leaves one entry in the ledger" \
  test "$(grep -c '^## ' "$ledger" 2>/dev/null)" = 1
keys="$(ledger_part "$ledger" config/settings.json keys 2>/dev/null)"
expect "the entry names the file the definition was dropped from" \
  grep -qxF -- '- file: config/settings.json' <<<"$keys"
expect "the entry is shaped last-wins-duplicate" grep -qxF -- '- shape: last-wins-duplicate' <<<"$keys"
expect "the entry locates the definition by its key path from the document root" \
  grep -qxF -- '- location: services.web.deny' <<<"$keys"
expect "the entry sets aside the Incoming's definition" \
  test "$(ledger_part "$ledger" config/settings.json incoming 2>/dev/null)" = '      "deny": [],'

# The same key name, once in each of two sibling objects: the Target defined `deny` inside
# `services.web` and the replayed commit defined it inside `services.api`. The file conflicts over the
# keys the two sides added to `services.web` at the same anchor, so the union reaches the script, but
# no scope defines `deny` twice and a JSON reader loses nothing.
fresh json-two-scopes
cat >services.json <<'JSON'
{
  "services": {
    "web": {
      "image": "web:1",
      "port": 80
    },
    "api": {
      "image": "api:1",
      "port": 81
    }
  }
}
JSON
commit base
g switch -q -c do/run
cat >services.json <<'JSON'
{
  "services": {
    "web": {
      "image": "web:1",
      "incoming_only": "i",
      "port": 80
    },
    "api": {
      "image": "api:1",
      "deny": ["root"],
      "port": 81
    }
  }
}
JSON
commit incoming
g switch -q main
cat >services.json <<'JSON'
{
  "services": {
    "web": {
      "image": "web:1",
      "target_only": "t",
      "deny": ["admin"],
      "port": 80
    },
    "api": {
      "image": "api:1",
      "port": 81
    }
  }
}
JSON
commit target
g switch -q do/run
g rebase main >/dev/null 2>&1

write_unions
union="$(cat services.json)"
expect "the union the integration wrote defines deny once in each of the two objects" \
  test "$(grep -c '"deny":' services.json)" = 2

run
ledger="$PWD/.scratch/run.ledger.md"

check_lines "the read-back counts the file it read and keeps nothing" 0 "$rc" \
  "read-back files=1 kept=0 deduped=0"
absent "no key is named kept in a file that defines each of them once per scope" "kept services.json"
expect "the JSON lands exactly as the union block wrote it" test "$(cat services.json)" = "$union"
expect "the Target's deny definition stands in its own object" \
  grep -qxF -- '      "deny": ["admin"],' services.json
expect "the Incoming's deny definition stands in the other object" \
  grep -qxF -- '      "deny": ["root"],' services.json

entries="$(grep -c '^## ' "$ledger" 2>/dev/null)" || entries=0
expect "a key each scope defines once leaves no entry in the ledger" test "$entries" = 0

if [ "$fails" = 0 ]; then echo "all ok"; else
  echo "$fails failing"
  exit 1
fi
