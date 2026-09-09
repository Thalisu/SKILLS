#!/usr/bin/env bash
# partial-test-data.sh: the contract of the partial test data rule, the Project map label that
# carries its helper, the refresh that names that label to an agent installed before it, and the
# state verifier's key for the helper, exercised against throwaway fixture projects.
# Run: bash skills/testing-policy/tests/partial-test-data.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
skill="$here/.."
render="$skill/scripts/render-agent.sh"
verify="$skill/scripts/verify-policy.sh"
render_policy="$skill/scripts/render-policy.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

check() { # $1 label, $2 expected exit, $3 actual exit, $4.. lines that must appear (fixed strings); output in $out
  local label="$1" want="$2" rc="$3"; shift 3
  local ok=1 line
  [ "$rc" = "$want" ] || ok=0
  for line in "$@"; do grep -qF -- "$line" <<<"$out" || ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else
    echo "FAIL  $label (exit $rc, wanted $want)"; head -12 <<<"$out" | sed 's/^/      /'; fails=$((fails + 1)); fi
}
empty() { # $1 label; the output in $out must be empty
  if [ -z "$out" ]; then echo "ok    $1"; else
    echo "FAIL  $1"; head -12 <<<"$out" | sed 's/^/      /'; fails=$((fails + 1)); fi
}
absent() { # $1 label, $2.. lines that must not appear; output in $out
  local label="$1"; shift
  local ok=1 line found=""
  for line in "$@"; do if grep -qF -- "$line" <<<"$out"; then ok=0; found="$found $line"; fi; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else echo "FAIL  $label (found:$found)"; fails=$((fails + 1)); fi
}
render() { rc=0; out="$(bash "$render" "$@" 2>&1)" || rc=$?; }
# The labels verify-policy.sh's map_missing() reads: the bold lead of every line after core-end.
map_labels() { rc=0; out="$(bash "$render" "$1" | awk '/^<!-- testing-policy:core-end -->$/{f=1; next} f' | grep -oE '^\*\*[^*]+\*\*')" || rc=$?; }
# The map entry alone: the label at line start and the slot under it, never the core's pointer at it.
policy() { rc=0; out="$(bash "$render_policy" "$@" 2>&1)" || rc=$?; }
map_entry() { rc=0; out="$(bash "$render" "$1" | grep -A1 -E "^\\*\\*$2\\*\\*")" || rc=$?; }
verify() { rc=0; out="$(bash "$verify" "$1" 2>&1)" || rc=$?; }
# Every piece the verifier folds into its exit code, so a case can show what a report-only key leaves
# alone. The policy section's slots are filled because an unfilled one fails the install by itself.
install_fixture() { # $1 project dir
  local p="$1"
  mkdir -p "$p/.claude/agents" "$p/.claude/skills/test-author" "$p/.claude/testing-policy"
  { echo "# Project"; echo; bash "$render_policy" native; } | sed -E 's/\{\{[^}]*\}\}/filled/g' > "$p/CLAUDE.md"
  bash "$render" unit > "$p/.claude/agents/unit-test-author.md"
  bash "$render" e2e > "$p/.claude/agents/e2e-test-author.md"
  bash "$render" test-author > "$p/.claude/skills/test-author/SKILL.md"
  : > "$p/.claude/testing-policy/scan-test-assets.sh"
  : > "$p/.claude/testing-policy/skip-patterns.sh"
}

echo "# the rule in the core"
render unit --core-only
check "the unit core forbids building a fake by asserting a type at the compiler" 0 "$rc" \
  "a fake by asserting a type at the compiler"
check "the unit core points at the Project map for the helper" 0 "$rc" \
  "Partial test data"

absent "the unit core names no package, no helper function and no assertion keyword" \
  "shoehorn" "@total-typescript" "fromPartial" "fromAny" "\`as\`" "as unknown as" "as any" "TypeScript"

echo
echo "# the tool in the Project map"
map_labels unit
check "the unit map carries a Partial test data label, where map_missing() reads labels" 0 "$rc" \
  "**Partial test data**"

rc=0; out="$(bash "$render" unit --core-only | grep -E '^\*\*Partial test data\*\*' || true)"
absent "the label line is in the preserved map, never in the regenerated core" "**Partial test data**"

map_entry unit "Partial test data"
check "the entry names the helper and the function for partial data that still type checks" 0 "$rc" \
  "fromPartial" "still type checks"
check "the entry names the function for data that is wrong on purpose" 0 "$rc" \
  "fromAny" "wrong on purpose"
check "the entry carries the not applicable value" 0 "$rc" "n/a"
check "the entry carries the none yet form naming the command that would add the helper" 0 "$rc" \
  "none yet"
check "the none yet form is a pointer, not a command that ran" 0 "$rc" \
  "not a command that ran"

echo
echo "# the rule binds the unit author alone"
render e2e --core-only
absent "the E2E core carries no partial test data rule of its own" \
  "a fake by asserting a type at the compiler" "Partial test data"
map_labels e2e
absent "the E2E map carries no Partial test data label" "**Partial test data**"

policy native
absent "the policy section in the project's instructions file is untouched" \
  "a fake by asserting a type at the compiler" "Partial test data"

render test-author
absent "the inline writer's skill carries no copy of the rule" \
  "a fake by asserting a type at the compiler" "Partial test data"
check "the inline writer reaches the rule and the entry through the agent file it already opens" 0 "$rc" \
  "The agent file is the single source of the rules" \
  "apply **## Authoring rules** and **## Project map** in full" \
  ".claude/agents/unit-test-author.md"

