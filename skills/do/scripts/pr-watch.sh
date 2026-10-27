#!/usr/bin/env bash
# pr-watch.sh: the CI verdict of one pull request, read off the GitHub CLI after blocking on its
# checks for at most DO_PR_WATCH_SECONDS (default 540), so the pr Playbook never reads the checks
# itself and never ends its turn while they run.
#
#   pr-watch.sh <pr> [<since> <state>] [<expected-sha>]
#     <pr>               a pull request number or URL, passed to gh as it stands
#     <since> <state>    the since= and state= of the previous pending verdict, as printed, which
#                        carry the 60-minute stall window across calls
#     <expected-sha>     the full sha of a tip just pushed, or the expect= of the previous pending
#                        verdict: while the pull request's head is another commit the watch holds
#                        verdict=pending and never settles on the old head's checks, for at most
#                        DO_PR_WATCH_REGISTER_SECONDS, measured by the since= carried across calls
#
# Prints key=value lines, verdict first: verdict=green, checks=<n> (0 once no check registered inside
# DO_PR_WATCH_REGISTER_SECONDS, default 120, which holds awaiting-approval and draft with no check the same way) | verdict=pending, since=<epoch>,
# state=<token>, then expect=<sha> while the head is not yet the expected sha | verdict=awaiting-approval, checks=<n> | verdict=draft, checks=<n> (every check
# passed on a draft pull request, which cannot merge until marked ready) | verdict=conflict, head=<head branch>,
# base=<base branch> | verdict=behind, head=<head branch>, base=<base branch> (every check passed and the head
# lacks commits of its base) | verdict=changes-requested, head=<head branch>, base=<base branch> (every
# check passed and a reviewer asked for changes) | verdict=cancelled, head=<head branch>, sha=<head commit>,
# then one cancelled=<link> <name> line per cancelled check, none failed or pending | verdict=red, head=<head branch>, sha=<head commit>, then one
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
# A pull request with no checks stays pending this long, from the first read, before it is green with
# checks=0: the workflows of a repository with CI register seconds after the pull request opens.
register_seconds="${DO_PR_WATCH_REGISTER_SECONDS:-120}"
gh_err="$(mktemp)"
trap 'rm -f "$gh_err"' EXIT

usage() {
  echo "usage: pr-watch.sh <pr> [<since> <state>] [<expected-sha>]" >&2
  exit 2
}

# gh exits 1 with "no checks reported" on a pull request that has none, which is not a read failure.
read_checks() { # $1 pr: prints one "<bucket> <link|none> <name>" line per check, nothing for a pull request with none; 1 on a read failure
  local out
  out="$(gh pr checks "$1" --json name,bucket,link --jq '
    def field: if . == null or . == "" then "none" else . end;
    .[] | "\(.bucket) \(.link | field) \(.name)"' 2>"$gh_err")" || {
    grep -qi 'no checks reported' "$gh_err" && return 0
    return 1
  }
  [ -z "$out" ] || echo "$out"
}

fingerprint() { # stdin: read_checks lines: prints the state token (bucket and name only, the link ignored) of that set of checks, independent of their order
  sed 's/^\([^ ]*\) [^ ]* /\1 /' | LC_ALL=C sort | cksum | tr ' ' '-'
}

read_pull() { # $1 pr: prints "<merge state> <mergeable> <review decision> <head> <base> <sha> <draft>", states lowercased, an absent or empty field as none, draft as true or false; 1 on a read failure
  gh pr view "$1" --json mergeStateStatus,mergeable,reviewDecision,headRefName,baseRefName,headRefOid,isDraft --jq '
    def field: if . == null or . == "" then "none" else . end;
    [(.mergeStateStatus | field | ascii_downcase), (.mergeable | field | ascii_downcase),
      (.reviewDecision | field | ascii_downcase), (.headRefName | field), (.baseRefName | field), (.headRefOid | field),
      (.isDraft // false | tostring)]
    | join(" ")'
}

classify() { # $1 read_checks lines, $2 merge state, $3 mergeable, $4 review decision, $5 draft: prints conflict|red|green|awaiting-approval|draft|cancelled|behind|changes-requested|wait|settling-<green|awaiting-approval|draft|behind|changes-requested> (no check yet, the verdict waits out the registration grace), or exits 3 with its stderr line
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
  if grep -q '^cancel ' <<<"$1"; then
    echo cancelled
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
  if [ "$5" = true ] && [ "$2" != unknown ]; then
    if [ -n "$1" ]; then echo draft; else echo settling-draft; fi
    return
  fi
  case "$2" in
    clean | has_hooks)
      if [ -n "$1" ]; then echo green; else echo settling-green; fi
      ;;
    blocked)
      if [ "$4" = review_required ]; then
        if [ -n "$1" ]; then echo awaiting-approval; else echo settling-awaiting-approval; fi
      elif [ "$4" = changes_requested ]; then
        if [ -n "$1" ]; then echo changes-requested; else echo settling-changes-requested; fi
      else
        echo "pr-watch.sh: no verdict yet for merge state blocked (review $4)" >&2
        exit 3
      fi
      ;;
    behind)
      if [ -n "$1" ]; then echo behind; else echo settling-behind; fi
      ;;
    unknown) echo wait ;;
    *)
      echo "pr-watch.sh: no verdict yet for merge state $2" >&2
      exit 3
      ;;
  esac
}

