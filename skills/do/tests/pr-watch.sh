#!/usr/bin/env bash
# pr-watch.sh: the contract of scripts/pr-watch.sh, the verdict the pr Playbook's step 4 reads to tell
# the developer whether the pull request is ready to merge.
# Run: bash skills/do/tests/pr-watch.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/pr-watch.sh"
fails=0

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home" GH_FAKE="$tmp/gh" DO_PR_WATCH_SECONDS=1 DO_PR_WATCH_INTERVAL=0
mkdir -p "$HOME" "$GH_FAKE" "$tmp/bin"

# The fake gh answers `gh pr checks <pr> --json ... --jq <expr>` with the recorded answers in
# $GH_FAKE/checks.1, checks.2, ... one per call, the last one repeating, and
# `gh pr view <pr> --json ... --jq <expr>` with $GH_FAKE/view, applying <expr> with the system jq.
# A pull request other than the one in $GH_FAKE/pr is one gh cannot open.
cat >"$tmp/bin/gh" <<'SH'
#!/usr/bin/env bash
[ "${1:-}" = pr ] || { echo "fake gh: unexpected command: $*" >&2; exit 1; }
sub="${2:-}" pr="${3:-}"
[ "$pr" = "$(cat "$GH_FAKE/pr")" ] || { echo "no pull requests found for branch \"$pr\"" >&2; exit 1; }
expr=.
shift 3
while [ $# -gt 0 ]; do
  case "$1" in --jq) expr="$2"; shift ;; esac
  shift
done
case "$sub" in
  checks)
    n=$(($(cat "$GH_FAKE/checks.calls" 2>/dev/null || echo 0) + 1))
    echo "$n" >"$GH_FAKE/checks.calls"
    answer="$GH_FAKE/checks.$n"
    while [ ! -f "$answer" ] && [ "$n" -gt 1 ]; do n=$((n - 1)); answer="$GH_FAKE/checks.$n"; done
    ;;
  view) answer="$GH_FAKE/view" ;;
  *) echo "fake gh: unexpected command: pr $sub" >&2; exit 1 ;;
esac
jq -r "$expr" "$answer"
SH
chmod +x "$tmp/bin/gh"
export PATH="$tmp/bin:$PATH"

serve() { # $1 the pull request, $2 its merge state, $3.. the `pr checks` JSON of each call in turn
  rm -f "$GH_FAKE"/checks.* "$GH_FAKE/view"
  echo "$1" >"$GH_FAKE/pr"
  printf '{"mergeStateStatus":"%s"}\n' "$2" >"$GH_FAKE/view"
  local i=0
  shift 2
  for answer in "$@"; do
    i=$((i + 1))
    echo "$answer" >"$GH_FAKE/checks.$i"
  done
}
run() { # $1.. the script's arguments: its stdout in $out, its exit in $rc
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines reads $out
  out="$(bash "$script" "$@" 2>/dev/null)" || rc=$?
}

serve 42 CLEAN '[{"name":"build","bucket":"pass"},{"name":"test","bucket":"pass"}]'
run 42
check_lines "every check passed and the merge state is clean: the pull request is green, with its check count" 0 "$rc" \
  "verdict=green" "checks=2"

serve 42 CLEAN '[{"name":"build","bucket":"pass"},{"name":"test","bucket":"pending"}]'
run 42
out="${out%%$'\n'*}"
check_lines "a check still pending when the time bound runs out: the watch returns verdict=pending on its first line, for the step to call it again" 0 "$rc" \
  "verdict=pending"

serve 42 CLEAN '[{"name":"build","bucket":"pass"},{"name":"test","bucket":"pending"}]' \
  '[{"name":"build","bucket":"pass"},{"name":"test","bucket":"pass"}]'
rc=0
# The 5-second kill sits far under the 60-second bound: a watch that waits its bound out is killed
# before it prints, and fails the case instead of hanging it.
out="$(DO_PR_WATCH_SECONDS=60 timeout 5 bash "$script" 42 2>/dev/null)" || rc=$?
check_lines "a pending check that settles green inside the bound: the watch returns verdict=green with its check count at once, without waiting the bound out" 0 "$rc" \
  "verdict=green" "checks=2"

serve 42 DIRTY '[{"name":"build","bucket":"pass"},{"name":"test","bucket":"pass"}]'
echo '{"mergeStateStatus":"DIRTY","mergeable":"CONFLICTING","headRefName":"feature/login","baseRefName":"main"}' >"$GH_FAKE/view"
run 42
same "a pull request that conflicts with its base: the watch returns verdict=conflict, naming its head and base branches" \
  "verdict=conflict"$'\n'"head=feature/login"$'\n'"base=main"
expect "a conflicted pull request is a verdict printed: the watch exits 0" [ "$rc" = 0 ]

exit "$((fails > 0))"