echo
echo "# the version"
version="$(bash "$render_policy" --version)"
old="2.3"  # the version before this rule landed, for the refresh fixture
rc=0; out="$(printf '%s\n%s\n' 2.4 "$version" | sort -V | head -1)"
check "the template version is 2.4, the step this rule landed at, or beyond (found $version)" 0 "$rc" "2.4"

render unit;        check "the rendered unit agent carries the template version"  0 "$rc" "<!-- testing-policy:agent v=$version -->"
render e2e;         check "the rendered E2E agent carries the template version"   0 "$rc" "<!-- testing-policy:agent v=$version -->"
render test-author; check "the rendered inline skill carries the template version" 0 "$rc" "<!-- testing-policy:skill v=$version -->"
policy native;      check "the rendered policy section carries the template version" 0 "$rc" "<!-- testing-policy:start v=$version surface=native -->"

echo
echo "# the refresh"
# map_missing() greps the whole installed file for the literal label, so a core that spelled the
# cross-reference in the map's own bold form would read as the label already being there.
render unit --core-only
absent "the core's pointer does not wear the map's bold label form" "**Partial test data**"

proj="$tmp/installed-at-2.3"
mkdir -p "$proj/.claude/agents"
{ echo "# Project"; echo; bash "$render_policy" native; } \
  | sed -E 's/(testing-policy:start v=)[0-9.]+/\1'"$old"'/' > "$proj/CLAUDE.md"
bash "$render" unit \
  | grep -vE '^\*\*Partial test data\*\*|^\{\{UNIT_PARTIAL_DATA_HELPER' \
  | sed -E 's/(testing-policy:agent v=)[0-9.]+/\1'"$old"'/' > "$proj/.claude/agents/unit-test-author.md"
verify "$proj"
check "an agent installed before the label gets it named among the labels the template gained" 1 "$rc" \
  "agent_unit_map_missing=**Partial test data**"

echo "# the install names the line it appends"
rc=0; out="$(cat "$skill/SKILL.md")" || rc=$?
check "the refresh step names the label as the line it fills from discovery and appends" 0 "$rc" \
  "for 2.4, **Partial test data** in the unit map"
check "the preserved-parts note names the version that added the label" 0 "$rc" \
  "2.4 added **Partial test data** to the unit map"

echo
echo "# the verifier's partial data helper key"
# The key reports the project's own state, so it is read off bare fixtures with no policy
# installed: exit 4 is `policy=none`, and the key prints all the same.
helper_pkg="@total-typescript/shoehorn"

mkdir -p "$tmp/not-ts/tests"
printf 'def test_thing():\n    assert True\n' > "$tmp/not-ts/tests/test_thing.py"

mkdir -p "$tmp/ts-without/tests"
echo '{}' > "$tmp/ts-without/tsconfig.json"
printf '{ "devDependencies": { "vitest": "^1" } }\n' > "$tmp/ts-without/package.json"
printf 'test("thing", () => {});\n' > "$tmp/ts-without/tests/thing.test.ts"

cp -r "$tmp/ts-without" "$tmp/ts-with"
printf '{ "devDependencies": { "vitest": "^1", "%s": "^0.1.2" } }\n' "$helper_pkg" > "$tmp/ts-with/package.json"

verify "$tmp/not-ts"
check "a project that is not TypeScript reads not applicable" 4 "$rc" "partial_data_helper=n/a"
verify "$tmp/ts-without"
check "an eligible project without the package reads absent" 4 "$rc" "partial_data_helper=absent"
verify "$tmp/ts-with"
check "an eligible project with the package reads installed" 4 "$rc" "partial_data_helper=installed"

# Report only, stated as the exit code: the fixture is complete, so a key inside the gate would turn
# this 0 into a 1, and the wanted 0 is what makes the case fail if it ever moves inside.
complete="$tmp/complete-without-helper"
cp -r "$tmp/ts-without" "$complete"
install_fixture "$complete"
verify "$complete"
check "a complete install reading absent keeps its exit code" 0 "$rc" "partial_data_helper=absent"

# The header alone, never the body below it: the code carries the same strings, so a case over the
# whole file would pass on a script that documents nothing.
rc=0; out="$(sed -n '1,/^set -/p' "$verify")" || rc=$?
check "the usage header names the key and its three values" 0 "$rc" \
  "partial_data_helper=n/a|absent|installed"

echo
echo "# repository standards"
emdash=$'\xe2\x80\x94'
rc=0; out="$(LC_ALL=C grep -lae "$emdash" \
  "$skill/AGENT-UNIT.md" "$skill/SKILL.md" "$skill/POLICY.md" "$here/partial-test-data.sh" || true)"
absent "no em-dash in the prose this rule wrote" \
  "AGENT-UNIT.md" "SKILL.md" "POLICY.md" "partial-test-data.sh"

# verify-policy.sh carries an em-dash inside a regex character class, which is syntax and not prose,
# so this file is read for its comment lines, where a script's prose lives.
rc=0; out="$(LC_ALL=C grep -nae "$emdash" "$verify" | grep -E '^[0-9]+:[[:space:]]*#' || true)"
empty "no em-dash in the verifier's comment prose"

echo
if [ "$fails" = 0 ]; then echo "partial-test-data: all checks passed"; else echo "partial-test-data: $fails failed"; exit 1; fi