read_once() { # $1 pr: sets checks, the pull fields and result (as classify prints it); exits 1 on a read failure, 3 as classify does
  merge="" mergeable="" review="" head="" base="" sha="" draft=""
  checks="$(read_checks "$1")" || exit 1
  read -r merge mergeable review head base sha draft <<<"$(read_pull "$1")"
  [ -n "$merge" ] || exit 1
  result="$(classify "$checks" "$merge" "$mergeable" "$review" "$draft")" || exit "$?"
  if [ "$sha" = "$expected" ]; then
    expected=""
  elif [ -n "$expected" ]; then
    result="wait"
  fi
}

keep_window() { # after a wait or settling read: keeps since and state while the checks are unchanged, restarts them otherwise; sets result to stalled once a pending check sat unchanged for stall_seconds, to the verdict a settling-* result names once no check appeared for register_seconds
  local now fresh
  now="$(date +%s)"
  if [ -n "$expected" ]; then
    fresh="$(fingerprint <<<"expect $expected")"
    if [ "$fresh" != "$state" ]; then
      since="$now"
      state="$fresh"
    fi
    [ $((now - since)) -ge "$register_seconds" ] || return 0
    expected=""
    result="$(classify "$checks" "$merge" "$mergeable" "$review" "$draft")" || exit "$?"
    holding || return 0
  fi
  fresh="$(fingerprint <<<"$checks")"
  if [ "$fresh" != "$state" ]; then
    since="$now"
    state="$fresh"
  fi
  if grep -q '^pending ' <<<"$checks" && [ $((now - since)) -ge "$stall_seconds" ]; then
    result=stalled
  fi
  if [[ "$result" == settling-* ]] && [ $((now - since)) -ge "$register_seconds" ]; then
    result="${result#settling-}"
  fi
}

holding() { [ "$result" = wait ] || [[ "$result" == settling-* ]]; }

main() {
  [ "$#" -ge 1 ] && [ "$#" -le 4 ] || usage
  [[ "$bound" =~ ^[0-9]+$ ]] && [[ "$interval" =~ ^[0-9]+$ ]] || usage
  [[ "$register_seconds" =~ ^[0-9]+$ ]] || usage
  local since="" state="" expected=""
  if [ "$#" = 3 ] || [ "$#" = 4 ]; then
    [[ "$2" =~ ^[0-9]+$ ]] && [[ "$3" =~ ^[0-9-]+$ ]] || usage
    since="$2" state="$3"
  fi
  if [ "$#" = 2 ] || [ "$#" = 4 ]; then
    expected="${!#}"
    [[ "$expected" =~ ^[0-9a-f]{40}$ ]] || usage
  fi
  command -v gh >/dev/null 2>&1 || {
    echo "pr-watch.sh: gh not found" >&2
    exit 1
  }
  local checks merge mergeable review head base sha draft result count remaining
  read_once "$1"
  holding && keep_window
  while holding; do
    remaining=$((bound - SECONDS))
    if [ "$remaining" -le 0 ]; then
      echo "verdict=pending"
      echo "since=$since"
      echo "state=$state"
      [ -z "$expected" ] || echo "expect=$expected"
      return 0
    fi
    sleep "$((interval < remaining ? interval : remaining))"
    read_once "$1"
    holding && keep_window
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
  if [ "$result" = behind ] || [ "$result" = changes-requested ]; then
    echo "verdict=$result"
    echo "head=$head"
    echo "base=$base"
    return 0
  fi
  if [ "$result" = cancelled ]; then
    echo "verdict=cancelled"
    echo "head=$head"
    echo "sha=$sha"
    sed -n 's/^cancel /cancelled=/p' <<<"$checks"
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
