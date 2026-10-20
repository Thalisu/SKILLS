#!/usr/bin/env bash
# pr-log.sh: the contract of scripts/pr-log.sh, the excerpt of a red check's failed steps the pr
# Playbook's fixer fork starts from.
# Run: bash skills/do/tests/pr-log.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/pr-log.sh"
fails=0

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home" GH_FAKE="$tmp/gh"
mkdir -p "$HOME" "$GH_FAKE" "$tmp/bin"

# The fake gh logs every command line it receives to $GH_FAKE/calls. It answers
# `gh repo view --json url --jq .url` with the pull request's repository in $GH_FAKE/repo_url, or,
# while $GH_FAKE/repo_fail exists, prints that file's line on stderr instead. It answers
# `gh run view --job 99 --repo <repo> --log-failed` with the recorded log in $GH_FAKE/log for the
# pull request's repository github.com/o/r and for the two foreign ones the refusal cases link to,
# which hold a log of their own too, and for job 999 of github.com/o/r, a job of another run. While
# $GH_FAKE/fail exists it cannot read the log, and prints that file's line on stderr instead. It
# answers `gh run view <run> --repo github.com/o/r --json headSha,jobs --jq '.headSha,
# (.jobs[].databaseId)'` for any run with the head sha in $GH_FAKE/head, then the job ids in
# $GH_FAKE/jobs, one per line, or, while $GH_FAKE/run_fail exists, prints that file's line on stderr
# instead. It refuses any other command line.
cat >"$tmp/bin/gh" <<'SH'
#!/usr/bin/env bash
echo "$*" >>"$GH_FAKE/calls"
if [ "$*" = "repo view --json url --jq .url" ]; then
  [ -f "$GH_FAKE/repo_fail" ] && { cat "$GH_FAKE/repo_fail" >&2; exit 1; }
  cat "$GH_FAKE/repo_url"
  exit 0
fi
case "$*" in
  "run view "[0-9]*" --repo github.com/o/r --json headSha,jobs --jq .headSha, (.jobs[].databaseId)")
    [ -f "$GH_FAKE/run_fail" ] && { cat "$GH_FAKE/run_fail" >&2; exit 1; }
    cat "$GH_FAKE/head" "$GH_FAKE/jobs"
    exit 0
    ;;
esac
case "$*" in
  "run view --job 99 --repo github.com/o/r --log-failed" | \
    "run view --job 999 --repo github.com/o/r --log-failed" | \
    "run view --job 99 --repo github.com/someone-else/deploy-repo --log-failed" | \
    "run view --job 99 --repo evil.example/o/r --log-failed") ;;
  *) echo "fake gh: unexpected command: $*" >&2; exit 1 ;;
esac
[ -f "$GH_FAKE/fail" ] && { cat "$GH_FAKE/fail" >&2; exit 1; }
cat "$GH_FAKE/log"
SH
chmod +x "$tmp/bin/gh"
echo "https://github.com/o/r" >"$GH_FAKE/repo_url"
echo 99 >"$GH_FAKE/jobs"
export PATH="$tmp/bin:$PATH"

run() { # $1.. the script's arguments: its stdout in $out, its exit in $rc
  # The run the link names is a run of the tree's HEAD here; a case that wants another head calls
  # the script through refuses, which leaves $GH_FAKE/head as the case wrote it.
  local head
  head="$(git -C "${2:-/nonexistent}" rev-parse HEAD 2>/dev/null)" && echo "$head" >"$GH_FAKE/head"
  rc=0
  # shellcheck disable=SC2034  # lib.sh's same reads $out
  out="$(bash "$script" "$@")" || rc=$?
}

fresh tree
echo "# fixture" >README.md
commit "the one tracked file"
cd "$tmp" || exit 1

