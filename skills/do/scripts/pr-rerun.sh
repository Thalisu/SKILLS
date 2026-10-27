#!/usr/bin/env bash
# pr-rerun.sh: one rerun of the failed jobs of each workflow run named, for the pr Playbook when a
# fixer could not reproduce a red check.
#
#   pr-rerun.sh <pr> <sha> <repo> <run id> [<run id>...]
#     <pr>      the pull request, its URL or its number, as gh pr view takes it
#     <sha>     the head commit the checks were read on
#     <repo>    the repository the runs belong to, as <host>/<owner>/<repo>
#     <run id>  a workflow run to rerun; one named twice is rerun once
#
# Prints one rerun=<run id> <attempt> line per distinct run, in first-seen order, once gh reads an
# attempt higher than the one before the rerun. When the pull request's head is no longer <sha>, it
# prints moved=<head sha> instead and reruns nothing. A <repo> that is not the pull request's
# repository, a run whose head commit is not <sha> and a run of another repository are refused
# before any run is rerun: the run ids come from a check's details link, which whoever posts a
# status sets. A failure prints one failed: line, the last stdout line, after the rerun= lines made
# so far, and reruns no later run. A refusal made before any run is rerun carries no run id first
# (failed: <reason>, a run named inside the reason as "run <run id>"): it concerns every run named,
# and the caller refuses every check it passed. A failure of one run's own rerun reads
# failed: <run id>: <reason>.
#
# Exits 0 every run reran, or the head moved · 1 gh missing, the head or a run unreadable, or a
# rerun refused or not seen (the failed: line is on stdout) · 2 usage, on stderr, nothing on stdout.
set -uo pipefail

# Roughly the time GitHub takes to register a new attempt, with margin.
wait_seconds="${DO_PR_RERUN_SECONDS:-300}"

read_head() { # $1 pr: prints the pull request's head commit; 1 on a read failure
  gh pr view "$1" --json headRefOid --jq .headRefOid
}

read_pr_repo() { # $1 pr: prints <host>/<owner>/<repo> of the pull request; 1 on a read failure
  local url
  url="$(gh pr view "$1" --json url --jq .url 2>/dev/null)" || return 1
  url="${url#https://}"
  url="${url%%/pull/*}"
  [ -n "$url" ] && [ "$url" != "${url#*/*/}" ] || return 1
  printf '%s\n' "$url"
}

read_identity() { # $1 repo, $2 run id: prints the run's head commit, a tab, then its url; 1 on a read failure
  gh run view "$2" --repo "$1" --json headSha,url --jq '[.headSha, .url] | @tsv'
}

read_attempt() { # $1 repo, $2 run id: prints the run's attempt; 1 on a read failure
  gh run view "$2" --repo "$1" --json attempt --jq .attempt
}

rerun_failed() { # $1 repo, $2 run id: reruns the failed jobs; 1 printing gh's one-line reason on a refusal
  local err
  err="$(gh run rerun "$2" --repo "$1" --failed 2>&1 >/dev/null)" && return 0
  err="$(printf '%s' "$err" | tr '\n' ' ' | sed 's/^ *//; s/ *$//')"
  printf '%s\n' "${err:-gh refused the rerun}"
  return 1
}

fail() { # $1 reason: prints the failed: line on stdout and exits 1
  printf 'failed: %s\n' "$1"
  exit 1
}

await_attempt() { # $1 repo, $2 run id, $3 attempt before: prints the attempt once it is higher; 1 past DO_PR_RERUN_SECONDS
  local deadline=$((SECONDS + wait_seconds)) now
  while :; do
    now="$(read_attempt "$1" "$2" 2>/dev/null)" || return 1
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
  command -v gh >/dev/null 2>&1 || fail "gh missing"
  local head pr="$1"
  head="$(read_head "$1" 2>/dev/null)" || fail "cannot read the head of pull request $1"
  if [ "$head" != "$2" ]; then
    printf 'moved=%s\n' "$head"
    exit 0
  fi
  local sha="$2" repo="$3" id before after reason seen=" " ids=() run_sha run_url run_repo pr_repo
  shift 3
  pr_repo="$(read_pr_repo "$pr")" || fail "cannot read the repository of pull request $pr"
  [ "${repo,,}" = "${pr_repo,,}" ] || fail "the repository $repo is not the pull request's repository $pr_repo"
  for id in "$@"; do
    case "$seen" in *" $id "*) continue ;; esac
    seen="$seen$id "
    ids+=("$id")
  done
  for id in "${ids[@]}"; do
    run_sha="$(read_identity "$repo" "$id" 2>&1)" || fail "run $id: $(printf '%s' "${run_sha:-cannot read the run}" | tr '\n' ' ' | sed 's/ *$//')"
    run_url="${run_sha#*$'\t'}"
    run_sha="${run_sha%%$'\t'*}"
    [ "$run_sha" = "$sha" ] || fail "run $id: its headSha $run_sha is not $sha"
    run_repo="${run_url#https://}"
    run_repo="${run_repo%%/actions/*}"
    [ "${run_repo,,}" = "${pr_repo,,}" ] || fail "run $id: the run belongs to $run_repo, not the pull request's repository $pr_repo"
  done
  for id in "${ids[@]}"; do
    before="$(read_attempt "$repo" "$id" 2>&1)" || fail "$id: $(printf '%s' "${before:-cannot read the run}" | tr '\n' ' ' | sed 's/ *$//')"
    reason="$(rerun_failed "$repo" "$id")" || fail "$id: $reason"
    after="$(await_attempt "$repo" "$id" "$before")" || fail "$id: rerun not seen"
    printf 'rerun=%s %s\n' "$id" "$after"
  done
}

main "$@"
