#!/usr/bin/env bash
# policy-reference.sh: the contract of the policy reference, the long-form rules an install writes to
# the project's .claude/testing-policy/policy.md, apart from the section it writes into CLAUDE.md.
# Run: bash skills/testing-policy/tests/policy-reference.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/.."
render_policy="$skill/scripts/render-policy.sh"
verify_policy="$skill/scripts/verify-policy.sh"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

run() {
  rc=0
  out="$(bash "$render_policy" "$@" 2>&1)" || rc=$?
}

version="$(bash "$render_policy" --version)"

echo "# the reference rendered for a surface, and the CLAUDE.md section rendered without it"
for surface in native consumer mixed unit; do
  run "$surface" --reference
  label="$surface: --reference prints the reference file, opened by a reference-start marker carrying the template version and the surface"
  if [ "$rc" = 0 ] &&
    [ "$(head -n 1 <<<"$out")" = "<!-- testing-policy:reference-start v=$version surface=$surface -->" ] &&
    [ "$(tail -n 1 <<<"$out")" = "<!-- testing-policy:reference-end -->" ]; then
    ok "$label"
  else
    fail "$label (exit $rc, wanted 0; first and last lines below)"
    echo "      $(head -n 1 <<<"$out")"
    echo "      $(tail -n 1 <<<"$out")"
  fi

  run "$surface"
  label="$surface: the plain render of the CLAUDE.md section does not carry the reference"
  if [ "$rc" = 0 ] &&
    ! grep -qF -- "testing-policy:reference-start" <<<"$out" &&
    ! grep -qF -- "testing-policy:reference-end" <<<"$out" &&
    [ "$(tail -n 1 <<<"$out")" = "<!-- testing-policy:end -->" ]; then
    ok "$label"
  else
    fail "$label (exit $rc, wanted 0; reference marker lines and last line below)"
    grep -nF -- "testing-policy:reference-" <<<"$out" | sed 's/^/      /'
    echo "      $(tail -n 1 <<<"$out")"
  fi
done

echo "# the verifier on an install's policy reference"
project="$tmp/installed"
policy_section_fixture "$project" native ""
policy_pieces_fixture "$project" unit e2e
reference="$project/.claude/testing-policy/policy.md"

rc=0
out="$(bash "$verify_policy" "$project" 2>&1)" || rc=$?
check_lines "a complete install holding the reference the template renders reads current, with the reference ok" 0 "$rc" \
  "policy=current" "policy_reference=ok"

sed -i "$(($(wc -l <"$reference") / 2))d" "$reference"
rc=0
out="$(bash "$verify_policy" "$project" 2>&1)" || rc=$?
check_lines "an install whose policy reference lost a line is reported drifted and fails, its CLAUDE.md section still current" 1 "$rc" \
  "policy=current" "policy_reference=drifted"

bash "$render_policy" unit --reference >"$reference"
rc=0
out="$(bash "$verify_policy" "$project" 2>&1)" || rc=$?
check_lines "a native install holding the reference rendered for the unit surface is reported drifted and fails" 1 "$rc" \
  "policy=current" "policy_reference=drifted"

rm -f "$reference"
rc=0
out="$(bash "$verify_policy" "$project" 2>&1)" || rc=$?
check_lines "an otherwise complete install without its policy reference is reported missing and fails" 1 "$rc" \
  "policy_reference=missing"

echo "# the verifier on a project whose git ignores the policy reference"
mkdir -p "$tmp/home"
export HOME="$tmp/home"
fresh ignoring
project="$tmp/ignoring"
policy_section_fixture "$project" native ""
policy_pieces_fixture "$project" unit e2e
echo ".claude/testing-policy/policy.md" >"$project/.gitignore"

rc=0
out="$(bash "$verify_policy" "$project" 2>&1)" || rc=$?
label="a project whose git ignores the policy reference, and nothing else of the install, has it named in the gitignored= line"
if [ "$(term gitignored)" = ".claude/testing-policy/policy.md" ]; then ok "$label"; else
  fail "$label (exit $rc)"
  dump_out
fi

echo
if [ "$fails" = 0 ]; then echo "policy-reference: all checks passed"; else
  echo "policy-reference: $fails failed"
  exit 1
fi
