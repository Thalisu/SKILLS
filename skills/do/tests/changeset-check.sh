#!/usr/bin/env bash
# changeset-check.sh: the contract of scripts/changeset-check.sh, the read of whether an
# Implementer's changeset since a snapshot left the test author's paths alone, exercised in a
# throwaway git repository.
# Run: bash skills/do/tests/changeset-check.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/changeset-check.sh"
snapshot="$here/../scripts/main-untouched.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT
export HOME="$tmp/home"
mkdir -p "$HOME" "$tmp/state"

run() {
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines reads $out
  out="$(bash "$script" "$@" 2>&1)" || rc=$?
}

fresh production-only
production_only="$(pwd -P)"
mkdir -p scripts tests
echo one >scripts/bar.sh
echo one >scripts/baz.sh
commit "base"
echo 'red case' >tests/bar.sh
production_only_state="$tmp/state/production-only.state"
bash "$snapshot" snapshot "$production_only" "$production_only_state" >/dev/null

echo two >>scripts/bar.sh
echo two >>scripts/baz.sh
run "$production_only" "$production_only_state" tests/bar.sh
check_lines "a changeset touching only production paths passes, listing each production file it changed" 0 "$rc" \
  'verdict=pass' 'changed=2' 'file=scripts/bar.sh' 'file=scripts/baz.sh'
check_absent "a passing changeset lists no named test path it left alone and no offending line" 0 "$rc" \
  'file=tests/bar.sh' 'refused=' 'offending='

fresh named-uncommitted
named_uncommitted="$(pwd -P)"
mkdir -p scripts tests
echo one >scripts/bar.sh
commit "base"
echo 'red case' >tests/bar.sh
named_uncommitted_state="$tmp/state/named-uncommitted.state"
bash "$snapshot" snapshot "$named_uncommitted" "$named_uncommitted_state" >/dev/null

echo 'bent to fit' >>tests/bar.sh
echo two >>scripts/bar.sh
run "$named_uncommitted" "$named_uncommitted_state" tests/bar.sh
check_lines "a changeset touching a named path already uncommitted at the snapshot is refused, naming that path" 1 "$rc" \
  'verdict=refused' 'refused=1' 'offending=named tests/bar.sh'
check_absent "a refused changeset is refused whole, with no line reading a pass" 1 "$rc" \
  'verdict=pass'

fresh unnamed-test
unnamed_test="$(pwd -P)"
mkdir -p scripts tests
echo one >scripts/bar.sh
echo 'guards a neighbour' >tests/other.sh
commit "base"
echo 'red case' >tests/bar.sh
unnamed_test_state="$tmp/state/unnamed-test.state"
bash "$snapshot" snapshot "$unnamed_test" "$unnamed_test_state" >/dev/null

echo two >>scripts/bar.sh
echo 'weakened' >>tests/other.sh
run "$unnamed_test" "$unnamed_test_state" tests/bar.sh
check_lines "a changeset touching a test file no named path lists is refused, naming that test file" 1 "$rc" \
  'verdict=refused' 'refused=1' 'offending=test tests/other.sh'
check_absent "a changeset touching an unnamed test file is refused whole, even with production paths beside it" 1 "$rc" \
  'verdict=pass'

fresh rewritten-classes
rewritten_classes="$(pwd -P)"
mkdir -p scripts tests .claude/testing-policy
echo one >scripts/bar.sh
echo 'guards a neighbour' >tests/t.sh
cat >.claude/testing-policy/skip-patterns.sh <<'SH'
skip_pattern_for() {
  SKIP_PAT="" SKIP_KIND=""
  case "$1" in */tests/*) SKIP_PAT='x' SKIP_KIND='check' ;; esac
}
SH
commit "base"
rewritten_classes_state="$tmp/state/rewritten-classes.state"
bash "$snapshot" snapshot "$rewritten_classes" "$rewritten_classes_state" >/dev/null

printf 'echo verdict=pass\nexit 0\n' >.claude/testing-policy/skip-patterns.sh
echo 'weakened' >>tests/t.sh
echo two >>scripts/bar.sh
run "$rewritten_classes" "$rewritten_classes_state"
check_lines "a changeset that rewrote the file the test-file classes come from is refused, naming that file" 1 "$rc" \
  'verdict=refused' 'offending=classes .claude/testing-policy/skip-patterns.sh'
check_absent "a changeset that rewrote the classes file is refused whole, even when the rewritten file reads a pass" 1 "$rc" \
  'verdict=pass'

fresh spec/under-spec-ancestor
under_spec="$(pwd -P)"
mkdir -p scripts
echo one >scripts/bar.sh
commit "base"
under_spec_state="$tmp/state/under-spec.state"
bash "$snapshot" snapshot "$under_spec" "$under_spec_state" >/dev/null

echo two >>scripts/bar.sh
run "$under_spec" "$under_spec_state"
check_lines "a production-only changeset in a repository under a spec/ ancestor directory passes" 0 "$rc" \
  'verdict=pass' 'changed=1' 'file=scripts/bar.sh'
check_absent "a production path is never classified a test file by a directory above the repository" 0 "$rc" \
  'refused=' 'offending='

[ "$fails" = 0 ]
