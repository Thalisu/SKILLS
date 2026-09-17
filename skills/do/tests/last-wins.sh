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

# A rebase stopped on a `.env` both sides appended the same DENY definition to, byte for byte: the
# developer's branch and the commit being replayed each set DENY to the same deny list, and each also
# appended a line of its own that no other side defines, so the file still conflicts. The union
# defines DENY twice with identical bytes, and a reader that takes the last definition it meets loses
# nothing, so the run has nothing to set aside.
fresh env-identical-duplicate
printf 'APP=one\n' >.env
commit base
g switch -q -c do/run
printf 'APP=one\nINCOMING_ONLY=i\nDENY=admin,root\n' >.env
commit incoming
g switch -q main
printf 'APP=one\nTARGET_ONLY=t\nDENY=admin,root\n' >.env
commit target
g switch -q do/run
g rebase main >/dev/null 2>&1

write_unions
expect "the union the integration wrote defines DENY twice with the same bytes" \
  test "$(cat .env)" = "$(printf 'APP=one\nTARGET_ONLY=t\nDENY=admin,root\nINCOMING_ONLY=i\nDENY=admin,root')"

run
ledger="$PWD/.scratch/run.ledger.md"

check_lines "the read-back names the key whose two identical definitions it collapsed into one and counts it as deduped" 0 "$rc" \
  "deduped .env DENY" "read-back files=1 kept=0 deduped=1"
absent "a definition identical on both sides is not named kept, since nothing was set aside" "kept .env"
expect "the .env defines DENY once and keeps every other line of both sides" \
  test "$(cat .env)" = "$(printf 'APP=one\nTARGET_ONLY=t\nDENY=admin,root\nINCOMING_ONLY=i')"
expect "the one DENY definition both sides wrote stands in the landed .env" \
  test "$(grep -c '^DENY=' .env)" = 1
expect "the Target's own line stands in the landed .env" grep -qxF -- 'TARGET_ONLY=t' .env
expect "the Incoming's own line stands in the landed .env" grep -qxF -- 'INCOMING_ONLY=i' .env

entries="$(grep -c '^## ' "$ledger" 2>/dev/null)" || entries=0
expect "a definition a reader loses nothing to leaves no entry in the ledger" test "$entries" = 0

# A rebase stopped on a `.env` whose base commit already defines DENY twice: neither side wrote either
# occurrence, and the conflict is driven by the line each side added at the same anchor. The duplicate
# is older than this union, so it is not the run's to touch and both occurrences land as the union
# block wrote them.
fresh env-duplicate-predating-the-union
printf 'APP=one\nDENY=admin\nDENY=root\n' >.env
commit base
g switch -q -c do/run
printf 'APP=one\nINCOMING_ONLY=i\nDENY=admin\nDENY=root\n' >.env
commit incoming
g switch -q main
printf 'APP=one\nTARGET_ONLY=t\nDENY=admin\nDENY=root\n' >.env
commit target
g switch -q do/run
g rebase main >/dev/null 2>&1

write_unions
union="$(cat .env)"
expect "the union the integration wrote carries both of the base commit's DENY definitions" \
  test "$union" = "$(printf 'APP=one\nTARGET_ONLY=t\nINCOMING_ONLY=i\nDENY=admin\nDENY=root')"

run
ledger="$PWD/.scratch/run.ledger.md"

check_lines "the read-back counts the file it read and touches neither occurrence of a duplicate neither side wrote" 0 "$rc" \
  "read-back files=1 kept=0 deduped=0"
absent "a duplicate older than the union is not named kept" "kept .env"
absent "a duplicate older than the union is not named deduped" "deduped .env"
expect "the .env lands exactly as the union block wrote it" test "$(cat .env)" = "$union"
expect "both of the base commit's DENY definitions stand in the landed .env" \
  test "$(grep -c '^DENY=' .env)" = 2

entries="$(grep -c '^## ' "$ledger" 2>/dev/null)" || entries=0
expect "a duplicate older than the union leaves no entry in the ledger" test "$entries" = 0

