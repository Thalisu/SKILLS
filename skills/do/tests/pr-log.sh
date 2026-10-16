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

# The fake gh answers `gh run view --job 99 --repo github.com/o/r --log-failed` with the recorded
# log in $GH_FAKE/log, and refuses any other command line.
cat >"$tmp/bin/gh" <<'SH'
#!/usr/bin/env bash
[ "$*" = "run view --job 99 --repo github.com/o/r --log-failed" ] || { echo "fake gh: unexpected command: $*" >&2; exit 1; }
cat "$GH_FAKE/log"
SH
chmod +x "$tmp/bin/gh"
export PATH="$tmp/bin:$PATH"

run() { # $1.. the script's arguments: its stdout in $out, its exit in $rc
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
  "step=Type check"$'\n'"step=Run tests"$'\n'"dropped=10"$'\n'"$want_tail"
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
  "step=Run tests"$'\n'"dropped=0"$'\n'"file=tests/test_main.py"$'\n'"file=src/app/main.py"$'\n'"excerpt=ERROR tests/test_main.py:8 test_add failed"$'\n'"excerpt=raised at /home/runner/work/r/r/src/app/main.py:12:5 in add"$'\n'"excerpt=called from /usr/lib/python3.11/unittest/case.py:57 in run"$'\n'"excerpt=loaded node_modules/x/index.js:3 first"$'\n'"excerpt=rerun with pytest \"tests/test_main.py\""
expect "a red check's excerpt naming files: the script exits 0" [ "$rc" = 0 ]

exit "$((fails > 0))"
