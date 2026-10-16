#!/usr/bin/env bash
# pr-watch.sh: the CI verdict of one pull request, read off the GitHub CLI after blocking on its
# checks for at most DO_PR_WATCH_SECONDS (default 540), so the pr Playbook never reads the checks
# itself and never ends its turn while they run.
#
#   pr-watch.sh <pr>        <pr> a pull request number or URL, passed to gh as it stands
#
# Prints key=value lines, verdict first: verdict=green, checks=<n> | verdict=pending. Later
# verdict words and keys append; a reader ignores keys it does not know.
# Exit codes: 0 a verdict printed · 1 gh missing or unable to read · 2 usage · 3 a settled state no
# verdict word covers yet. Nothing on stdout for 1, 2 or 3.
# DO_PR_WATCH_SECONDS and DO_PR_WATCH_INTERVAL (default 30) override the bound and the poll interval.
set -uo pipefail

# 540 seconds leaves one read's margin under the Bash tool's 600000 ms timeout, which kills a
# watch that outlives it before it prints a verdict.
bound="${DO_PR_WATCH_SECONDS:-540}"
interval="${DO_PR_WATCH_INTERVAL:-30}"

usage() {
  echo "usage: pr-watch.sh <pr>" >&2
  exit 2
}

read_checks() { # $1 pr: prints one "<bucket> <name>" line per check; 1 on a read failure
  gh pr checks "$1" --json name,bucket --jq '.[] | "\(.bucket) \(.name)"'
}

read_merge_state() { # $1 pr: prints the lowercased mergeStateStatus; 1 on a read failure
  gh pr view "$1" --json mergeStateStatus --jq '.mergeStateStatus | ascii_downcase'
}

classify() { # $1 read_checks lines, $2 merge state or empty: prints green|wait, or exits 3 with its stderr line
  local bucket name
  if grep -q '^pending ' <<<"$1"; then
    echo wait
    return
  fi
  while read -r bucket name; do
    case "$bucket" in
      '' | pass | skipping) ;;
      *)
        echo "pr-watch.sh: no verdict yet for check $name ($bucket)" >&2
        exit 3
        ;;
    esac
  done <<<"$1"
  case "$2" in
    clean | has_hooks) echo green ;;
    unknown) echo wait ;;
    *)
      echo "pr-watch.sh: no verdict yet for merge state $2" >&2
      exit 3
      ;;
  esac
}

read_once() { # $1 pr: sets checks and result (green|wait); exits 1 on a read failure, 3 as classify does
  state=""
  checks="$(read_checks "$1")" || exit 1
  if ! grep -q '^pending ' <<<"$checks"; then
    state="$(read_merge_state "$1")" || exit 1
  fi
  result="$(classify "$checks" "$state")" || exit "$?"
}

main() {
  [ "$#" = 1 ] || usage
  [[ "$bound" =~ ^[0-9]+$ ]] && [[ "$interval" =~ ^[0-9]+$ ]] || usage
  command -v gh >/dev/null 2>&1 || {
    echo "pr-watch.sh: gh not found" >&2
    exit 1
  }
  local checks state result count remaining
  read_once "$1"
  while [ "$result" = wait ]; do
    remaining=$((bound - SECONDS))
    if [ "$remaining" -le 0 ]; then
      echo "verdict=pending"
      return 0
    fi
    sleep "$((interval < remaining ? interval : remaining))"
    read_once "$1"
  done
  count=0
  [ -n "$checks" ] && count="$(grep -c '' <<<"$checks")"
  echo "verdict=green"
  echo "checks=$count"
}

main "$@"
