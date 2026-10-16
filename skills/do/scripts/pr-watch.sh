#!/usr/bin/env bash
# pr-watch.sh: the CI verdict of one pull request, read off the GitHub CLI after blocking on its
# checks for at most DO_PR_WATCH_SECONDS (default 540), so the pr Playbook never reads the checks
# itself and never ends its turn while they run.
#
#   pr-watch.sh <pr> [<since> <state>]
#     <pr>               a pull request number or URL, passed to gh as it stands
#     <since> <state>    the since= and state= of the previous pending verdict, as printed, which
#                        carry the 60-minute stall window across calls
#
# Prints key=value lines, verdict first: verdict=green, checks=<n> | verdict=pending, since=<epoch>,
# state=<token> | verdict=awaiting-approval, checks=<n> | verdict=conflict, head=<head branch>,
# base=<base branch> | verdict=red, head=<head branch>, sha=<head commit>, then one
# red=<link> <name> line per failed check | verdict=stalled, then one pending=<check name> line per
# pending check. Later verdict words and keys append; a reader ignores keys it does not know.
# Exit codes: 0 a verdict printed · 1 gh missing or unable to read · 2 usage · 3 a settled state no
# verdict word covers yet. Nothing on stdout for 1, 2 or 3.
# DO_PR_WATCH_SECONDS and DO_PR_WATCH_INTERVAL (default 30) override the bound and the poll interval.
set -uo pipefail

# 540 seconds leaves one read's margin under the Bash tool's 600000 ms timeout, which kills a
# watch that outlives it before it prints a verdict.
bound="${DO_PR_WATCH_SECONDS:-540}"
interval="${DO_PR_WATCH_INTERVAL:-30}"
# A pending check whose set of checks has not changed for this long is on a runner that is gone.
stall_seconds=3600

usage() {
  echo "usage: pr-watch.sh <pr> [<since> <state>]" >&2
  exit 2
}

read_checks() { # $1 pr: prints one "<bucket> <link|none> <name>" line per check; 1 on a read failure
  gh pr checks "$1" --json name,bucket,link --jq '
    def field: if . == null or . == "" then "none" else . end;
    .[] | "\(.bucket) \(.link | field) \(.name)"'
}

fingerprint() { # stdin: read_checks lines: prints the state token (bucket and name only, the link ignored) of that set of checks, independent of their order
  sed 's/^\([^ ]*\) [^ ]* /\1 /' | LC_ALL=C sort | cksum | tr ' ' '-'
}

read_pull() { # $1 pr: prints "<merge state> <mergeable> <review decision> <head> <base> <sha>", states lowercased, an absent or empty field as none; 1 on a read failure
  gh pr view "$1" --json mergeStateStatus,mergeable,reviewDecision,headRefName,baseRefName,headRefOid --jq '
    def field: if . == null or . == "" then "none" else . end;
    [(.mergeStateStatus | field | ascii_downcase), (.mergeable | field | ascii_downcase),
      (.reviewDecision | field | ascii_downcase), (.headRefName | field), (.baseRefName | field), (.headRefOid | field)]
    | join(" ")'
}

classify() { # $1 read_checks lines, $2 merge state, $3 mergeable, $4 review decision: prints conflict|red|green|awaiting-approval|wait, or exits 3 with its stderr line
  local bucket link name
  if [ "$3" = conflicting ] || [ "$2" = dirty ]; then
    echo conflict
    return
  fi
  if grep -q '^pending ' <<<"$1"; then
    echo wait
    return
  fi
  if grep -q '^fail ' <<<"$1"; then
    echo red
    return
  fi
  while read -r bucket link name; do
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
    blocked)
      if [ "$4" = review_required ]; then
        echo awaiting-approval
      else
        echo "pr-watch.sh: no verdict yet for merge state blocked (review $4)" >&2
        exit 3
      fi
      ;;
    unknown) echo wait ;;
    *)
      echo "pr-watch.sh: no verdict yet for merge state $2" >&2
      exit 3
      ;;
  esac
}

read_once() { # $1 pr: sets checks, the pull fields and result (conflict|green|awaiting-approval|wait); exits 1 on a read failure, 3 as classify does
  merge="" mergeable="" review="" head="" base="" sha=""
  checks="$(read_checks "$1")" || exit 1
  read -r merge mergeable review head base sha <<<"$(read_pull "$1")"
  [ -n "$merge" ] || exit 1
  result="$(classify "$checks" "$merge" "$mergeable" "$review")" || exit "$?"
}

keep_window() { # after a wait read: keeps since and state while the checks are unchanged, restarts them otherwise; sets result to stalled once a pending check sat unchanged for stall_seconds
  local now fresh
  now="$(date +%s)"
  fresh="$(fingerprint <<<"$checks")"
  if [ "$fresh" != "$state" ]; then
    since="$now"
    state="$fresh"
  fi
  if grep -q '^pending ' <<<"$checks" && [ $((now - since)) -ge "$stall_seconds" ]; then
    result=stalled
  fi
}

main() {
  [ "$#" = 1 ] || [ "$#" = 3 ] || usage
  [[ "$bound" =~ ^[0-9]+$ ]] && [[ "$interval" =~ ^[0-9]+$ ]] || usage
  local since="" state=""
  if [ "$#" = 3 ]; then
    [[ "$2" =~ ^[0-9]+$ ]] && [[ "$3" =~ ^[0-9-]+$ ]] || usage
    since="$2" state="$3"
  fi
  command -v gh >/dev/null 2>&1 || {
    echo "pr-watch.sh: gh not found" >&2
    exit 1
  }
  local checks merge mergeable review head base sha result count remaining
  read_once "$1"
  [ "$result" = wait ] && keep_window
  while [ "$result" = wait ]; do
    remaining=$((bound - SECONDS))
    if [ "$remaining" -le 0 ]; then
      echo "verdict=pending"
      echo "since=$since"
      echo "state=$state"
      return 0
    fi
    sleep "$((interval < remaining ? interval : remaining))"
    read_once "$1"
    [ "$result" = wait ] && keep_window
  done
  if [ "$result" = stalled ]; then
    echo "verdict=stalled"
    sed -n 's/^pending [^ ]* /pending=/p' <<<"$checks"
    return 0
  fi
  if [ "$result" = conflict ]; then
    echo "verdict=conflict"
    echo "head=$head"
    echo "base=$base"
    return 0
  fi
  if [ "$result" = red ]; then
    echo "verdict=red"
    echo "head=$head"
    echo "sha=$sha"
    sed -n 's/^fail /red=/p' <<<"$checks"
    return 0
  fi
  count=0
  [ -n "$checks" ] && count="$(grep -c '' <<<"$checks")"
  echo "verdict=$result"
  echo "checks=$count"
}

main "$@"
