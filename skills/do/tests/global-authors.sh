#!/usr/bin/env bash
# global-authors.sh: the contract of the global unit and end-to-end authors do ships for a project
# with no Testing Policy installed: each agent carries the policy's agent core byte for byte, the
# Project map the run derives with scripts/project-map.sh, and the sentences of the Playbook that
# dispatch them. Run: bash skills/do/tests/global-authors.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
skill="$here/.."
repo="$(cd "$skill/../.." && pwd -P)"
policy="$repo/skills/testing-policy"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

ok() { echo "ok    $1"; }
fail() { echo "FAIL  $1"; fails=$((fails + 1)); }
has() { # $1 label, $2 file, $3.. fixed strings that must each appear in it
  local label="$1" file="$2"; shift 2
  local s
  for s in "$@"; do grep -qF -- "$s" "$file" 2>/dev/null || { fail "$label (missing: $s)"; return; }; done
  ok "$label"
}

echo "# the agents carry the policy's core unchanged"
version="$(bash "$policy/scripts/render-policy.sh" --version)"
for kind in unit e2e; do
  agent="$skill/agents/global-$kind-test-author.md"
  if [ ! -f "$agent" ]; then fail "global-$kind-test-author ships in do's agents folder"; continue; fi
  ok "global-$kind-test-author ships in do's agents folder"
  core="$(bash "$policy/scripts/render-agent.sh" --core-only "$kind")"
  body="$(cat "$agent")"
  if [ -n "$core" ] && [[ "$body" == *"$core"* ]]; then ok "global-$kind-test-author carries the $kind core byte for byte"
  else fail "global-$kind-test-author carries the $kind core byte for byte"; fi
  has "global-$kind-test-author records the policy version its core came from" "$agent" \
    "<!-- testing-policy:agent v=$version -->"
  has "global-$kind-test-author is named for the Agent tool" "$agent" "name: global-$kind-test-author"
  template="$policy/AGENT-$(tr '[:lower:]' '[:upper:]' <<<"$kind").md"
  has "global-$kind-test-author holds the template's tools" "$agent" "$(grep -m1 '^tools:' "$template")"
  has "global-$kind-test-author names do as its only caller" "$agent" \
    "Dispatched only by the do skill" "Never on your own initiative."
  has "global-$kind-test-author reads its Project map from the file the dispatch names" "$agent" \
    "## Project map" "The Project map is not in this file."
  if grep -q '—' "$agent"; then fail "global-$kind-test-author carries no em-dash"; else ok "global-$kind-test-author carries no em-dash"; fi
done
has "the README links both global authors by name" "$repo/README.md" \
  "ln -s ~/SKILLS/skills/do/agents/global-unit-test-author.md ~/.claude/agents/global-unit-test-author.md" \
  "ln -s ~/SKILLS/skills/do/agents/global-e2e-test-author.md ~/.claude/agents/global-e2e-test-author.md"
has "the invocation contract names both global authors and their caller" "$repo/.agents/invocation.md" \
  '| `global-unit-test-author` | `do`, user-invoked |' '| `global-e2e-test-author` | `do`, user-invoked |'

echo "# scripts/project-map.sh: only what a command read"
mapper="$skill/scripts/project-map.sh"
none='none yet → /testing-policy'
check() { # $1 label, $2 expected exit, $3 actual exit, $4.. whole lines that must appear in $out
  local label="$1" want="$2" rc="$3"; shift 3
  local good=1 line
  [ "$rc" = "$want" ] || good=0
  for line in "$@"; do grep -qxF -- "$line" <<<"$out" || good=0; done
  if [ "$good" = 1 ]; then ok "$label"; else fail "$label (exit $rc, wanted $want)"; echo "      ${out//$'\n'/$'\n'      }"; fi
}
project() { # $1 dir: a git repository with its files already written
  git -C "$1" init -q -b main && git -C "$1" add -A && git -C "$1" -c user.email=t@example.com -c user.name=t commit -q -m fixture
}
map() { rc=0; out="$(bash "$mapper" "$@" 2>&1)" || rc=$?; }

p="$tmp/node"; mkdir -p "$p/src" "$p/e2e"
printf '{"scripts":{"test":"vitest run","format":"prettier --write .","test:e2e":"playwright test"}}\n' > "$p/package.json"
: > "$p/src/notes.test.ts"; : > "$p/src/tags.test.ts"; : > "$p/e2e/login.spec.ts"
project "$p"
map "$p" "$p/.scratch/f/issues/01-x.project-map.md"
check "a package.json's scripts fill the run commands and the files fill the layout" 0 "$rc" \
  "map=$p/.scratch/f/issues/01-x.project-map.md" "read=package.json" \
  "unit_run_file=npm run test -- <file>" "unit_run_all=npm run test" "unit_format=npm run format" \
  'unit_test_layout=`src/` (2 files)' \
  "e2e_run_flow=npm run test:e2e -- <flow>" "e2e_run_all=npm run test:e2e" \
  'e2e_flow_root=`e2e/` (1 file)' "verdict=written"
written="$p/.scratch/f/issues/01-x.project-map.md"
has "the map is written at the path given, every template label present" "$written" \
  "**Framework & run commands**" "- Single file: \`npm run test -- <file>\`" "**Test root & layout**" \
  "**Shared homes by role**" "**System boundaries**" "**Partial test data**" \
  "**Discovery: run all of these on every dispatch, before writing**" "**Idiom**" \
  "**Tool & run commands**" "**Preflight: every check must pass before running**" "**Flow root & naming**"
has "a slot no command read reads none yet and the command that would fill it" "$written" \
  "- Module mocks: \`$none\`" "- Page objects / interactions (or shared subflows): \`$none\`"

p="$tmp/make"; mkdir -p "$p/tests"
printf 'test:\n\tsh tests/run.sh\n\ne2e:\n\tsh e2e.sh\n' > "$p/Makefile"; : > "$p/tests/run.sh"
project "$p"
map "$p" "$p/.scratch/map.md"
check "a Makefile's targets fill the suites, never a single-file command it did not read" 0 "$rc" \
  "read=Makefile" "unit_run_all=make test" "unit_run_file=$none" "e2e_run_all=make e2e" "e2e_run_flow=$none"

p="$tmp/bare"; mkdir -p "$p/skills/a/tests"
: > "$p/skills/a/tests/one.sh"; : > "$p/README.md"
project "$p"
map "$p" "$p/.scratch/map.md"
check "a project with no runner reads none yet for every command and still reads its layout" 0 "$rc" \
  "read=none" "unit_run_all=$none" "unit_run_file=$none" "unit_format=$none" \
  'unit_test_layout=`skills/a/tests/` (1 file)' "e2e_run_flow=$none" "e2e_flow_root=$none" "verdict=written"

map "$p" "$tmp/elsewhere.md"
check "a map path outside the project's own Scratch is refused" 2 "$rc"
[ ! -e "$tmp/elsewhere.md" ] && ok "a refused map is never written" || fail "a refused map is never written"
map "$p"
check "a missing argument is a usage error" 2 "$rc"

echo
if [ "$fails" = 0 ]; then echo "all passed"; else echo "$fails failed"; exit 1; fi
