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

refused_once() { # $1 label: the run exited 3 and printed exactly one line, a line=
  if [ "$rc" = 3 ] && [ "$(wc -l <<<"$out")" = 1 ] && [ "${out#line=}" != "$out" ]; then ok "$1"; else
    fail "$1 (exit $rc, wanted 3)"
    dump_out
  fi
}

g branch debt/taken "$tip"
state_before="$(door_state && g worktree list --porcelain)"
run taken "$review"
refused_once "an existing debt/<slug> refuses the cut with one line=: exit 3"
absent_prefix "a refusal over an existing debt/<slug> names no branch" "branch="
absent_prefix "a refusal over an existing debt/<slug> names no worktree" "worktree="
expect "the existing debt/<slug> keeps the commits it held" \
  test "$(g -C "$main" rev-parse -q --verify refs/heads/debt/taken)" = "$tip"
expect "every ref, the working tree and the worktree list are as they were after refusing over debt/<slug>" \
  test "$(door_state && g worktree list --porcelain)" = "$state_before"
expect "no folder is made at the worktree path of a refused debt/<slug>" \
  test ! -e "$main/.claude/worktrees/debt-taken"

occupied="$main/.claude/worktrees/debt-occupied"
mkdir -p "$occupied"
printf 'earlier work\n' >"$occupied/keep.txt"
contents_before="$(cd "$occupied" && snapshot . '%p %y %s\n' && sha256sum keep.txt)"
state_before="$(door_state && g worktree list --porcelain)"
run occupied "$review"
refused_once "an existing folder at the worktree path refuses the cut with one line=: exit 3"
absent_prefix "a refusal over an existing folder names no branch" "branch="
absent_prefix "a refusal over an existing folder names no worktree" "worktree="
expect "no debt/<slug> is created when its worktree path is taken" \
  test -z "$(g -C "$main" rev-parse -q --verify refs/heads/debt/occupied)"
expect "every ref, the working tree and the worktree list are as they were after refusing over the folder" \
  test "$(door_state && g worktree list --porcelain)" = "$state_before"
expect "the existing folder keeps its contents" \
  test "$(cd "$occupied" && snapshot . '%p %y %s\n' && sha256sum keep.txt)" = "$contents_before"

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
check_lines "the cut hands the fix run the Debt review, then the developer's branch to land on: exit 0" \
  0 "$rc" "call=fix $review reports"
expect "debt/reports-export starts at the developer's tip when debt-review.sh ran" \
  test "$(g -C "$main" rev-parse -q --verify refs/heads/debt/reports-export)" = "$reviewed"

fresh held
main="$tmp/held"
printf '.scratch/\n' >.gitignore
printf 'base\n' >README.md
commit base
g checkout -q -b invoices
printf 'export\n' >invoices.txt
commit "invoices export"
short="$(g rev-parse --short HEAD)"
feature="$main/.scratch/20261020-invoices-export"
mkdir -p "$feature"
printf '# Spec: Invoices export\n' >"$feature/spec.md"
review="$feature/spec.debt.review.md"
cat >"$review" <<EOF
# Review: Invoices export

Spec: $feature/spec.md
Fixed point: invoices ($short)
Commit: $short
Spec source: $feature/spec.md
Mode: default
Language: English

## Act on

none

## Consider

### 1. Principles at invoices.txt:1
Claim: the export format is decided in three places
Evidence: Single source of truth; the format string is repeated across the export path
Rung: 3
Mark: too big for a Fixer
Fix: one module owns the export format, in the invoices export
Source: issues/01-export.debt.md, item 1

## Noted

none

## Cleared

none

## Axes

EOF

run invoices-export "$review"
check_lines "a marked Consider Finding hands the developer the /tickets call over the review's Spec: exit 0" \
  0 "$rc" "tickets=/tickets $feature/spec.md"

