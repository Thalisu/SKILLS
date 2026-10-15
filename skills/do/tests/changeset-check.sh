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

[ "$fails" = 0 ]
