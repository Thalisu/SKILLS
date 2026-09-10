#!/usr/bin/env bash
# post-feature-gate.sh: the contract of the post-feature gate, the tier after a feature's own tests
# that the project picks at install (the full unit suite, the full E2E suite, both, or none), the
# Project facts line that records the pick, and the state verifier's key that names a Project facts
# line the template gained since an install, exercised against throwaway fixture projects.
# Run: bash skills/testing-policy/tests/post-feature-gate.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
skill="$here/.."
render_policy="$skill/scripts/render-policy.sh"
render_agent="$skill/scripts/render-agent.sh"
verify="$skill/scripts/verify-policy.sh"
page="$(cd "$skill/../.." && pwd -P)/docs/testing-policy.md"
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
absent() { # $1 label, $2 expected exit, $3 actual exit, $4.. lines that must not appear; output in $out
  local label="$1" want="$2" rc="$3"; shift 3
  local ok=1 line found=""
  [ "$rc" = "$want" ] || ok=0
  for line in "$@"; do if grep -qF -- "$line" <<<"$out"; then ok=0; found="$found $line"; fi; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else
    echo "FAIL  $label (exit $rc, wanted $want, found:$found)"; fails=$((fails + 1)); fi
}
policy() { rc=0; out="$(bash "$render_policy" "$@" 2>&1)" || rc=$?; }
# Project facts alone: everything the render prints after the core, the part a refresh preserves.
facts() { rc=0; out="$(bash "$render_policy" "$1" | awk '/^<!-- testing-policy:core-end -->$/{f=1; next} f')" || rc=$?; }
verify() { rc=0; out="$(bash "$verify" "$1" 2>&1)" || rc=$?; }
# A project whose policy section is the current render with every slot filled, minus the lines the
# caller's grep pattern drops.
section_fixture() { # $1 project dir, $2 grep -v pattern (empty keeps every line)
  mkdir -p "$1"
  { echo "# Project"; echo; bash "$render_policy" native; } \
    | { if [ -n "$2" ]; then grep -vE -- "$2"; else cat; fi; } \
    | sed -E 's/\{\{[^}]*\}\}/filled/g' > "$1/CLAUDE.md"
}

echo "# the tiers in the core"
for surface in native consumer mixed; do
  policy "$surface" --core-only
  check "the $surface core runs the change's own tests on every change" 0 "$rc" \
    "the unit tests it added and the ones covering the code it touches"
  check "the $surface core leaves the tier after a feature to the gate the project picked" 0 "$rc" \
    "**Per feature**" "the post-feature gate in Project facts" "both, or none"
  absent "the $surface core no longer fixes a full suite per phase or delivery" 0 "$rc" \
    "**Per phase/delivery**" "**per phase/delivery**" "before declaring the phase or delivery complete"
  # The verifier greps the whole section for the literal label, so a core that spelled the pointer in
  # the facts line's bold form would read as the line already being there.
  absent "the $surface core's pointer does not wear the facts line's bold label" 0 "$rc" "**Post-feature gate**"
done

echo
echo "# the pick in Project facts"
for surface in native consumer mixed; do
  facts "$surface"
  check "the $surface Project facts carry the post-feature gate slot with its four answers" 0 "$rc" \
    "- **Post-feature gate**: {{POST_FEATURE_GATE" "full unit suite | full E2E suite | both | none"
done

echo
echo "# the verifier names a Project facts line the template gained"
section_fixture "$tmp/installed-before-the-gate" '^- \*\*Post-feature gate\*\*'
verify "$tmp/installed-before-the-gate"
check "a section installed before the line gets it named among the facts the template gained" 1 "$rc" \
  "policy=current" "policy_facts_missing=**Post-feature gate**"

section_fixture "$tmp/installed-with-the-gate" ""
verify "$tmp/installed-with-the-gate"
absent "a section carrying every Project facts line names none" 1 "$rc" "policy_facts_missing"

# The header alone, never the body below it: the code carries the same strings, so a case over the
# whole file would pass on a script that documents nothing.
rc=0; out="$(sed -n '1,/^set -/p' "$verify")" || rc=$?
check "the usage header names the key" 0 "$rc" "policy_facts_missing="

echo
echo "# the install asks for the pick"
rc=0; out="$(cat "$skill/SKILL.md")" || rc=$?
check "the one question carries the post-feature gate and its four answers" 0 "$rc" \
  "the post-feature gate" "the full unit suite, the full E2E suite, both, or none"
# shellcheck disable=SC2016  # the backticks are part of the fixed strings SKILL.md carries
check "a refresh asks only when Project facts lack the line" 0 "$rc" \
  '`policy_facts_missing` names **Post-feature gate**'
# shellcheck disable=SC2016
check "the refresh appends the line and keeps every other Project facts line verbatim" 0 "$rc" \
  'except a label named in `policy_facts_missing`'
# shellcheck disable=SC2016
check "the verification step requires no Project facts line missing" 0 "$rc" \
  'no `policy_facts_missing`'

# The preserved-parts paragraph is read on its own: the steps spell the same rule, so a case over the
# whole file would pass on a paragraph that still says the opposite.
rc=0; out="$(grep -F 'Generated vs preserved.' "$skill/SKILL.md")" || rc=$?
check "the preserved-parts paragraph names the facts line and where it is filled from" 0 "$rc" \
  "2.5 added **Post-feature gate** to Project facts" "**Post-feature gate** from the step-3 answer"

rc=0; out="$(awk '/^## Post-install checklist$/{f=1} f' "$skill/SKILL.md")" || rc=$?
check "the checklist covers the facts labels and the pick" 0 "$rc" \
  "Every Project-facts label" "**Post-feature gate** in Project facts reads one of the four answers"

echo
echo "# the E2E author leaves the full suite to the gate"
rc=0; out="$(bash "$render_agent" e2e)" || rc=$?
check "the E2E agent names the full suite as the post-feature gate's" 0 "$rc" "post-feature gate"
absent "the E2E agent no longer calls the full suite the delivery gate" 0 "$rc" "delivery gate"

echo
echo "# the page"
# The page is hard-wrapped prose, so it is read with its line breaks folded: a phrase that wraps is
# still the phrase.
rc=0; out="$(tr '\n' ' ' < "$page" | tr -s ' ')" || rc=$?
check "the page says the project picks the gate after a feature" 0 "$rc" \
  "the post-feature gate" "the full unit suite, the full E2E suite, both, or none"
check "the page records the version that made the gate a pick" 0 "$rc" "2.5 made the gate after a feature"

echo
echo "# repository standards"
emdash=$'\xe2\x80\x94'
prose_files=("$skill/POLICY.md" "$skill/SKILL.md" "$skill/AGENT-E2E.md" "$here/post-feature-gate.sh" "$page")
rc=0; out="$(LC_ALL=C grep -lae "$emdash" "${prose_files[@]}" || true)"
absent "no em-dash in the prose this rule wrote" 0 "$rc" \
  "POLICY.md" "SKILL.md" "AGENT-E2E.md" "post-feature-gate.sh" "testing-policy.md"

echo
if [ "$fails" = 0 ]; then echo "post-feature-gate: all checks passed"; else echo "post-feature-gate: $fails failed"; exit 1; fi
