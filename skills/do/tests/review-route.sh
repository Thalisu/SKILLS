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

# A target that moved after an integration that found it already held sends the run through its
# in-run Resume once, the fix call made from the same lines, instead of stopping.
for last in review fix; do
  route "landing=$moved" "integration=noop" "last=$last" "command=command=bash skills/do/scripts/gate.sh"
  check_lines "a target that moved after a no-op integration, on the return of a $last call, takes the in-run Resume" 3 "$rc" \
    "fix=fix /repo/.scratch/feature/issues/07-ticket.review.md spec/feature" \
    "gate=command=bash skills/do/scripts/gate.sh" "caller=Caller: do" "route=resume"
done

# The same return after the in-run Resume's own no-op means the run would loop on a tip it already
# met: it stops for the developer, with no further fix call.
route "landing=$moved" "integration=noop" "last=resume"
check_lines "a target that moved after the in-run Resume's no-op integration stops the run as blocked" 4 "$rc" \
  "reason=target moved, spec/feature is at 89abcde and the branch is not on it" "route=blocked"
absent_prefix "a run stopped on a tip it already met makes no further fix call" "fix="

# A reason naming Findings leaves those Findings open, and the developer reads from one line which
# ones, and the two ways to close them: fix them in the worktree, or overrule them in the Review,
# then request the run again. The Findings are named wherever the reason names them.
open_direction="Yours: direction: Finding 2, 5 stays open in /repo/.scratch/feature/issues/07-ticket.review.md: fix it in /repo/.claude/worktrees/do-ticket and run do on /repo/.scratch/feature/issues/07-ticket.md again, or overrule it by editing /repo/.scratch/feature/issues/07-ticket.review.md and running do on /repo/.scratch/feature/issues/07-ticket.md again"
for reason in "Finding 2, 5 not fixed or not verified" \
  "gate fixer did not return, Diff tests; Finding 2, 5 not fixed or not verified"; do
  route "landing=not landed: $reason" "last=fix"
  check_lines "a reason naming Findings ($reason) stops the run with the Findings and the way to close them" 4 "$rc" \
    "reason=$reason" "direction=findings" "findings=2, 5" "yours=$open_direction" "route=blocked"
done

# A reviewed, Green branch whose target refuses commits only needs landing elsewhere, and the
# developer lands it by hand from the two lines printed.
route "landing=not landed: spec/feature is a protected branch"
check_lines "a protected target stops the run with the way to land the branch elsewhere" 4 "$rc" \
  "direction=protected" \
  "yours=Yours: direction: land do/ticket on a branch that takes commits, or leave it in its worktree" \
  "by_hand=git switch <a branch that takes commits>" "by_hand=git merge --ff-only do/ticket" \
  "route=blocked"

# A red gate on the tree a re-integration handed the fix call stops the run with the one line that
# undoes that whole integration, back to the commit recorded before it started.
before=fedcba9876543210fedcba9876543210fedcba98
for last in fix resume; do
  route "landing=not landed: gate red, the unit suite" "last=$last" "before=$before"
  check_lines "a red gate on the $last call's tree stops the run with the undo of the re-integration" 4 "$rc" \
    "reason=gate red, the unit suite" "undo=git reset --hard $before" "route=blocked"
done

# Any other reason stops the run with the review's own words quoted, which the session words the
# blocked Reply from, never from a reading of the Review: no direction line is composed for it.
for reason in "the fast-forward of spec/feature to do/ticket failed" "Axis Security not run"; do
  route "landing=not landed: $reason"
  check_lines "any other reason ($reason) stops the run with that reason quoted" 4 "$rc" \
    "reason=$reason" "direction=reason" "route=blocked"
  absent_prefix "any other reason ($reason) carries no composed direction line" "yours="
done

exit $((fails > 0))
