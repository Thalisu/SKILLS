#!/usr/bin/env bash
# pr-job-link.sh: whether a red check's link is safe to read, the one rule pr-log.sh and
# pr-job-log.sh share. Sourced, never run: it defines these functions and does nothing else.
#
#   check_job_link <link> <tree>  sets repo (<host>/<owner>/<repo>), run, job and run_sha (the
#                                 run's head commit) and returns 0, or
#                                 sets reason and returns 1 (gh missing or unable to read), 2 (not a
#                                 work tree) or 3 (refused unread)
#
# Whoever posts a status sets its link: a link whose <host>/<owner>/<repo> is not the pull request's
# base repository, as gh resolves it from <tree>, is refused unread, and so is one whose job is not
# one of its run's jobs: a job id in the same repository can be a fork pull request's job, whose log
# its author controls.
#
# Prints nothing and exits nothing: each caller prints its own <script>: <reason> line and exits
# with the code returned.

# shellcheck disable=SC2034 # repo, run, job and reason are read by the sourcing script.
parse_link() { # $1 link: sets repo, run and job; returns 3 with reason set when it is not an Actions job URL
  local re='^https://([^/]+)/([^/]+)/([^/]+)/actions/runs/([0-9]+)/job/([0-9]+)([?#].*)?$'
  if [[ ! "$1" =~ $re ]]; then
    reason="not a GitHub Actions job link: $1"
    return 3
  fi
  repo="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}/${BASH_REMATCH[3]}" run="${BASH_REMATCH[4]}" job="${BASH_REMATCH[5]}"
}

read_base_repo() { # $1 tree: prints <host>/<owner>/<repo> of the pull request's base repository; 1 on a read failure
  local url
  url="$(cd "$1" && gh repo view --json url --jq .url 2>/dev/null)" || return 1
  url="${url#https://}"
  [ -n "$url" ] && [ "$url" != "${url#*/*/}" ] || return 1
  printf '%s\n' "${url%/}"
}

read_run_identity() { # $1 repo, $2 run id: prints the run's head commit, then the id of each of its jobs, one per line
  gh run view "$2" --repo "$1" --json headSha,jobs --jq '.headSha, (.jobs[].databaseId)'
}

# shellcheck disable=SC2034 # reason and run_sha are read by the sourcing script.
check_job_link() { # $1 link, $2 tree: sets repo, run, job and returns 0; or sets reason and returns 1, 2 or 3
  local base identity
  if ! git -C "$2" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    reason="not a git work tree: $2"
    return 2
  fi
  parse_link "$1" || return
  if ! command -v gh >/dev/null 2>&1; then
    reason="gh is not on PATH"
    return 1
  fi
  base="$(read_base_repo "$2")" || {
    reason="cannot read the pull request's repository"
    return 1
  }
  if [ "${repo,,}" != "${base,,}" ]; then
    reason="the link is to $repo, not the pull request's repository $base: $1"
    return 3
  fi
  identity="$(read_run_identity "$repo" "$run" 2>/dev/null)" || {
    reason="gh could not read run $run"
    return 1
  }
  run_sha="$(printf '%s\n' "$identity" | head -n 1)"
  if ! printf '%s\n' "$identity" | tail -n +2 | grep -qx "$job"; then
    reason="job $job is not a job of run $run: $1"
    return 3
  fi
}
