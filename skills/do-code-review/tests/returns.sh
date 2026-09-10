#!/usr/bin/env bash
# returns.sh: the contract of scripts/returns.sh, the wait the orchestrator runs on its reviewers'
# return files, so a retry forks only the reviewer whose file never landed.
# Run: bash skills/do-code-review/tests/returns.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/returns.sh"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

run() {
  rc=0
  out="$(bash "$script" "$@" 2>&1)" || rc=$?
}

technical="$tmp/technical.md"
security="$tmp/security.md"

printf 'findings\n' >"$technical"
printf 'findings\n' >"$security"
run 1 "$technical" "$security"
check_lines "every return landed: each named returned, exit 0" 0 "$rc" "returned=$technical" "returned=$security"

rm "$security"
run 1 "$technical" "$security"
check_lines "a return that never landed is named missing beside the one that did" 1 "$rc" \
  "returned=$technical" "missing=$security"
expect "the lines come in the order the files were given" test "$(sed -n 1p <<<"$out")" = "returned=$technical"

: >"$security"
run 1 "$security"
check_lines "an empty return file is missing" 1 "$rc" "missing=$security"

rm "$security"
(
  sleep 1
  printf 'late\n' >"$security"
) &
start="$(date +%s)"
run 10 "$security"
took=$(($(date +%s) - start))
wait
check_lines "a return that lands inside the window ends the wait" 0 "$rc" "returned=$security"
expect "the wait ends when the file lands, not at its window" test "$took" -lt 5

rm "$security"
start="$(date +%s)"
run 2 "$security"
took=$(($(date +%s) - start))
expect "the wait closes at its window" test "$took" -ge 2 -a "$took" -le 4

run
check_lines "no argument is a usage error" 2 "$rc"
run abc "$technical"
check_lines "a window that is not a number is a usage error" 2 "$rc"
run 5
check_lines "a window with no file is a usage error" 2 "$rc"

echo
if [ "$fails" = 0 ]; then echo "returns: all checks passed"; else
  echo "returns: $fails failed"
  exit 1
fi
