#!/usr/bin/env bash
# global-authors.sh: the contract of the global unit and end-to-end authors do ships for a project
# with no Testing Policy installed: each agent carries the policy's agent core byte for byte, and
# the Project map the run derives with scripts/project-map.sh. Run: bash skills/do/tests/global-authors.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/.."
repo="$(cd "$skill/../.." && pwd -P)"
policy="$repo/skills/testing-policy"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

echo "# the agents carry the policy's core unchanged"
for kind in unit e2e; do
  agent="$skill/agents/global-$kind-test-author.md"
  core="$(bash "$policy/scripts/render-agent.sh" --core-only "$kind")"
  body="$(cat "$agent")"
  if [ -n "$core" ] && [[ "$body" == *"$core"* ]]; then
    ok "global-$kind-test-author carries the $kind core byte for byte"
  else fail "global-$kind-test-author carries the $kind core byte for byte"; fi
done

echo "# scripts/project-map.sh: only what a command read"
mapper="$skill/scripts/project-map.sh"
none='none yet → /testing-policy'
project() { # $1 dir: a git repository with its files already written
  git -C "$1" init -q -b main && git -C "$1" add -A && git -C "$1" -c user.email=t@example.com -c user.name=t commit -q -m fixture
}
map() {
  rc=0
  out="$(bash "$mapper" "$@" 2>&1)" || rc=$?
}

p="$tmp/node"
mkdir -p "$p/src" "$p/e2e"
printf '{"scripts":{"test":"vitest run","format":"prettier --write .","test:e2e":"playwright test"}}\n' >"$p/package.json"
: >"$p/src/notes.test.ts"
: >"$p/src/tags.test.ts"
: >"$p/e2e/login.spec.ts"
project "$p"
map "$p" "$p/.scratch/f/issues/01-x.project-map.md"
check_lines "a package.json's scripts fill the run commands and the files fill the layout" 0 "$rc" \
  "map=$p/.scratch/f/issues/01-x.project-map.md" "read=package.json" \
  "unit_run_file=npm run test -- <file>" "unit_run_all=npm run test" "unit_format=npm run format" \
  "unit_test_layout=\`src/\` (2 files)" \
  "e2e_run_flow=npm run test:e2e -- <flow>" "e2e_run_all=npm run test:e2e" \
  "e2e_flow_root=\`e2e/\` (1 file)" "verdict=written"
written="$p/.scratch/f/issues/01-x.project-map.md"
has "the map is written at the path given, every template label present" "$written" \
  "**Framework & run commands**" "- Single file: \`npm run test -- <file>\`" "**Test root & layout**" \
  "**Shared homes by role**" "**System boundaries**" "**Partial test data**" \
  "**Discovery: run all of these on every dispatch, before writing**" "**Idiom**" \
  "**Tool & run commands**" "**Preflight: every check must pass before running**" "**Flow root & naming**"
has "a slot no command read reads none yet and the command that would fill it" "$written" \
  "- Module mocks: \`$none\`" "- Page objects / interactions (or shared subflows): \`$none\`"

p="$tmp/make"
mkdir -p "$p/tests"
printf 'test:\n\tsh tests/run.sh\n\ne2e:\n\tsh e2e.sh\n' >"$p/Makefile"
: >"$p/tests/run.sh"
project "$p"
map "$p" "$p/.scratch/map.md"
check_lines "a Makefile's targets fill the suites, never a single-file command it did not read" 0 "$rc" \
  "read=Makefile" "unit_run_all=make test" "unit_run_file=$none" "e2e_run_all=make e2e" "e2e_run_flow=$none"

p="$tmp/bare"
mkdir -p "$p/skills/a/tests"
: >"$p/skills/a/tests/one.sh"
: >"$p/README.md"
project "$p"
map "$p" "$p/.scratch/map.md"
check_lines "a project with no runner reads none yet for every command and still reads its layout" 0 "$rc" \
  "read=none" "unit_run_all=$none" "unit_run_file=$none" "unit_format=$none" \
  "unit_test_layout=\`skills/a/tests/\` (1 file)" "e2e_run_flow=$none" "e2e_flow_root=$none" "verdict=written"

map "$p" "$tmp/elsewhere.md"
check_lines "a map path outside the project's own Scratch is refused" 2 "$rc"
if [ ! -e "$tmp/elsewhere.md" ]; then ok "a refused map is never written"; else fail "a refused map is never written"; fi

shimbin="$tmp/shimbin"
mkdir -p "$shimbin"
for t in awk cat dirname git grep head jq mkdir sed sort uniq bash env sh tr wc basename; do
  real="$(command -v "$t" 2>/dev/null)"
  [ -n "$real" ] && ln -sf "$real" "$shimbin/$t"
done
rc=0
out="$(PATH="$shimbin" bash "$mapper" "$p" "$p/.scratch/no-realpath.md" 2>&1)" || rc=$?
check_lines "with no realpath on PATH the map path is refused, never resolved as the raw string" 2 "$rc"
if [ ! -e "$p/.scratch/no-realpath.md" ]; then
  ok "a map is never written with no realpath on PATH"
else fail "a map is never written with no realpath on PATH"; fi

map "$p"
check_lines "a missing argument is a usage error" 2 "$rc"

echo "# a map with no unit run command has a route for the loop's BLOCKED verdict"
p="$tmp/no-runner"
mkdir -p "$p/skills/a/tests"
: >"$p/skills/a/tests/one.sh"
project "$p"
map "$p" "$p/.scratch/map.md"
check_lines "the no-runner fixture leaves both unit run slots unfilled, the case the new route covers" 0 "$rc" \
  "unit_run_file=$none" "unit_run_all=$none"

echo "# every verdict a core declares has a route in the references that consume it"
# The routes only, never the passage that names the list: `RED_AS_EXPECTED` standing there would
# answer for a bare `RED` a core declares later, which is the run's whole problem.
# Each core against the one passage that consumes it, never the union of the two: a union answers
# for a route only one of them carries, so deleting the other's leaves the check green. The
# passages are asserted non-empty first, since a renamed anchor empties one and every verdict it
# should have routed then passes against the other. Emptiness is read off the passage before the
# flattening: `tr` on an empty here-string still writes a space.
loop_passage="$(passage_of "$skill/references/mechanics.md" "2. Read the verdict" "3. Write the smallest")"
flows_passage="$(passage_of "$skill/references/ticket.md" "**6. E2E flows.**" "**7. Gate.**")"
expect "the build loop passage the unit verdicts are read against is there" test -n "$loop_passage"
expect "the flows step passage the e2e verdicts are read against is there" test -n "$flows_passage"
for kind in unit e2e; do
  if [ "$kind" = unit ]; then
    route="the build loop" passage="$loop_passage"
  else
    route="the flows step" passage="$flows_passage"
  fi
  flat="$(tr '\n' ' ' <<<"$passage" | tr -s ' ')"
  mapfile -t verdicts < <(bash "$policy/scripts/render-agent.sh" --core-only "$kind" |
    sed -n 's/^\*\*Verdict\*\*: *//p' | grep -oE '`[A-Z_]+`')
  if [ "${#verdicts[@]}" -gt 0 ]; then
    ok "the $kind core declares its verdicts where the run reads them"
  else fail "the $kind core declares its verdicts where the run reads them"; fi
  for v in ${verdicts[@]+"${verdicts[@]}"}; do
    carries "$route routes the $kind core's $v" "$v"
  done
done
echo
if [ "$fails" = 0 ]; then echo "all passed"; else
  echo "$fails failed"
  exit 1
fi
