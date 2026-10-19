#!/usr/bin/env bash
# gather.sh: the contract of scripts/gather.sh, the pending debt of one feature folder, named by
# its slug the way /debt is typed. Run: bash skills/debt/tests/gather.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/gather.sh"
resolve="$here/../../../.agents/scripts/resolve-feature-folder.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

run() {
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines reads $out
  out="$(cd "$tmp" && bash "$script" "$@" 2>&1)" || rc=$?
}

mkdir -p "$tmp/.scratch/20261019-pending-debt-review/issues"
printf '# Spec: pending debt review\n' >"$tmp/.scratch/20261019-pending-debt-review/spec.md"

want="$(cd "$tmp" && bash "$resolve" pending-debt-review | sed -n 's/^folder=//p')"
if [ -z "$want" ] || [ "$want" = none ]; then
  echo "FAIL  fixture: the resolver named no folder for pending-debt-review"
  exit 1
fi

# The exit code of a feature with or without debt belongs to later cases, so these accept any.
run pending-debt-review
check_lines "a bare slug gathers the folder the resolver names" "$rc" "$rc" "folder=$want"

run 20261019-pending-debt-review
check_lines "the dated folder name gathers the same folder as the bare slug" "$rc" "$rc" "folder=$want"

entries='%p %y %s %T@\n'
before="$(snapshot "$tmp" "$entries")"
run Pending-Debt-Typo
check_lines "a slug that names no folder says so, quoting the slug as typed, and exits 3" 3 "$rc" \
  "line=no feature folder for Pending-Debt-Typo; nothing written"
expect "a slug that names no folder writes nothing in the directory it ran from" \
  test "$before" = "$(snapshot "$tmp" "$entries")"

exit "$fails"
