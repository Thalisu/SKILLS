#!/usr/bin/env bash
# pr-rerun.sh: the contract of scripts/pr-rerun.sh, the rerun of a red check's workflow runs the pr
# Playbook asks for when its fixer could not reproduce the failure.
# Run: bash skills/do/tests/pr-rerun.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/pr-rerun.sh"
fails=0

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home" GH_FAKE="$tmp/gh" DO_PR_RERUN_SECONDS=10
mkdir -p "$HOME" "$GH_FAKE" "$tmp/bin"

# The fake gh logs every command line it receives to $GH_FAKE/calls. It answers
# `gh pr view <pr> --json headRefOid --jq <expr>` with the head in $GH_FAKE/head, and
# `gh run view <id> --repo <repo> --json attempt --jq <expr>` with the attempt in $GH_FAKE/attempt.<id>,
# applying <expr> with the system jq. `gh run rerun <id> --repo <repo> --failed` starts a new attempt,
# which the next views still hide behind the old one as many times as $GH_FAKE/lag.<id> says.
# A pull request other than $GH_FAKE/pr, or a run outside $GH_FAKE/repo, is one gh cannot find.
cat >"$tmp/bin/gh" <<'SH'
#!/usr/bin/env bash
echo "$*" >>"$GH_FAKE/calls"
[ $# -ge 3 ] || { echo "fake gh: unexpected command: $*" >&2; exit 1; }
cmd="$1 $2" id="$3"
shift 3
expr=. repo=
while [ $# -gt 0 ]; do
  case "$1" in --jq) expr="$2"; shift ;; --repo) repo="$2"; shift ;; esac
  shift
done
case "$cmd" in
  "pr view")
    [ "$id" = "$(cat "$GH_FAKE/pr")" ] || { echo "no pull requests found for branch \"$id\"" >&2; exit 1; }
    printf '{"headRefOid":"%s"}\n' "$(cat "$GH_FAKE/head")" | jq -r "$expr"
    ;;
  "run view" | "run rerun")
    [ "$repo" = "$(cat "$GH_FAKE/repo")" ] && [ -f "$GH_FAKE/attempt.$id" ] ||
      { echo "could not find any workflow run with ID $id" >&2; exit 1; }
    if [ "$cmd" = "run rerun" ]; then
      echo $(($(cat "$GH_FAKE/attempt.$id") + 1)) >"$GH_FAKE/next.$id"
      exit 0
    fi
    if [ -f "$GH_FAKE/next.$id" ]; then
      lag="$(cat "$GH_FAKE/lag.$id" 2>/dev/null || echo 0)"
      if [ "$lag" -gt 0 ]; then echo $((lag - 1)) >"$GH_FAKE/lag.$id"; else mv "$GH_FAKE/next.$id" "$GH_FAKE/attempt.$id"; fi
    fi
    printf '{"attempt":%s}\n' "$(cat "$GH_FAKE/attempt.$id")" | jq -r "$expr"
    ;;
  *) echo "fake gh: unexpected command: $cmd" >&2; exit 1 ;;
esac
SH
chmod +x "$tmp/bin/gh"
export PATH="$tmp/bin:$PATH"

sha=3f2a9c1d8e7b6a5f4e3d2c1b0a9f8e7d6c5b4a39
echo 42 >"$GH_FAKE/pr"
echo "$sha" >"$GH_FAKE/head"
echo github.com/o/r >"$GH_FAKE/repo"
echo 1 >"$GH_FAKE/attempt.7"
echo 2 >"$GH_FAKE/attempt.9"
echo 2 >"$GH_FAKE/lag.9"

rc=0
# The 30-second kill sits far over the 10-second bound: a script that never sees the new attempt is
# killed and fails the case instead of hanging it.
out="$(timeout 30 bash "$script" 42 "$sha" github.com/o/r 7 9 7 2>/dev/null)" || rc=$?
out="$(grep '^rerun=' <<<"$out")"
same "two runs reran, one named twice and one whose new attempt shows only after two more views: one rerun= line per run in first-seen order, each with the new attempt gh reads, never the old one" \
  "rerun=7 2"$'\n'"rerun=9 3"
expect "the runs reran with their new attempts seen: the script exits 0" [ "$rc" = 0 ]

out="$(grep '^run rerun ' "$GH_FAKE/calls" 2>/dev/null)"
same "a run named twice on the command line: gh reruns the failed jobs of each run once, in first-seen order, and never a run twice" \
  "run rerun 7 --repo github.com/o/r --failed"$'\n'"run rerun 9 --repo github.com/o/r --failed"

moved=9c8b7a6f5e4d3c2b1a0f9e8d7c6b5a4f3e2d1c0b
rm -f "$GH_FAKE/calls"
echo "$moved" >"$GH_FAKE/head"
rc=0
out="$(timeout 30 bash "$script" 42 "$sha" github.com/o/r 7 9 2>/dev/null)" || rc=$?
check_lines "the head moved past the watched sha: the script prints moved= with the head gh reads and exits 0" \
  0 "$rc" "moved=$moved"
absent "the head moved past the watched sha: no rerun= line on stdout" "rerun="
out="$(grep '^run rerun ' "$GH_FAKE/calls" 2>/dev/null)"
same "the head moved past the watched sha: gh reruns no run at all" ""

exit "$((fails > 0))"
