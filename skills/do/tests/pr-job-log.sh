#!/usr/bin/env bash
# pr-job-log.sh: the contract of scripts/pr-job-log.sh, the red check's whole job log the pr
# Playbook hands every pr fixer on its Log: line.
# Run: bash skills/do/tests/pr-job-log.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/pr-job-log.sh"
fails=0

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home" GH_FAKE="$tmp/gh"
mkdir -p "$HOME" "$GH_FAKE" "$tmp/bin" "$tmp/out"

# The fake gh: scripts/tests/stubs/gh, whose header names the $GH_FAKE files it reads.
cp "$here/../../../scripts/tests/stubs/gh" "$tmp/bin/gh"
chmod +x "$tmp/bin/gh"
echo "https://github.com/o/r" >"$GH_FAKE/repo_url"
echo 99 >"$GH_FAKE/jobs"
export PATH="$tmp/bin:$PATH"

run() { # $1.. the script's arguments: its stdout in $out, its exit in $rc
  # The run the link names is a run of the tree's HEAD here.
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
link="https://github.com/o/r/actions/runs/7/job/99"
{
  printf '%s\tStart services\t2026-10-14T12:00:00.1234567Z %s\n' "$job" "db: container name /pg already in use"
  printf '%s\tStart services\t2026-10-14T12:00:01.1234567Z %s\n' "$job" "${esc}[32mservices up${esc}[0m"
  printf '%s\tRun tests\t2026-10-14T12:01:00.1234567Z %s\n' "$job" "${esc}[31mFAIL${esc}[0m src/a.test.ts"
} >"$GH_FAKE/log"
want_log="$job"$'\t'"Start services"$'\t'"2026-10-14T12:00:00.1234567Z db: container name /pg already in use"$'\n'"$job"$'\t'"Start services"$'\t'"2026-10-14T12:00:01.1234567Z services up"$'\n'"$job"$'\t'"Run tests"$'\t'"2026-10-14T12:01:00.1234567Z FAIL src/a.test.ts"

run "$link" "$tmp/tree" "$tmp/out/log-1"
same "a red check's whole job log: log= names the out file's absolute path and lines= its line count" \
  "log=$tmp/out/log-1"$'\n'"lines=3"
expect "a red check's whole job log: the script exits 0" [ "$rc" = 0 ]
# shellcheck disable=SC2034  # lib.sh's same reads $out
out="$(cat "$tmp/out/log-1" 2>/dev/null)"
same "a red check's whole job log: the out file holds every step's lines as gh prints them, a step that passed included, with only the ANSI escapes stripped" "$want_log"

# A check's details link is set by whoever posts the status: a link pr-log.sh refuses unread would
# hand the fixer a log its poster controls, so the whole log is refused on the same link.
refused_unread() { # $1 label, $2 the link
  # Optional: $3 the pattern of the gh calls that must not happen (default: any run view, which reads a run or a log)
  rm -f "$GH_FAKE/fail" "$GH_FAKE/calls" "$tmp/out/refused"
  refuses_exit=3 refuses "$1: refused, exit 3 and a pr-job-log.sh: reason on stderr" opens "pr-job-log.sh: " "$2" "$tmp/tree" "$tmp/out/refused"
  same "$1: nothing on stdout" ""
  # shellcheck disable=SC2034  # lib.sh's same reads $out
  out="$(grep "${3:-^run view }" "$GH_FAKE/calls" 2>/dev/null)"
  same "$1: the linked log is never read" ""
  expect "$1: no file is written" [ ! -e "$tmp/out/refused" ]
}
git -C "$tmp/tree" rev-parse HEAD >"$GH_FAKE/head"
refused_unread "a check link to another repository on the pull request's host" "https://github.com/someone-else/deploy-repo/actions/runs/7/job/99"
refused_unread "a check link to the pull request's owner and repo on another host" "https://evil.example/o/r/actions/runs/7/job/99"

exit "$((fails > 0))"
