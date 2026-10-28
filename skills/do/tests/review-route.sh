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

# A target that moved while the review ran, after an integration that moved the branch, is
# integrated again and landed through the fix call on the Review already held: the call names the
# Review and the target, hands on the run's own gate command, and is marked as do's own.
moved="not landed: target moved, spec/feature is at 89abcde and the branch is not on it"
for integration in rebase reapply; do
  route "landing=$moved" "integration=$integration" "command=command=bash skills/do/scripts/gate.sh"
  check_lines "a target that moved after an integration that read $integration is landed through the fix call" 1 "$rc" \
    "landing=not landed" "reason=target moved, spec/feature is at 89abcde and the branch is not on it" \
    "fix=fix /repo/.scratch/feature/issues/07-ticket.review.md spec/feature" \
    "gate=command=bash skills/do/scripts/gate.sh" "caller=Caller: do" "route=fix"
done

# A resume that ran no gate of its own hands the fix call no gate command: one carried over would be
# another session's.
route "landing=$moved" "integration=rebase"
check_lines "a fix call with no gate of the run's own still names the Review and do as its caller" 1 "$rc" \
  "fix=fix /repo/.scratch/feature/issues/07-ticket.review.md spec/feature" "caller=Caller: do" "route=fix"
absent_prefix "a fix call with no gate of the run's own carries no gate line" "gate="

exit $((fails > 0))