esc=$'\e'
job="test (ubuntu-latest, 3.11)"
want_tail=""
{
  for i in $(seq 1 30); do
    text="type check line $i" plain="type check line $i"
    if ((i % 10 == 0)); then
      text="${esc}[33mwarn${esc}[0m type check line $i" plain="warn type check line $i"
    fi
    printf '%s\tType check\t2026-10-14T12:00:%02d.1234567Z %s\n' "$job" "$((i % 60))" "$text"
    ((i > 10)) && want_tail+="excerpt=$plain"$'\n'
  done
  for i in $(seq 1 178); do
    printf '%s\tRun tests\t2026-10-14T12:01:%02d.1234567Z test line %s\n' "$job" "$((i % 60))" "$i"
    want_tail+="excerpt=test line $i"$'\n'
  done
  printf '%s\tRun tests\t2026-10-14T12:02:00.1234567Z %s\n' "$job" "${esc}[31mFAIL${esc}[0m src/a.test.ts"
  printf '%s\tRun tests\t2026-10-14T12:02:01.1234567Z %s\n' "$job" "Tests: ${esc}[1;31m1 failed${esc}[0m, 177 passed"
} >"$GH_FAKE/log"
want_tail+="excerpt=FAIL src/a.test.ts"$'\n'"excerpt=Tests: 1 failed, 177 passed"

run "https://github.com/o/r/actions/runs/7/job/99" "$tmp/tree"
same "a red check's log of 210 lines over two failed steps: the excerpt names each failed step once in log order, the 10 lines dropped, then the last 200 lines without the job and step columns, the timestamp or ANSI escapes" \
  "step=Type check"$'\n'"step=Run tests"$'\n'"dropped=10"$'\n'"$want_tail"$'\n'"repo=github.com/o/r"$'\n'"run=7"
expect "a red check's log cut to its excerpt: the script exits 0" [ "$rc" = 0 ]

fresh named
mkdir -p src/app tests
echo "def add(a, b): return a + b" >src/app/main.py
echo "def test_add(): pass" >tests/test_main.py
echo "# fixture" >README.md
commit "a tree with files in subfolders"
cd "$tmp" || exit 1

{
  printf '%s\tRun tests\t2026-10-14T12:03:00.1234567Z %s\n' "$job" "ERROR tests/test_main.py:8 test_add failed"
  printf '%s\tRun tests\t2026-10-14T12:03:01.1234567Z %s\n' "$job" "raised at ${esc}[36m/home/runner/work/r/r/src/app/main.py:12:5${esc}[0m in add"
  printf '%s\tRun tests\t2026-10-14T12:03:02.1234567Z %s\n' "$job" "called from /usr/lib/python3.11/unittest/case.py:57 in run"
  printf '%s\tRun tests\t2026-10-14T12:03:03.1234567Z %s\n' "$job" "loaded node_modules/x/index.js:3 first"
  printf '%s\tRun tests\t2026-10-14T12:03:04.1234567Z %s\n' "$job" 'rerun with pytest "tests/test_main.py"'
} >"$GH_FAKE/log"

run "https://github.com/o/r/actions/runs/7/job/99" "$tmp/named"
same "a red check's excerpt naming files: one file= line per tracked file it names, repo-relative, first appearance first and once, a runner workspace path reduced to the repo path and a toolchain or untracked path left out, between dropped= and the excerpt" \
  "step=Run tests"$'\n'"dropped=0"$'\n'"file=tests/test_main.py"$'\n'"file=src/app/main.py"$'\n'"excerpt=ERROR tests/test_main.py:8 test_add failed"$'\n'"excerpt=raised at /home/runner/work/r/r/src/app/main.py:12:5 in add"$'\n'"excerpt=called from /usr/lib/python3.11/unittest/case.py:57 in run"$'\n'"excerpt=loaded node_modules/x/index.js:3 first"$'\n'"excerpt=rerun with pytest \"tests/test_main.py\""$'\n'"repo=github.com/o/r"$'\n'"run=7"
expect "a red check's excerpt naming files: the script exits 0" [ "$rc" = 0 ]

printf '%s\tRun tests\t2026-10-14T12:03:00.1234567Z %s\n' "$job" "ERROR tests/test_main.py:8 test_add failed" >"$GH_FAKE/log"
run "https://github.com/o/r/actions/runs/4242/job/99" "$tmp/named"
same "a red check's workflow run to rerun: repo= with the link's host, owner and repo, then run= with the run id of the link, not its job id, both after every step=, dropped=, file= and excerpt= line" \
  "step=Run tests"$'\n'"dropped=0"$'\n'"file=tests/test_main.py"$'\n'"excerpt=ERROR tests/test_main.py:8 test_add failed"$'\n'"repo=github.com/o/r"$'\n'"run=4242"
expect "a red check's workflow run to rerun: the script exits 0" [ "$rc" = 0 ]

