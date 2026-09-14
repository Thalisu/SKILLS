#!/usr/bin/env bash
# post-feature-gate.sh: the contract of the post-feature gate, the tier after a feature's own tests
# that the project picks at install (the full unit suite, the full E2E suite, both, or none), the
# Project facts line that records the pick, and the state verifier's key that names a Project facts
# line the template gained since an install, exercised against throwaway fixture projects.
# Run: bash skills/testing-policy/tests/post-feature-gate.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/.."
verify="$skill/scripts/verify-policy.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

verify() {
  rc=0
  out="$(bash "$verify" "$1" 2>&1)" || rc=$?
}
echo
echo "# the verifier names a Project facts line the template gained"
# Both fixtures carry every piece, so the key is the only thing between them: the wanted 1 fails the
# first case on a verifier that prints the key without failing the install.
policy_section_fixture "$tmp/installed-before-the-gate" native '^- \*\*Post-feature gate\*\*'
policy_pieces_fixture "$tmp/installed-before-the-gate" unit e2e
verify "$tmp/installed-before-the-gate"
check "a complete install whose section lacks the line fails, naming it among the facts the template gained" 1 "$rc" \
  "policy=current" "policy_facts_missing=**Post-feature gate**"

policy_section_fixture "$tmp/installed-with-the-gate" native ""
policy_pieces_fixture "$tmp/installed-with-the-gate" unit e2e
verify "$tmp/installed-with-the-gate"
check_absent "a complete install carrying every Project facts line passes and names none" 0 "$rc" "policy_facts_missing"
echo
if [ "$fails" = 0 ]; then echo "post-feature-gate: all checks passed"; else
  echo "post-feature-gate: $fails failed"
  exit 1
fi
