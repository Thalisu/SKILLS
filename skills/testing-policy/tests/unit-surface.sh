#!/usr/bin/env bash
# unit-surface.sh: the contract of the unit surface, the install for a project with unit tests and no
# E2E tier at all, exercised against a throwaway fixture project.
# Run: bash skills/testing-policy/tests/unit-surface.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/.."
verify="$skill/scripts/verify-policy.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

echo "# the verifier reads a unit install"
project="$tmp/unit-only"
policy_section_fixture "$project" unit ""
policy_pieces_fixture "$project" unit
rc=0
out="$(bash "$verify" "$project" 2>&1)" || rc=$?
check_lines "a complete unit install with no E2E agent is current, on the unit surface, with the E2E agent not applicable" 0 "$rc" \
  "policy=current" "surface=unit" "agent_e2e=n/a"

echo
echo "# the policy rendered for the unit surface"
rc=0
out="$(bash "$skill/scripts/render-policy.sh" unit 2>&1)" || rc=$?
e2e_lines="$(grep -inF -- e2e <<<"$out")"
if [ "$rc" = 0 ] && [ -z "$e2e_lines" ]; then
  ok "the unit render demands no E2E tier: it never mentions E2E, in the core or in Project facts"
else
  fail "the unit render demands no E2E tier: it never mentions E2E, in the core or in Project facts (exit $rc, wanted 0; lines naming E2E below)"
  echo "      ${e2e_lines//$'\n'/$'\n'      }"
fi

echo
if [ "$fails" = 0 ]; then echo "unit-surface: all checks passed"; else
  echo "unit-surface: $fails failed"
  exit 1
fi
