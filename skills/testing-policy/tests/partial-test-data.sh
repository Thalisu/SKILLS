#!/usr/bin/env bash
# partial-test-data.sh: the contract of the partial test data rule, the Project map label that
# carries its helper, the scan section that counts the assertions already in the tree and the
# verifier key that reports the helper's state, exercised against throwaway fixture projects.
# Run: bash skills/testing-policy/tests/partial-test-data.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
skill="$here/.."
render="$skill/scripts/render-agent.sh"
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
if [ "$fails" = 0 ]; then echo "partial-test-data: all checks passed"; else echo "partial-test-data: $fails failed"; exit 1; fi