mkdir -p "$tmp/plain"
link="https://github.com/o/r/actions/runs/7/job/99"
printf '%s\tRun tests\t2026-10-14T12:04:00.1234567Z %s\n' "$job" "FAIL src/a.test.ts" >"$tmp/log.red"
unanswered() { # $1 the exit wanted, $2 what gh does: log|empty|fail, $3 label, $4.. the script's arguments
  local want="$1" gh="$2" label="$3"
  shift 3
  rm -f "$GH_FAKE/fail"
  case "$gh" in
    log) cp "$tmp/log.red" "$GH_FAKE/log" ;;
    empty) : >"$GH_FAKE/log" ;;
    fail) echo "failed to get run log: HTTP 410" >"$GH_FAKE/fail" ;;
  esac
  run "$@"
  same "$label: nothing on stdout" ""
  expect "$label: the script exits $want" [ "$rc" = "$want" ]
}
unanswered 1 fail "gh cannot read the job's log" "$link" "$tmp/tree"
unanswered 2 log "no argument"
unanswered 2 log "the link alone" "$link"
unanswered 2 log "a third argument" "$link" "$tmp/tree" extra
unanswered 2 log "a tree that is not a git work tree" "$link" "$tmp/plain"
unanswered 3 log "the link is none" none "$tmp/tree"
unanswered 3 log "a pull request's checks page, not a job" "https://github.com/o/r/pull/42/checks" "$tmp/tree"
unanswered 3 log "a link off GitHub Actions" "https://ci.example.com/build/7" "$tmp/tree"
unanswered 3 empty "a job log holding no failed step" "$link" "$tmp/tree"

# A check's details link is set by whoever posts the status: a link to a repository other than the
# pull request's would hand that repository's log to the fixer and its run to pr-rerun.sh.
foreign_link() { # $1 label, $2 the link
  # Optional: $3 the pattern of the gh calls that must not happen (default: any run view, which reads a run or a log)
  rm -f "$GH_FAKE/fail" "$GH_FAKE/calls"
  cp "$tmp/log.red" "$GH_FAKE/log"
  refuses_exit=3 refuses "$1: refused, exit 3 and a pr-log.sh: reason on stderr" opens "pr-log.sh: " "$2" "$tmp/tree"
  same "$1: nothing on stdout" ""
  # shellcheck disable=SC2034  # lib.sh's same reads $out
  out="$(grep "${3:-^run view }" "$GH_FAKE/calls" 2>/dev/null)"
  same "$1: the linked log is never read" ""
}
foreign_link "a check link to another repository on the pull request's host" "https://github.com/someone-else/deploy-repo/actions/runs/7/job/99"
foreign_link "a check link to the pull request's owner and repo on another host" "https://evil.example/o/r/actions/runs/7/job/99"

# The run id and the job id of a link are read apart: a job of another run, or a run of another head
# than the one the run tree is cut at, would hand the fixer a failure that is not the watched one.
git -C "$tmp/tree" rev-parse HEAD >"$GH_FAKE/head"
echo 98 >"$GH_FAKE/jobs"
foreign_link "a check link whose job is not one of the link's run" "https://github.com/o/r/actions/runs/111/job/999" '^run view --job '
echo 99 >"$GH_FAKE/jobs"
git -C "$tmp/named" rev-parse HEAD >"$GH_FAKE/head"
foreign_link "a check link to a run of another head than the tree's" "$link" '^run view --job '

rm -f "$GH_FAKE/fail"
cp "$tmp/log.red" "$GH_FAKE/log"
echo "GraphQL: Could not resolve to a Repository" >"$GH_FAKE/repo_fail"
refuses_exit=1 refuses "gh cannot read the pull request's repository: exit 1 and its reason on stderr" opens "pr-log.sh: cannot read the pull request's repository" "$link" "$tmp/tree"
same "gh cannot read the pull request's repository: nothing on stdout" ""
rm -f "$GH_FAKE/repo_fail"

git -C "$tmp/tree" rev-parse HEAD >"$GH_FAKE/head"
echo "HTTP 404: Not Found" >"$GH_FAKE/run_fail"
refuses_exit=1 refuses "gh cannot read the link's run: exit 1 and a pr-log.sh: reason on stderr" opens "pr-log.sh: " "$link" "$tmp/tree"
same "gh cannot read the link's run: nothing on stdout" ""
rm -f "$GH_FAKE/run_fail"

exit "$((fails > 0))"