# A rebase stopped on a `.env` whose base commit already defines DENY twice with the same bytes, and
# whose conflict is driven by the line each side added at the same anchor. A reader of the landed file
# would lose nothing to either occurrence, but neither side wrote them: the duplicate is older than
# this union, so it is not the run's to collapse and both occurrences land as the union block wrote
# them.
fresh env-identical-duplicate-predating-the-union
printf 'APP=one\nDENY=admin\nDENY=admin\n' >.env
commit base
g switch -q -c do/run
printf 'APP=one\nINCOMING_ONLY=i\nDENY=admin\nDENY=admin\n' >.env
commit incoming
g switch -q main
printf 'APP=one\nTARGET_ONLY=t\nDENY=admin\nDENY=admin\n' >.env
commit target
g switch -q do/run
g rebase main >/dev/null 2>&1

write_unions
union="$(cat .env)"
expect "the union the integration wrote carries both of the base commit's identical DENY definitions" \
  test "$union" = "$(printf 'APP=one\nTARGET_ONLY=t\nINCOMING_ONLY=i\nDENY=admin\nDENY=admin')"

run
ledger="$PWD/.scratch/run.ledger.md"

check_lines "the read-back counts the file it read and collapses neither occurrence of an identical duplicate neither side wrote" 0 "$rc" \
  "read-back files=1 kept=0 deduped=0"
absent "an identical duplicate older than the union is not named kept" "kept .env"
absent "an identical duplicate older than the union is not named deduped" "deduped .env"
expect "the .env lands exactly as the union block wrote it" test "$(cat .env)" = "$union"
expect "both of the base commit's identical DENY definitions stand in the landed .env" \
  test "$(grep -c '^DENY=admin$' .env)" = 2
expect "the Target's own line stands in the landed .env" grep -qxF -- 'TARGET_ONLY=t' .env
expect "the Incoming's own line stands in the landed .env" grep -qxF -- 'INCOMING_ONLY=i' .env

entries="$(grep -c '^## ' "$ledger" 2>/dev/null)" || entries=0
expect "an identical duplicate older than the union leaves no entry in the ledger" test "$entries" = 0

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

# A rebase stopped on a `*.yaml` whose base commit carries one `web:` mapping under `services:`: the
# Target set `deny` to a real deny list inside it, the commit being replayed emptied `deny` under the
# same mapping, and each side added one key of its own at the same anchor. One scope, one key, two
# definitions, and a YAML reader takes the last one it meets.
fresh yaml-same-scope
mkdir -p config
cat >config/settings.yaml <<'YAML'
services:
  web:
    image: web:1
    port: 80
YAML
commit base
g switch -q -c do/run
cat >config/settings.yaml <<'YAML'
services:
  web:
    image: web:1
    incoming_only: i
    deny: []
    port: 80
YAML
commit incoming
g switch -q main
cat >config/settings.yaml <<'YAML'
services:
  web:
    image: web:1
    target_only: t
    deny: [admin, root]
    port: 80
YAML
commit target
g switch -q do/run
g rebase main >/dev/null 2>&1

write_unions
expect "the union the integration wrote defines services.web.deny twice under one mapping" \
  test "$(grep -c 'deny:' config/settings.yaml)" = 2

run
ledger="$PWD/.scratch/run.ledger.md"

check_lines "the read-back names the YAML key path it kept from the document root and counts the file it read" 0 "$rc" \
  "kept config/settings.yaml services.web.deny" "read-back files=1 kept=1 deduped=0"
expect "the YAML keeps the Target's deny definition, drops the Incoming's, and keeps every other line of both sides" \
  test "$(cat config/settings.yaml)" = "$(
    cat <<'YAML'
services:
  web:
    image: web:1
    target_only: t
    deny: [admin, root]
    incoming_only: i
    port: 80
YAML
  )"
expect "the Target's deny definition stands in the landed YAML" \
  grep -qxF -- '    deny: [admin, root]' config/settings.yaml
expect "the Incoming's deny definition is gone from the landed YAML" \
  test -z "$(grep -xF -- '    deny: []' config/settings.yaml)"

