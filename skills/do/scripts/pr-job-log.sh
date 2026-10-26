#!/usr/bin/env bash
# pr-job-log.sh: a red check's whole job log, every step included and not only the failed ones,
# written to a file the pr Playbook hands its fixer fork on the brief's Log: line.
#
#   pr-job-log.sh <link> <tree> <out>
#     <link>    a red= line's link from pr-watch.sh
#     <tree>    the run tree, cut detached at the watched commit
#     <out>     the new file the log is written to
#
# Writes every line of the job's log as gh prints it, with only the ANSI escapes stripped, so a line
# the excerpt quotes is found in it by search. Prints log=<absolute path of out> then lines=<n>, n
# being the file's line count.
#
# Exits 0 the log written · 1 gh missing or unable to read the log · 2 usage · 3 refused unread
# (not an Actions job link) or an empty log. Nothing on stdout and no file for 1, 2 or 3; a one-line
# pr-job-log.sh: <reason> goes to stderr.
set -uo pipefail

read_whole_log() { # $1 repo, $2 job id: the raw log lines of every step
  gh run view --job "$2" --repo "$1" --log
}

main() {
  local re='^https://([^/]+)/([^/]+)/([^/]+)/actions/runs/([0-9]+)/job/([0-9]+)([?#].*)?$'
  local repo job log out esc
  if [ "$#" -ne 3 ]; then
    echo "usage: pr-job-log.sh <link> <tree> <out>" >&2
    exit 2
  fi
  if [[ ! "$1" =~ $re ]]; then
    echo "pr-job-log.sh: not a GitHub Actions job link: $1" >&2
    exit 3
  fi
  repo="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}/${BASH_REMATCH[3]}" job="${BASH_REMATCH[5]}"
  if ! command -v gh >/dev/null 2>&1; then
    echo "pr-job-log.sh: gh is not on PATH" >&2
    exit 1
  fi
  out="$(cd "$(dirname "$3")" && pwd)/$(basename "$3")"
  if ! log="$(read_whole_log "$repo" "$job")"; then
    echo "pr-job-log.sh: gh could not read the log of job $job" >&2
    exit 1
  fi
  if [ -z "$log" ]; then
    echo "pr-job-log.sh: the log of job $job is empty" >&2
    exit 3
  fi
  esc=$'\e'
  printf '%s\n' "$log" | sed "s/$esc\[[0-9;?]*[A-Za-z]//g" >"$out.partial" && mv "$out.partial" "$out" || {
    rm -f "$out.partial"
    echo "pr-job-log.sh: cannot write $out" >&2
    exit 1
  }
  printf 'log=%s\nlines=%s\n' "$out" "$(wc -l <"$out" | tr -d ' ')"
}

main "$@"
