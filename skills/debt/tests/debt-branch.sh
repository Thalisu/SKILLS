#!/usr/bin/env bash
# debt-branch.sh: the contract of scripts/debt-branch.sh, which cuts the Fixers' debt/<slug> branch
# at the Debt review's Fixed point, in a worktree of its own under the main checkout.
# Run: bash skills/debt/tests/debt-branch.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/debt-branch.sh"
fails=0
tmp="$(cd "$(mktemp -d)" && pwd -P)"
trap 'cd /; rm -rf "$tmp"' EXIT

run() {
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines reads $out
  out="$(cd "$tmp" && bash "$script" "$@" 2>&1)" || rc=$?
}

fresh cut
main="$tmp/cut"
printf '.scratch/\n' >.gitignore
printf 'base\n' >README.md
commit base
g checkout -q -b feature
printf 'export\n' >notes.txt
commit "notes export"
reviewed="$(g rev-parse HEAD)"
short="$(g rev-parse --short HEAD)"
feature="$main/.scratch/20261020-notes-export"
mkdir -p "$feature"
printf '# Spec: Notes export\n' >"$feature/spec.md"
review="$feature/spec.debt.review.md"
printf '# Review: Notes export\n\nSpec: %s\nFixed point: feature (%s)\nCommit: %s\nSpec source: %s\nMode: default\nLanguage: English\n\n## Act on\n\nnone\n\n## Consider\n\nnone\n\n## Noted\n\nnone\n\n## Cleared\n\nnone\n\n## Axes\n\n' \
  "$feature/spec.md" "$short" "$short" "$feature/spec.md" >"$review"
printf 'later\n' >>notes.txt
commit "after the review"
tip="$(g rev-parse feature)"
expect "fixture: the developer's tip moved past the Fixed point" test "$tip" != "$reviewed"
status_before="$(g -C "$main" status --porcelain)"

wt="$main/.claude/worktrees/debt-notes-export"
run notes-export "$review"
check_lines "the cut names its branch, worktree, main checkout, and the Fixed point's branch and sha: exit 0" \
  0 "$rc" "branch=debt/notes-export" "worktree=$wt" "main=$main" "target=feature" "tip=$short"
expect "debt/notes-export starts at the Fixed point's sha, not the developer's moved tip" \
  test "$(g -C "$main" rev-parse -q --verify refs/heads/debt/notes-export)" = "$reviewed"
expect "the worktree is one git lists under the main checkout, checked out on debt/notes-export" \
  test "$(branch_of_worktree "$main" "$wt")" = "refs/heads/debt/notes-export"
expect "the developer's branch keeps its tip" \
  test "$(g -C "$main" rev-parse refs/heads/feature)" = "$tip"
expect "the main checkout stays on the developer's branch" \
  test "$(g -C "$main" symbolic-ref HEAD)" = "refs/heads/feature"
expect "the main checkout's working tree status is unchanged" \
  test "$(g -C "$main" status --porcelain)" = "$status_before"

fresh pair
main="$tmp/pair"
printf '.scratch/\n' >.gitignore
printf 'base\n' >README.md
commit base
g checkout -q -b reports
printf 'export\n' >reports.txt
commit "reports export"
feature="$main/.scratch/20261020-reports-export"
mkdir -p "$feature/issues"
printf '# Spec: Reports export\n' >"$feature/spec.md"
printf '## 2026-10-20 09:00\n\n- the export path is hardcoded\n' >"$feature/issues/01-export.debt.md"
returns="$tmp/pair-returns"
mkdir -p "$returns"
reviewed="$(g rev-parse HEAD)"
# shellcheck disable=SC2034  # lib.sh's term reads $out
out="$(cd "$main" && bash "$here/../scripts/debt-review.sh" reports-export "$returns" 2>&1)"
review="$(term review)"
expect "fixture: debt-review.sh wrote the Debt review" test -f "$review"
printf 'later\n' >>reports.txt
commit "after the review"
expect "fixture: the developer's tip moved past the review" test "$(g rev-parse reports)" != "$reviewed"

run reports-export "$review"
check_lines "a cut from the review debt-review.sh wrote targets the developer's branch: exit 0" \
  0 "$rc" "target=reports"
expect "debt/reports-export starts at the developer's tip when debt-review.sh ran" \
  test "$(g -C "$main" rev-parse -q --verify refs/heads/debt/reports-export)" = "$reviewed"

exit "$fails"