expect "the dropped YAML definition leaves one entry in the ledger" \
  test "$(grep -c '^## ' "$ledger" 2>/dev/null)" = 1
keys="$(ledger_part "$ledger" config/settings.yaml keys 2>/dev/null)"
expect "the entry names the YAML file the definition was dropped from" \
  grep -qxF -- '- file: config/settings.yaml' <<<"$keys"
expect "the YAML entry is shaped last-wins-duplicate" grep -qxF -- '- shape: last-wins-duplicate' <<<"$keys"
expect "the YAML entry locates the definition by its key path from the document root" \
  grep -qxF -- '- location: services.web.deny' <<<"$keys"
expect "the YAML entry sets aside the Incoming's definition" \
  test "$(ledger_part "$ledger" config/settings.yaml incoming 2>/dev/null)" = '    deny: []'

# The same key name, once under each of two sibling mappings, in a `*.yml` the registry matches by the
# same row: the Target defined `deny` under `services.web` and the replayed commit defined it under
# `services.api`. The file conflicts over the keys the two sides added under `services.web` at the same
# anchor, so the union reaches the script, but no scope defines `deny` twice and a YAML reader loses
# nothing.
fresh yaml-two-scopes
cat >services.yml <<'YAML'
services:
  web:
    image: web:1
    port: 80
  api:
    image: api:1
    port: 81
YAML
commit base
g switch -q -c do/run
cat >services.yml <<'YAML'
services:
  web:
    image: web:1
    incoming_only: i
    port: 80
  api:
    image: api:1
    deny: [root]
    port: 81
YAML
commit incoming
g switch -q main
cat >services.yml <<'YAML'
services:
  web:
    image: web:1
    target_only: t
    deny: [admin]
    port: 80
  api:
    image: api:1
    port: 81
YAML
commit target
g switch -q do/run
g rebase main >/dev/null 2>&1

write_unions
union="$(cat services.yml)"
expect "the union the integration wrote defines deny once under each of the two mappings" \
  test "$(grep -c 'deny:' services.yml)" = 2

run
ledger="$PWD/.scratch/run.ledger.md"

check_lines "the read-back counts the .yml it read and keeps nothing" 0 "$rc" \
  "read-back files=1 kept=0 deduped=0"
absent "no key is named kept in a YAML that defines each of them once per scope" "kept services.yml"
expect "the YAML lands exactly as the union block wrote it" test "$(cat services.yml)" = "$union"
expect "the Target's deny definition stands under its own mapping" \
  grep -qxF -- '    deny: [admin]' services.yml
expect "the Incoming's deny definition stands under the other mapping" \
  grep -qxF -- '    deny: [root]' services.yml

entries="$(grep -c '^## ' "$ledger" 2>/dev/null)" || entries=0
expect "a YAML key each scope defines once leaves no entry in the ledger" test "$entries" = 0

# A rebase stopped on a `*.toml` whose base commit carries one `[services.web]` table: the Target set
# `deny` to a real deny list under it, the commit being replayed emptied `deny` under the same table,
# and each side added one key of its own at the same anchor. One table, one key, two definitions, and
# a TOML reader takes the last one it meets.
fresh toml-same-scope
mkdir -p config
cat >config/settings.toml <<'TOML'
[services.web]
image = "web:1"
port = 80
TOML
commit base
g switch -q -c do/run
cat >config/settings.toml <<'TOML'
[services.web]
image = "web:1"
incoming_only = "i"
deny = []
port = 80
TOML
commit incoming
g switch -q main
cat >config/settings.toml <<'TOML'
[services.web]
image = "web:1"
target_only = "t"
deny = ["admin", "root"]
port = 80
TOML
commit target
g switch -q do/run
g rebase main >/dev/null 2>&1

write_unions
expect "the union the integration wrote defines services.web.deny twice under one table" \
  test "$(grep -c '^deny =' config/settings.toml)" = 2

run
ledger="$PWD/.scratch/run.ledger.md"