invoices_review() { # $1 path, $2 the ## Consider body, $3 the ## Noted body: a review of the held fixture
  printf '# Review: Invoices export\n\nSpec: %s\nFixed point: invoices (%s)\nCommit: %s\nSpec source: %s\nMode: default\nLanguage: English\n\n## Act on\n\nnone\n\n## Consider\n\n%s\n\n## Noted\n\n%s\n\n## Cleared\n\nnone\n\n## Axes\n\n' \
    "$feature/spec.md" "$short" "$short" "$feature/spec.md" "$2" "$3" >"$1"
}
unmarked="### 1. Principles at invoices.txt:1
Claim: the export format is decided in three places
Evidence: Single source of truth; the format string is repeated across the export path
Rung: 3
Fix: one module owns the export format, in the invoices export
Source: issues/01-export.debt.md, item 1"
marked="### 2. Principles at invoices.txt:1
Claim: the export pipeline mixes formatting and delivery
Evidence: Separation of concerns; one function renders and uploads
Rung: 3
Mark: too big for a Fixer
Fix: split rendering from delivery across the invoices export
Source: issues/01-export.debt.md, item 2"

invoices_review "$feature/unmarked.debt.review.md" "$unmarked" none
run invoices-unmarked "$feature/unmarked.debt.review.md"
check_absent "a review with no marked Finding hands the developer no /tickets call: exit 0" \
  0 "$rc" "tickets="

invoices_review "$feature/moved.debt.review.md" "$unmarked" "$marked"
run invoices-moved "$feature/moved.debt.review.md"
check_absent "a marked Finding moved out of Consider hands the developer no /tickets call: exit 0" \
  0 "$rc" "tickets="

fresh dirty
main="$tmp/dirty"
printf '.scratch/\n' >.gitignore
printf 'base\n' >README.md
commit base
g checkout -q -b ledger
printf 'export\n' >ledger.txt
commit "ledger export"
short="$(g rev-parse --short HEAD)"
feature="$main/.scratch/20261020-ledger-export"
mkdir -p "$feature"
printf '# Spec: Ledger export\n' >"$feature/spec.md"
review="$feature/spec.debt.review.md"
printf '# Review: Ledger export\n\nSpec: %s\nFixed point: ledger (%s)\nCommit: %s\nSpec source: %s\nMode: default\nLanguage: English\n\n## Act on\n\nnone\n\n## Consider\n\nnone\n\n## Noted\n\nnone\n\n## Cleared\n\nnone\n\n## Axes\n\n' \
  "$feature/spec.md" "$short" "$short" "$feature/spec.md" >"$review"
printf 'unsaved\n' >>ledger.txt
expect "fixture: the developer has an uncommitted change to a tracked file" \
  test "$(g status --porcelain)" = " M ledger.txt"
state_before="$(door_state && g worktree list --porcelain)"
run ledger-export "$review"
check_lines "an uncommitted change in the main checkout refuses the cut: exit 4" \
  4 "$rc" "line=working tree has uncommitted changes; commit or stash before fix"
same "a refusal over an uncommitted change prints that one line and nothing else" \
  "line=working tree has uncommitted changes; commit or stash before fix"
expect "every ref, the working tree and the worktree list are as they were after refusing over an uncommitted change" \
  test "$(door_state && g worktree list --porcelain)" = "$state_before"
expect "no debt/<slug> is created over an uncommitted change" \
  test -z "$(g -C "$main" rev-parse -q --verify refs/heads/debt/ledger-export)"
expect "no folder is made at the worktree path over an uncommitted change" \
  test ! -e "$main/.claude/worktrees/debt-ledger-export"

fresh untracked
main="$tmp/untracked"
printf '.scratch/\n' >.gitignore
printf 'base\n' >README.md
commit base
g checkout -q -b payroll
printf 'export\n' >payroll.txt
commit "payroll export"
short="$(g rev-parse --short HEAD)"
feature="$main/.scratch/20261020-payroll-export"
mkdir -p "$feature"
printf '# Spec: Payroll export\n' >"$feature/spec.md"
review="$feature/spec.debt.review.md"
printf '# Review: Payroll export\n\nSpec: %s\nFixed point: payroll (%s)\nCommit: %s\nSpec source: %s\nMode: default\nLanguage: English\n\n## Act on\n\nnone\n\n## Consider\n\nnone\n\n## Noted\n\nnone\n\n## Cleared\n\nnone\n\n## Axes\n\n' \
  "$feature/spec.md" "$short" "$short" "$feature/spec.md" >"$review"
printf 'draft\n' >payroll-draft.txt
expect "fixture: the developer's only change is a new file never added and not ignored" \
  test "$(g status --porcelain)" = "?? payroll-draft.txt"
