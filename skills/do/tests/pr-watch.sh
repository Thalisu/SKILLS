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
# A recorded answer that opens with `fail:` is a call gh refuses: the rest goes to stderr, and gh exits 1.
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
if IFS= read -r first <"$answer" && [ "${first#fail:}" != "$first" ]; then
  echo "${first#fail:}" >&2
  exit 1
fi
jq -r "$expr" "$answer"
SH
chmod +x "$tmp/bin/gh"
export PATH="$tmp/bin:$PATH"

serve() { # $1 the pull request, $2 its merge state, $3.. the `pr checks` JSON of each call in turn, or fail:<gh's stderr> for a call gh refuses
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

# gh reports a pull request with no checks as a failure: exit 1, this line on stderr, nothing on stdout.
serve 42 CLEAN "fail:no checks reported on the 'feature' branch"
DO_PR_WATCH_REGISTER_SECONDS=0 run 42
check_lines "a clean pull request on a repository with no CI, once the registration grace has passed: the watch returns verdict=green with no checks counted, not a read failure" 0 "$rc" \
  "verdict=green" "checks=0"

serve 42 CLEAN "fail:no checks reported on the 'feature' branch"
DO_PR_WATCH_REGISTER_SECONDS=3600 run 42
since="$(term since)"
state="$(term state)"
handed=no
[[ "$since" =~ ^[0-9]+$ ]] && [ -n "$state" ] && handed=yes
out="${out%%$'\n'*}"
check_lines "no checks reported on a clean pull request inside the registration grace, when the time bound runs out: the watch returns verdict=pending on its first line, not green, for the step to call it again" 0 "$rc" \
  "verdict=pending"
expect "no checks reported inside the registration grace: the pending verdict carries a since= epoch and a state= token to hand back" [ "$handed" = yes ]
DO_PR_WATCH_REGISTER_SECONDS=0 run 42 "$since" "$state"
check_lines "no checks reported, called again with the since and state it handed back once the grace has passed: the watch returns verdict=green with no checks counted" 0 "$rc" \
  "verdict=green" "checks=0"

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

serve 42 DIRTY '[{"name":"build","bucket":"pass"},{"name":"test","bucket":"pending"}]'
echo '{"mergeStateStatus":"DIRTY","mergeable":"CONFLICTING","headRefName":"feature/login","baseRefName":"main"}' >"$GH_FAKE/view"
rc=0
# A conflicted pull request's CI may never start: the 5-second kill under the 60-second bound fails a
# watch that waits the pending check out before it reads the merge state.
out="$(DO_PR_WATCH_SECONDS=60 timeout 5 bash "$script" 42 2>/dev/null)" || rc=$?
same "a pull request that conflicts while a check is still pending: the watch returns verdict=conflict at once, without waiting the checks out" \
  "verdict=conflict"$'\n'"head=feature/login"$'\n'"base=main"
expect "a conflict found while a check is pending is a verdict printed: the watch exits 0" [ "$rc" = 0 ]

serve 42 BLOCKED '[{"name":"build","bucket":"pass"},{"name":"test","bucket":"pass"}]'
echo '{"mergeStateStatus":"BLOCKED","mergeable":"MERGEABLE","reviewDecision":"REVIEW_REQUIRED","headRefName":"feature/login","baseRefName":"main"}' >"$GH_FAKE/view"
run 42
same "every check passed and only a required review blocks the merge: the watch returns verdict=awaiting-approval, with its check count" \
  "verdict=awaiting-approval"$'\n'"checks=2"
expect "a pull request awaiting approval is a verdict printed: the watch exits 0" [ "$rc" = 0 ]

serve 42 BLOCKED "fail:no checks reported on the 'feature' branch"
echo '{"mergeStateStatus":"BLOCKED","mergeable":"MERGEABLE","reviewDecision":"REVIEW_REQUIRED","headRefName":"feature/login","baseRefName":"main"}' >"$GH_FAKE/view"
DO_PR_WATCH_REGISTER_SECONDS=3600 run 42
since="$(term since)"
state="$(term state)"
handed=no
[[ "$since" =~ ^[0-9]+$ ]] && [ -n "$state" ] && handed=yes
out="${out%%$'\n'*}"
check_lines "no check registered yet on a pull request awaiting a required review, inside the registration grace: the watch returns verdict=pending on its first line, not awaiting-approval, for no check proved green" 0 "$rc" \
  "verdict=pending"
expect "no check registered yet on a pull request awaiting a required review: the pending verdict carries a since= epoch and a state= token to hand back" [ "$handed" = yes ]

serve 42 BLOCKED "fail:no checks reported on the 'feature' branch"
echo '{"mergeStateStatus":"BLOCKED","mergeable":"MERGEABLE","reviewDecision":"REVIEW_REQUIRED","isDraft":true,"headRefName":"feature/login","baseRefName":"main"}' >"$GH_FAKE/view"
DO_PR_WATCH_REGISTER_SECONDS=3600 run 42
out="${out%%$'\n'*}"
check_lines "no check registered yet on a draft pull request, inside the registration grace: the watch returns verdict=pending on its first line, not draft, for no check proved green" 0 "$rc" \
  "verdict=pending"

serve 42 BLOCKED "fail:no checks reported on the 'feature' branch"
echo '{"mergeStateStatus":"BLOCKED","mergeable":"MERGEABLE","reviewDecision":"REVIEW_REQUIRED","headRefName":"feature/login","baseRefName":"main"}' >"$GH_FAKE/view"
DO_PR_WATCH_REGISTER_SECONDS=0 run 42
same "a pull request awaiting a required review on a repository with no CI, once the registration grace has passed: the watch returns verdict=awaiting-approval with no checks counted, not pending" \
  "verdict=awaiting-approval"$'\n'"checks=0"
expect "a pull request with no CI awaiting a required review past the grace is a verdict printed: the watch exits 0" [ "$rc" = 0 ]

serve 42 BLOCKED '[{"name":"build","bucket":"pass"},{"name":"test","bucket":"pass"}]'
echo '{"mergeStateStatus":"BLOCKED","mergeable":"MERGEABLE","reviewDecision":"REVIEW_REQUIRED","isDraft":true,"headRefName":"feature/login","baseRefName":"main"}' >"$GH_FAKE/view"
run 42
same "a draft pull request with every check passed and a required review pending: the watch returns verdict=draft with its check count, not verdict=awaiting-approval" \
  "verdict=draft"$'\n'"checks=2"
expect "a draft pull request blocked on a required review is a verdict printed: the watch exits 0" [ "$rc" = 0 ]

serve 42 CLEAN '[{"name":"build","bucket":"pass"},{"name":"test","bucket":"pass"}]'
echo '{"mergeStateStatus":"CLEAN","mergeable":"MERGEABLE","isDraft":true,"headRefName":"feature/login","baseRefName":"main"}' >"$GH_FAKE/view"
run 42
same "a draft pull request with every check passed and a clean merge state: the watch returns verdict=draft with its check count, not verdict=green" \
  "verdict=draft"$'\n'"checks=2"
expect "a clean draft pull request is a verdict printed: the watch exits 0" [ "$rc" = 0 ]

for review in APPROVED CHANGES_REQUESTED; do
  serve 42 BLOCKED '[{"name":"build","bucket":"pass"},{"name":"test","bucket":"pass"}]'
  printf '{"mergeStateStatus":"BLOCKED","mergeable":"MERGEABLE","reviewDecision":"%s","headRefName":"feature/login","baseRefName":"main"}\n' "$review" >"$GH_FAKE/view"
  run 42
  same "a pull request blocked with review $review, not a pending required review: the watch prints no verdict, awaiting-approval or any other" ""
  expect "a pull request blocked with review $review is a settled state no verdict covers: the watch exits 3" [ "$rc" = 3 ]
done

serve 42 BLOCKED '[{"name":"test (ubuntu-latest, 3.11)","bucket":"fail","link":"https://github.com/o/r/actions/runs/7/job/99"},{"name":"lint","bucket":"pass","link":"https://github.com/o/r/actions/runs/7/job/98"},{"name":"build","bucket":"fail","link":"https://github.com/o/r/actions/runs/7/job/97"}]'
echo '{"mergeStateStatus":"BLOCKED","mergeable":"MERGEABLE","reviewDecision":"REVIEW_REQUIRED","headRefName":"feature/login","headRefOid":"3f2a9c1d8e7b6a5f4e3d2c1b0a9f8e7d6c5b4a39","baseRefName":"main"}' >"$GH_FAKE/view"
run 42
same "no check pending and some failed: the watch returns verdict=red, the head branch and commit, and each failed check's link and name in the order gh lists them" \
  "verdict=red"$'\n'"head=feature/login"$'\n'"sha=3f2a9c1d8e7b6a5f4e3d2c1b0a9f8e7d6c5b4a39"$'\n'"red=https://github.com/o/r/actions/runs/7/job/99 test (ubuntu-latest, 3.11)"$'\n'"red=https://github.com/o/r/actions/runs/7/job/97 build"
expect "a pull request with failed checks is a verdict printed: the watch exits 0" [ "$rc" = 0 ]

serve 42 DIRTY '[{"name":"build","bucket":"fail","link":"https://github.com/o/r/actions/runs/7/job/97"},{"name":"lint","bucket":"pass","link":"https://github.com/o/r/actions/runs/7/job/98"}]'
echo '{"mergeStateStatus":"DIRTY","mergeable":"CONFLICTING","headRefName":"feature/login","headRefOid":"3f2a9c1d8e7b6a5f4e3d2c1b0a9f8e7d6c5b4a39","baseRefName":"main"}' >"$GH_FAKE/view"
run 42
same "a pull request that conflicts with its base while a check failed: the watch returns verdict=conflict with its head and base, not verdict=red" \
  "verdict=conflict"$'\n'"head=feature/login"$'\n'"base=main"
expect "a conflict found over a failed check is a verdict printed: the watch exits 0" [ "$rc" = 0 ]

serve 42 UNSTABLE '[{"name":"build","bucket":"cancel","link":"https://github.com/o/r/actions/runs/7/job/97"},{"name":"lint","bucket":"pass","link":"https://github.com/o/r/actions/runs/7/job/98"}]'
echo '{"mergeStateStatus":"UNSTABLE","mergeable":"MERGEABLE","headRefName":"feature/login","headRefOid":"3f2a9c1d8e7b6a5f4e3d2c1b0a9f8e7d6c5b4a39","baseRefName":"main"}' >"$GH_FAKE/view"
run 42
same "a cancelled check with none failed and none pending: the watch prints no verdict, red or any other" ""
expect "a cancelled check with none failed and none pending is a settled state no verdict covers: the watch exits 3" [ "$rc" = 3 ]

serve 42 CLEAN '[{"name":"lint","bucket":"pass"},{"name":"build (ubuntu-latest, 3.11)","bucket":"pending"},{"name":"deploy","bucket":"pending"}]'
run 42
state="$(sed -n 's/^state=//p' <<<"$out")"
# A <since> of 1 is decades ago: the checks served unchanged since then have sat for far more than an hour.
run 42 1 "$state"
same "checks unchanged for an hour with some still pending: the watch returns verdict=stalled, naming each pending check in the order gh lists them" \
  "verdict=stalled"$'\n'"pending=build (ubuntu-latest, 3.11)"$'\n'"pending=deploy"
expect "a stalled pull request is a verdict printed: the watch exits 0" [ "$rc" = 0 ]

serve 42 CLEAN '[{"name":"build","bucket":"pending"},{"name":"deploy","bucket":"pending"}]'
run 42
handed="$(sed -n 's/^state=//p' <<<"$out")"
serve 42 CLEAN '[{"name":"build","bucket":"pass"},{"name":"deploy","bucket":"pending"}]'
before="$(date +%s)"
# A <since> of 1 is decades ago: only a window restarted on the moved check keeps this call short of stalled.
run 42 1 "$handed"
since="$(sed -n 's/^since=//p' <<<"$out")"
state="$(sed -n 's/^state=//p' <<<"$out")"
restarted=no
[[ "$since" =~ ^[0-9]+$ ]] && ((since >= before && since <= before + 60)) && restarted=yes
moved=no
[ -n "$handed" ] && [ -n "$state" ] && [ "$state" != "$handed" ] && moved=yes
expect "a check that moved since the window began: the watch returns verdict=pending on its first line, not stalled" [ "${out%%$'\n'*}" = verdict=pending ]
expect "a check that moved since the window began: the watch exits 0" [ "$rc" = 0 ]
expect "a check that moved since the window began: the watch restarts the window at the current time, not at the <since> it was handed" [ "$restarted" = yes ]
expect "a check that moved since the window began: the watch hands back a state other than the one it was handed" [ "$moved" = yes ]

exit "$((fails > 0))"
