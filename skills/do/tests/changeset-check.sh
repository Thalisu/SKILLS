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

snapshot_digest() { # $1 tree, $2 state file: takes the snapshot, the digest= value it printed on stdout
  local out
  # shellcheck disable=SC2034  # lib.sh's term reads $out
  out="$(bash "$snapshot" snapshot "$1" "$2")"
  term digest
}

fresh production-only
production_only="$(pwd -P)"
mkdir -p scripts tests
echo one >scripts/bar.sh
echo one >scripts/baz.sh
commit "base"
echo 'red case' >tests/bar.sh
production_only_state="$tmp/state/production-only.state"
production_only_digest="$(snapshot_digest "$production_only" "$production_only_state")"

echo two >>scripts/bar.sh
echo two >>scripts/baz.sh
run "$production_only" "$production_only_state" "$production_only_digest" tests/bar.sh
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
named_uncommitted_digest="$(snapshot_digest "$named_uncommitted" "$named_uncommitted_state")"

echo 'bent to fit' >>tests/bar.sh
echo two >>scripts/bar.sh
run "$named_uncommitted" "$named_uncommitted_state" "$named_uncommitted_digest" tests/bar.sh
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
unnamed_test_digest="$(snapshot_digest "$unnamed_test" "$unnamed_test_state")"

echo two >>scripts/bar.sh
echo 'weakened' >>tests/other.sh
run "$unnamed_test" "$unnamed_test_state" "$unnamed_test_digest" tests/bar.sh
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
rewritten_classes_digest="$(snapshot_digest "$rewritten_classes" "$rewritten_classes_state")"

printf 'echo verdict=pass\nexit 0\n' >.claude/testing-policy/skip-patterns.sh
echo 'weakened' >>tests/t.sh
echo two >>scripts/bar.sh
run "$rewritten_classes" "$rewritten_classes_state" "$rewritten_classes_digest"
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
under_spec_digest="$(snapshot_digest "$under_spec" "$under_spec_state")"

echo two >>scripts/bar.sh
run "$under_spec" "$under_spec_state" "$under_spec_digest"
check_lines "a production-only changeset in a repository under a spec/ ancestor directory passes" 0 "$rc" \
  'verdict=pass' 'changed=1' 'file=scripts/bar.sh'
check_absent "a production path is never classified a test file by a directory above the repository" 0 "$rc" \
  'refused=' 'offending='

fresh git-config-and-hook
git_config_and_hook="$(pwd -P)"
mkdir -p scripts
echo one >scripts/bar.sh
commit "base"
git_common="$(g rev-parse --path-format=absolute --git-common-dir)"
git_config_and_hook_state="$tmp/state/git-config-and-hook.state"
git_config_and_hook_digest="$(snapshot_digest "$git_config_and_hook" "$git_config_and_hook_state")"

g config core.hooksPath "$git_config_and_hook/scripts/hooks"
printf '#!/bin/sh\nexit 0\n' >"$git_common/hooks/pre-commit"
echo two >>scripts/bar.sh
run "$git_config_and_hook" "$git_config_and_hook_state" "$git_config_and_hook_digest"
check_lines "a changeset that changed the git config or wrote a git hook is refused, naming each by its absolute path" 1 "$rc" \
  'verdict=refused' "offending=git $git_common/config" "offending=git $git_common/hooks/pre-commit" \
  'file=scripts/bar.sh'
check_absent "a changeset that changed the git config or a hook is refused whole, even with a production file beside it" 1 "$rc" \
  'verdict=pass'

fresh policy-snapshot-and-fixture
policy_snapshot="$(pwd -P)"
mkdir -p src/__snapshots__ tests/fixtures .claude/testing-policy
cp "$here/../../../.claude/testing-policy/skip-patterns.sh" .claude/testing-policy/skip-patterns.sh
echo 'exports[`a 1`] = `one`;' >src/__snapshots__/a.test.ts.snap
echo '{"total": 1}' >tests/fixtures/data.json
commit "base"
policy_snapshot_state="$tmp/state/policy-snapshot.state"
policy_snapshot_digest="$(snapshot_digest "$policy_snapshot" "$policy_snapshot_state")"

echo 'exports[`a 1`] = `two`;' >src/__snapshots__/a.test.ts.snap
echo '{"total": 2}' >tests/fixtures/data.json
run "$policy_snapshot" "$policy_snapshot_state" "$policy_snapshot_digest"
check_lines "with the Testing Policy installed, a changeset rewriting a Jest snapshot and a fixture is refused, naming each as test material" 1 "$rc" \
  'verdict=refused' 'offending=test src/__snapshots__/a.test.ts.snap' 'offending=test tests/fixtures/data.json'
check_absent "a rewritten snapshot or fixture never passes as production under the policy's narrower classes" 1 "$rc" \
  'verdict=pass'

fresh resnapshotted-baseline
resnapshotted="$(pwd -P)"
mkdir -p scripts tests
echo one >scripts/bar.sh
commit "base"
echo 'red case' >tests/bar.sh
resnapshotted_state="$tmp/state/resnapshotted.state"
resnapshotted_digest="$(snapshot_digest "$resnapshotted" "$resnapshotted_state")"

echo 'bent to fit' >>tests/bar.sh
echo two >>scripts/bar.sh
bash "$snapshot" snapshot "$resnapshotted" "$resnapshotted_state" >/dev/null
run "$resnapshotted" "$resnapshotted_state" "$resnapshotted_digest" tests/bar.sh
check_absent "a baseline re-snapshotted after the author's test was bent no longer matches its digest, and reads no verdict" 2 "$rc" \
  'verdict='

[ "$fails" = 0 ]
