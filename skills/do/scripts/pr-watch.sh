#!/usr/bin/env bash
# pr-watch.sh: the CI verdict of one pull request, read off the GitHub CLI, so the pr Playbook
# never reads the checks itself.
#
#   pr-watch.sh <pr>        <pr> a pull request number or URL, passed to gh as it stands
#
# Prints key=value lines, verdict first: verdict=green, checks=<n>. Later verdict words and keys
# append; a reader ignores keys it does not know.
# Exit codes: 0 a verdict printed · 1 gh missing or unable to read · 2 usage · 3 a settled state no
# verdict word covers yet. Nothing on stdout for 1, 2 or 3.
set -uo pipefail

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

classify() { # $1 read_checks lines, $2 merge state: prints green, or exits 3 with its stderr line
  local bucket name
  while read -r bucket name; do
    case "$bucket" in
      pass | skipping) ;;
      *)
        echo "pr-watch.sh: no verdict yet for check $name ($bucket)" >&2
        exit 3
        ;;
    esac
  done <<<"$1"
  case "$2" in
    clean | has_hooks) echo green ;;
    *)
      echo "pr-watch.sh: no verdict yet for merge state $2" >&2
      exit 3
      ;;
  esac
}

main() {
  [ "$#" = 1 ] || usage
  command -v gh >/dev/null 2>&1 || {
    echo "pr-watch.sh: gh not found" >&2
    exit 1
  }
  local checks state count
  checks="$(read_checks "$1")" || exit 1
  state="$(read_merge_state "$1")" || exit 1
  classify "$checks" "$state" >/dev/null
  count=0
  [ -n "$checks" ] && count="$(grep -c '' <<<"$checks")"
  echo "verdict=green"
  echo "checks=$count"
}

main "$@"