state_before="$(door_state && g worktree list --porcelain)"
run payroll-export "$review"
check_lines "a new untracked file in the main checkout refuses the cut: exit 4" \
  4 "$rc" "line=working tree has uncommitted changes; commit or stash before fix"
same "a refusal over an untracked file prints that one line and nothing else" \
  "line=working tree has uncommitted changes; commit or stash before fix"
expect "every ref, the working tree and the worktree list are as they were after refusing over an untracked file" \
  test "$(door_state && g worktree list --porcelain)" = "$state_before"
expect "no debt/<slug> is created over an untracked file" \
  test -z "$(g -C "$main" rev-parse -q --verify refs/heads/debt/payroll-export)"
expect "no folder is made at the worktree path over an untracked file" \
  test ! -e "$main/.claude/worktrees/debt-payroll-export"

fresh spared
main="$tmp/spared"
printf 'base\n' >README.md
commit base
g checkout -q -b tax
feature="$main/.scratch/20261020-tax-export"
mkdir -p "$feature"
printf '# Spec: Tax export\n' >"$feature/spec.md"
printf 'export\n' >tax.txt
commit "tax export"
short="$(g rev-parse --short HEAD)"
review="$feature/spec.debt.review.md"
printf '# Review: Tax export\n\nSpec: %s\nFixed point: tax (%s)\nCommit: %s\nSpec source: %s\nMode: default\nLanguage: English\n\n## Act on\n\nnone\n\n## Consider\n\nnone\n\n## Noted\n\nnone\n\n## Cleared\n\nnone\n\n## Axes\n\n' \
  "$feature/spec.md" "$short" "$short" "$feature/spec.md" >"$review"
expect "fixture: the Debt review is the only change, untracked and not ignored" \
  test "$(g status --porcelain)" = "?? .scratch/20261020-tax-export/spec.debt.review.md"
run tax-export "$review"
check_lines "the run's own untracked Debt review is not an uncommitted change: the cut goes ahead, exit 0" \
  0 "$rc" "branch=debt/tax-export" "worktree=$main/.claude/worktrees/debt-tax-export" "main=$main" \
  "target=tax" "tip=$short" "call=fix $review tax"
absent_prefix "a cut beside the run's own untracked Debt review prints no refusal line" "line="

fresh empty
main="$tmp/empty"
printf '.scratch/\n' >.gitignore
printf 'base\n' >README.md
commit base
g checkout -q -b receipts
printf 'export\n' >receipts.txt
commit "receipts export"
reviewed="$(g rev-parse HEAD)"
short="$(g rev-parse --short HEAD)"
feature="$main/.scratch/20261020-receipts-export"
mkdir -p "$feature"
printf '# Spec: Receipts export\n' >"$feature/spec.md"
review="$feature/spec.debt.review.md"
cat >"$review" <<EOF
# Review: Receipts export

Spec: $feature/spec.md
Fixed point: receipts ($short)
Commit: $short
Spec source: $feature/spec.md
Mode: default
Language: English

## Act on

none

## Consider

### 1. Principles at receipts.txt:1
Claim: the export format is decided in two places
Evidence: Single source of truth; the format string is repeated across the export path
Rung: 3
Fix: one module owns the export format, in the receipts export
Source: issues/01-export.debt.md, item 1

## Noted

none

## Cleared

### 2. Correctness at receipts.txt:1
Claim: an empty receipt list writes no header
Evidence: the export loop starts after the header line
Rung: 4
Refuted by: running the export over an empty list writes the header line alone
Source: issues/01-export.debt.md, item 2

## Axes

EOF
expect "fixture: the review's Act on is exactly none while Consider and Cleared each hold a Finding" \
  test "$(awk '/^## /{s=$0; next} s=="## Act on" && NF' "$review")" = "none"
run receipts-export "$review"
check_lines "a Debt review with nothing to act on is cut like any other and handed to the fix run: exit 0" \
  0 "$rc" "branch=debt/receipts-export" "target=receipts" "call=fix $review receipts"
expect "debt/receipts-export is cut at the Fixed point when Act on is none" \
  test "$(g -C "$main" rev-parse -q --verify refs/heads/debt/receipts-export)" = "$reviewed"

exit "$fails"