check_lines "the read-back names the TOML key path it kept from the table it sits under and counts the file it read" 0 "$rc" \
  "kept config/settings.toml services.web.deny" "read-back files=1 kept=1 deduped=0"
expect "the TOML keeps the Target's deny definition, drops the Incoming's, and keeps every other line of both sides" \
  test "$(cat config/settings.toml)" = "$(
    cat <<'TOML'
[services.web]
image = "web:1"
target_only = "t"
deny = ["admin", "root"]
incoming_only = "i"
port = 80
TOML
  )"
expect "the Target's deny definition stands in the landed TOML" \
  grep -qxF -- 'deny = ["admin", "root"]' config/settings.toml
expect "the Incoming's deny definition is gone from the landed TOML" \
  test -z "$(grep -xF -- 'deny = []' config/settings.toml)"

expect "the dropped TOML definition leaves one entry in the ledger" \
  test "$(grep -c '^## ' "$ledger" 2>/dev/null)" = 1
keys="$(ledger_part "$ledger" config/settings.toml keys 2>/dev/null)"
expect "the entry names the TOML file the definition was dropped from" \
  grep -qxF -- '- file: config/settings.toml' <<<"$keys"
expect "the TOML entry is shaped last-wins-duplicate" grep -qxF -- '- shape: last-wins-duplicate' <<<"$keys"
expect "the TOML entry locates the definition by its key path from the table it sits under" \
  grep -qxF -- '- location: services.web.deny' <<<"$keys"
expect "the TOML entry sets aside the Incoming's definition" \
  test "$(ledger_part "$ledger" config/settings.toml incoming 2>/dev/null)" = 'deny = []'

# The same key name, once under each of two tables: the Target defined `deny` under
# `[services.web]` and the replayed commit defined it under `[services.api]`. The file conflicts over
# the keys the two sides added under `[services.web]` at the same anchor, so the union reaches the
# script, but no table defines `deny` twice and a TOML reader loses nothing.
fresh toml-two-scopes
cat >services.toml <<'TOML'
[services.web]
image = "web:1"
port = 80

[services.api]
image = "api:1"
port = 81
TOML
commit base
g switch -q -c do/run
cat >services.toml <<'TOML'
[services.web]
image = "web:1"
incoming_only = "i"
port = 80

[services.api]
image = "api:1"
deny = ["root"]
port = 81
TOML
commit incoming
g switch -q main
cat >services.toml <<'TOML'
[services.web]
image = "web:1"
target_only = "t"
deny = ["admin"]
port = 80

[services.api]
image = "api:1"
port = 81
TOML
commit target
g switch -q do/run
g rebase main >/dev/null 2>&1

write_unions
union="$(cat services.toml)"
expect "the union the integration wrote defines deny once under each of the two tables" \
  test "$(grep -c '^deny =' services.toml)" = 2

run
ledger="$PWD/.scratch/run.ledger.md"

check_lines "the read-back counts the .toml it read and keeps nothing" 0 "$rc" \
  "read-back files=1 kept=0 deduped=0"
absent "no key is named kept in a TOML that defines each of them once per table" "kept services.toml"
expect "the TOML lands exactly as the union block wrote it" test "$(cat services.toml)" = "$union"
expect "the Target's deny definition stands under its own table" \
  grep -qxF -- 'deny = ["admin"]' services.toml
expect "the Incoming's deny definition stands under the other table" \
  grep -qxF -- 'deny = ["root"]' services.toml

entries="$(grep -c '^## ' "$ledger" 2>/dev/null)" || entries=0
expect "a TOML key each table defines once leaves no entry in the ledger" test "$entries" = 0

# A rebase stopped on a `*.ini` whose base commit carries one `[web]` section: the Target set `deny`
# to a real deny list under it, the commit being replayed emptied `deny` under the same section, and
# each side added one key of its own at the same anchor. One section, one key, two definitions, and an
# INI reader takes the last one it meets.
fresh ini-same-scope
mkdir -p config
cat >config/settings.ini <<'INI'
[web]
image = web:1
port = 80
INI
commit base
g switch -q -c do/run
cat >config/settings.ini <<'INI'
[web]
image = web:1
incoming_only = i
deny =
port = 80
INI
commit incoming
g switch -q main
cat >config/settings.ini <<'INI'
[web]
image = web:1
target_only = t
deny = admin,root
port = 80
INI
commit target
g switch -q do/run
g rebase main >/dev/null 2>&1

