#!/usr/bin/env bash
# pr-watch.sh: the CI verdict of one pull request, read off the GitHub CLI after blocking on its
# checks for at most DO_PR_WATCH_SECONDS (default 540), so the pr Playbook never reads the checks
# itself and never ends its turn while they run.
#
#   pr-watch.sh <pr>        <pr> a pull request number or URL, passed to gh as it stands
#
# Prints key=value lines, verdict first: verdict=green, checks=<n> | verdict=pending |
# verdict=conflict, head=<head branch>, base=<base branch>. Later
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

read_pull() { # $1 pr: prints "<merge state> <mergeable> <review decision> <head> <base>", states lowercased, an absent or empty field as none; 1 on a read failure
  gh pr view "$1" --json mergeStateStatus,mergeable,reviewDecision,headRefName,baseRefName --jq '
    def field: if . == null or . == "" then "none" else . end;
    [(.mergeStateStatus | field | ascii_downcase), (.mergeable | field | ascii_downcase),
      (.reviewDecision | field | ascii_downcase), (.headRefName | field), (.baseRefName | field)]
    | join(" ")'
}

classify() { # $1 read_checks lines, $2 merge state, $3 mergeable: prints conflict|green|wait, or exits 3 with its stderr line
  local bucket name
  if [ "$3" = conflicting ] || [ "$2" = dirty ]; then
    echo conflict
    return
  fi
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

read_once() { # $1 pr: sets checks, the pull fields and result (conflict|green|wait); exits 1 on a read failure, 3 as classify does
  merge="" mergeable="" review="" head="" base=""
  checks="$(read_checks "$1")" || exit 1
  read -r merge mergeable review head base <<<"$(read_pull "$1")"
  [ -n "$merge" ] || exit 1
  result="$(classify "$checks" "$merge" "$mergeable")" || exit "$?"
}

main() {
  [ "$#" = 1 ] || usage
  [[ "$bound" =~ ^[0-9]+$ ]] && [[ "$interval" =~ ^[0-9]+$ ]] || usage
  command -v gh >/dev/null 2>&1 || {
    echo "pr-watch.sh: gh not found" >&2
    exit 1
  }
  local checks merge mergeable review head base result count remaining
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
  if [ "$result" = conflict ]; then
    echo "verdict=conflict"
    echo "head=$head"
    echo "base=$base"
    return 0
  fi
  count=0
  [ -n "$checks" ] && count="$(grep -c '' <<<"$checks")"
  echo "verdict=green"
  echo "checks=$count"
}

main "$@"
