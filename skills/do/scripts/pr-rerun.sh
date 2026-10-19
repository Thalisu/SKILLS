#!/usr/bin/env bash
# pr-rerun.sh: one rerun of the failed jobs of each workflow run named, for the pr Playbook when a
# fixer could not reproduce a red check.
#
#   pr-rerun.sh <pr> <sha> <repo> <run id> [<run id>...]
#     <pr>      the pull request number
#     <sha>     the head commit the checks were read on
#     <repo>    the repository the runs belong to, as <host>/<owner>/<repo>
#     <run id>  a workflow run to rerun; one named twice is rerun once
#
# Prints one rerun=<run id> <attempt> line per distinct run, in first-seen order, once gh reads an
# attempt higher than the one before the rerun.
#
# Exits 0 every run reran · 1 gh missing, or a rerun refused or not seen (a one-line failed: <reason>
# goes to stderr) · 2 usage, nothing on stdout.
set -uo pipefail

# Roughly the time GitHub takes to register a new attempt, with margin.
wait_seconds="${DO_PR_RERUN_SECONDS:-300}"

read_attempt() { # $1 repo, $2 run id: prints the run's attempt; 1 on a read failure
  gh run view "$2" --repo "$1" --json attempt --jq .attempt
}

rerun_failed() { # $1 repo, $2 run id: reruns the failed jobs; 1 with gh's reason on a refusal
  gh run rerun "$2" --repo "$1" --failed
}

await_attempt() { # $1 repo, $2 run id, $3 attempt before: prints the attempt once it is higher; 1 past DO_PR_RERUN_SECONDS
  local deadline=$((SECONDS + wait_seconds)) now
  while :; do
    now="$(read_attempt "$1" "$2")" || return 1
    if [ "$now" -gt "$3" ] 2>/dev/null; then
      printf '%s\n' "$now"
      return 0
    fi
    [ "$SECONDS" -lt "$deadline" ] || return 1
    sleep 1
  done
}

main() {
  if [ $# -lt 4 ]; then
    echo "usage: pr-rerun.sh <pr> <sha> <repo> <run id> [<run id>...]" >&2
    exit 2
  fi
  if ! command -v gh >/dev/null 2>&1; then
    echo "failed: gh missing" >&2
    exit 1
  fi
  local repo="$3" id before after seen=" "
  shift 3
  for id in "$@"; do
    case "$seen" in *" $id "*) continue ;; esac
    seen="$seen$id "
    before="$(read_attempt "$repo" "$id")" || {
      echo "failed: cannot read run $id" >&2
      exit 1
    }
    rerun_failed "$repo" "$id" || {
      echo "failed: rerun of run $id refused" >&2
      exit 1
    }
    after="$(await_attempt "$repo" "$id" "$before")" || {
      echo "failed: no new attempt seen for run $id" >&2
      exit 1
    }
    printf 'rerun=%s %s\n' "$id" "$after"
  done
}

main "$@"