write_unions
expect "the union the integration wrote defines web.deny twice under one section" \
  test "$(grep -c '^deny' config/settings.ini)" = 2

run
ledger="$PWD/.scratch/run.ledger.md"

check_lines "the read-back names the INI key path it kept from the section it sits under and counts the file it read" 0 "$rc" \
  "kept config/settings.ini web.deny" "read-back files=1 kept=1 deduped=0"
expect "the INI keeps the Target's deny definition, drops the Incoming's, and keeps every other line of both sides" \
  test "$(cat config/settings.ini)" = "$(
    cat <<'INI'
[web]
image = web:1
target_only = t
deny = admin,root
incoming_only = i
port = 80
INI
  )"
expect "the Target's deny definition stands in the landed INI" \
  grep -qxF -- 'deny = admin,root' config/settings.ini
expect "the Incoming's deny definition is gone from the landed INI" \
  test -z "$(grep -xF -- 'deny =' config/settings.ini)"

expect "the dropped INI definition leaves one entry in the ledger" \
  test "$(grep -c '^## ' "$ledger" 2>/dev/null)" = 1
keys="$(ledger_part "$ledger" config/settings.ini keys 2>/dev/null)"
expect "the entry names the INI file the definition was dropped from" \
  grep -qxF -- '- file: config/settings.ini' <<<"$keys"
expect "the INI entry is shaped last-wins-duplicate" grep -qxF -- '- shape: last-wins-duplicate' <<<"$keys"
expect "the INI entry locates the definition by its key path from the section it sits under" \
  grep -qxF -- '- location: web.deny' <<<"$keys"
expect "the INI entry sets aside the Incoming's definition" \
  test "$(ledger_part "$ledger" config/settings.ini incoming 2>/dev/null)" = 'deny ='

# The same stop read back a second time, the way a rerun reaches it: the script stages nothing, so the
# index stages are still there and the run's union block writes the same union over the file the first
# read-back left. The entry is keyed by the file, the key path and the two sides' bytes, none of which
# move when the dropped line does, so the second read-back rewrites the entry it already wrote instead
# of adding a second one.
fresh env-rerun
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

write_unions
run
ledger="$PWD/.scratch/run.ledger.md"
check_lines "the first read-back at the stop names the key it kept" 0 "$rc" \
  "kept .env DENY" "read-back files=1 kept=1 deduped=0"
cp "$ledger" "$tmp/rerun.ledger"
cp .env "$tmp/rerun.env"

write_unions
expect "the run's union block rebuilds the same union from the stages the read-back left unmerged" \
  test "$(cat .env)" = "$(printf 'APP=one\nTARGET_ONLY=t\nDENY=admin,root\nINCOMING_ONLY=i\nDENY=')"

run
check_lines "a second read-back at the same stop reads the file back again and names the same key" 0 "$rc" \
  "kept .env DENY" "read-back files=1 kept=1 deduped=0"
expect "the second read-back lands the .env exactly as the first one did" \
  test "$(cat .env)" = "$(cat "$tmp/rerun.env")"
expect "a second read-back leaves one entry in the ledger and not a second one for the same key" \
  test "$(grep -c '^## ' "$ledger" 2>/dev/null)" = 1
expect "the second read-back rewrites the entry where it stands, leaving the ledger byte for byte" \
  cmp -s "$ledger" "$tmp/rerun.ledger"
expect "the rewritten entry still sets aside the Incoming's definition" \
  test "$(ledger_part "$ledger" .env incoming 2>/dev/null)" = 'DENY='

if [ "$fails" = 0 ]; then echo "all ok"; else
  echo "$fails failing"
  exit 1
fi
