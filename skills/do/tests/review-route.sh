#!/usr/bin/env bash
# review-route.sh: the contract of scripts/review-route.sh, the route a session takes after the
# review's return or a fix call's, read off the landing line and the run's state as key=value lines
# on stdin. Run: bash skills/do/tests/review-route.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/review-route.sh"
fails=0

route() { # $@ key=value lines that replace or add to the run's defaults: the script's output in $out, its exit in $rc
  local line key input
  local -A given=()
  local -a order=(landing integration last review target worktree branch rerun)
  given=(
    [landing]="landed at 0123456789abcdef0123456789abcdef01234567"
    [integration]=rebase
    [last]=review
    [review]=/repo/.scratch/feature/issues/07-ticket.review.md
    [target]=spec/feature
    [worktree]=/repo/.claude/worktrees/do-ticket
    [branch]=do/ticket
    [rerun]=/repo/.scratch/feature/issues/07-ticket.md
  )
  for line in "$@"; do
    key="${line%%=*}"
    case " ${order[*]} " in *" $key "*) ;; *) order+=("$key") ;; esac
    given[$key]="${line#*=}"
  done
  input=""
  for key in "${order[@]}"; do input+="$key=${given[$key]}"$'\n'; done
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines reads $out
  out="$(printf '%s' "$input" | bash "$script" 2>&1)" || rc=$?
}

# The session goes on to the verification only on a landing, whichever form the landing line takes.
route "landing=landed at 0123456789abcdef0123456789abcdef01234567"
check_lines "a landing goes on to the verification" 0 "$rc" \
  "landing=landed" "commit=0123456789abcdef0123456789abcdef01234567" "route=verify"
route "landing=landed at 0123456789abcdef0123456789abcdef01234567, rebased onto spec/feature at 89abcde"
check_lines "a landing rebased onto its target goes on to the verification" 0 "$rc" \
  "landing=landed" "commit=0123456789abcdef0123456789abcdef01234567" "route=verify"

exit $((fails > 0))
