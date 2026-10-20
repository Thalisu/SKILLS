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
taken_wt="$main/.claude/worktrees/debt-taken"
expect "fixture: debt/taken exists with no folder at its worktree path" test ! -e "$taken_wt"
expect "fixture: git lists no worktree on debt/taken" \
  test -z "$(g -C "$main" worktree list --porcelain | grep -Fx 'branch refs/heads/debt/taken')"
head_before="$(g -C "$main" rev-parse HEAD)"
review_before="$(sha256sum "$review")"
run taken "$review"
check_lines "a not-landed debt/<slug> with no worktree anywhere is resumed with its worktree added back: exit 0" \
  0 "$rc" "cut=resumed" "branch=debt/taken" "worktree=$taken_wt" "tip=$short"
expect "the worktree added back is one git lists under the main checkout, checked out on debt/taken" \
  test "$(branch_of_worktree "$main" "$taken_wt")" = "refs/heads/debt/taken"
expect "the resumed debt/<slug> keeps the commits it held, not reset to the Fixed point" \
  test "$(g -C "$main" rev-parse -q --verify refs/heads/debt/taken)" = "$tip"
expect "the developer's branch keeps its tip after resuming with the worktree added back" \
  test "$(g -C "$main" rev-parse refs/heads/feature)" = "$tip"
expect "the main checkout's HEAD stays on the developer's branch at its commit after resuming" \
  test "$(g -C "$main" symbolic-ref HEAD) $(g -C "$main" rev-parse HEAD)" = "refs/heads/feature $head_before"
expect "the Debt review keeps every byte after resuming with the worktree added back" \
  test "$(sha256sum "$review")" = "$review_before"

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

fresh resumed
main="$tmp/resumed"
printf '.scratch/\n' >.gitignore
printf 'base\n' >README.md
commit base
g checkout -q -b orders
printf 'export\n' >orders.txt
commit "orders export"
short="$(g rev-parse --short HEAD)"
feature="$main/.scratch/20261020-orders-export"
mkdir -p "$feature"
printf '# Spec: Orders export\n' >"$feature/spec.md"
review="$feature/spec.debt.review.md"
printf '# Review: Orders export\n\nSpec: %s\nFixed point: orders (%s)\nCommit: %s\nSpec source: %s\nMode: default\nLanguage: English\n\n## Act on\n\nnone\n\n## Consider\n\nnone\n\n## Noted\n\nnone\n\n## Cleared\n\nnone\n\n## Axes\n\n' \
  "$feature/spec.md" "$short" "$short" "$feature/spec.md" >"$review"
wt="$main/.claude/worktrees/debt-orders-export"
run orders-export "$review"
expect "fixture: the first run cut debt/orders-export in its worktree" \
  test "$(branch_of_worktree "$main" "$wt")" = "refs/heads/debt/orders-export"
printf 'fixed\n' >"$wt/orders.txt"
g -C "$wt" add -A >/dev/null
g -C "$wt" commit -qm "fix Finding 1"
fixer="$(g -C "$main" rev-parse -q --verify refs/heads/debt/orders-export)"
expect "fixture: debt/orders-export holds the Fixer's commit past the Fixed point" \
  test "$(g -C "$main" rev-parse "$fixer^")" = "$(g -C "$main" rev-parse "$short")"
cat >>"$review" <<EOF
## Fix run

Date: 2026-10-20 · at $short

- 1: fixed $(g -C "$main" rev-parse --short "$fixer"), not verified (\`bash tests/orders.test.sh\`)
- wave 1: 1
- duplication scan: skip: no test asset changed
- diff tests: \`bash tests/orders.test.sh\`: red
- gate fixer: two attempts, still red
- gate: \`bash tests/orders.test.sh\`: red
- not landed: Finding 1 not fixed or not verified; the branch debt/orders-export and its worktree stay in place
EOF
review_before="$(sha256sum "$review")"
state_before="$(door_state && g worktree list --porcelain)"
run orders-export "$review"
check_lines "a debt/<slug> a run left not landed is resumed in its worktree at the unchanged Fixed point: exit 0" \
  0 "$rc" "cut=resumed" "worktree=$wt" "tip=$short" "call=fix $review orders"
expect "the resumed debt/<slug> keeps the Fixer's commit as its tip" \
  test "$(g -C "$main" rev-parse -q --verify refs/heads/debt/orders-export)" = "$fixer"
expect "every ref, the working tree and the worktree list are as they were after resuming" \
  test "$(door_state && g worktree list --porcelain)" = "$state_before"
expect "the Debt review keeps every byte after resuming" \
  test "$(sha256sum "$review")" = "$review_before"

retry="$feature/retry.debt.review.md"
sed '/^## Fix run$/,$d' "$review" >"$retry"
retry_wt="$main/.claude/worktrees/debt-orders-retry"
run orders-retry "$retry"
fixed_point="$(g -C "$main" rev-parse "$short")"
expect "fixture: the first run cut debt/orders-retry in its worktree at the Fixed point" \
  test "$(g -C "$main" rev-parse -q --verify refs/heads/debt/orders-retry)" = "$fixed_point"
printf 'later\n' >>orders.txt
commit "after the review"
expect "fixture: debt/orders-retry holds no commit of its own and the developer's branch moved past it" \
  g -C "$main" merge-base --is-ancestor refs/heads/debt/orders-retry refs/heads/orders
expect "fixture: the developer's tip is not the Fixed point" \
  test "$(g -C "$main" rev-parse refs/heads/orders)" != "$fixed_point"
cat >>"$retry" <<EOF
## Fix run

Date: 2026-10-20 · at $short

- 1: not fixed: the Fixer could not turn \`bash tests/orders.test.sh\` green
- wave 1: 1
- duplication scan: skip: no Fixer commit
- diff tests: skip: no Fixer commit
- gate: \`bash tests/orders.test.sh\`: green
- not landed: no Fixer commit; the branch debt/orders-retry and its worktree stay in place
EOF
retry_before="$(sha256sum "$retry")"
run orders-retry "$retry"
check_lines "a not-landed debt/<slug> with no Fixer commit, already inside the developer's moved branch, is resumed: exit 0" \
  0 "$rc" "cut=resumed" "worktree=$retry_wt"
expect "the resumed debt/<slug> with no Fixer commit is not removed and stays at the Fixed point" \
  test "$(g -C "$main" rev-parse -q --verify refs/heads/debt/orders-retry)" = "$fixed_point"
expect "the worktree of the resumed debt/<slug> with no Fixer commit is still listed on its branch" \
  test "$(branch_of_worktree "$main" "$retry_wt")" = "refs/heads/debt/orders-retry"
expect "the Debt review keeps every byte after resuming a debt/<slug> with no Fixer commit" \
  test "$(sha256sum "$retry")" = "$retry_before"

twice="$feature/twice.debt.review.md"
sed '/^## Fix run$/,$d' "$review" >"$twice"
twice_wt="$main/.claude/worktrees/debt-orders-twice"
run orders-twice "$twice"
expect "fixture: the first run cut debt/orders-twice in its worktree" \
  test "$(branch_of_worktree "$main" "$twice_wt")" = "refs/heads/debt/orders-twice"
expect "fixture: debt/orders-twice sits at the Fixed point, the earlier run's landed sha" \
  test "$(g -C "$main" rev-parse -q --verify refs/heads/debt/orders-twice)" = "$fixed_point"
expect "fixture: the earlier run's landed sha, the Fixed point, is inside the developer's branch" \
  g -C "$main" merge-base --is-ancestor "$fixed_point" refs/heads/orders
cat >>"$twice" <<EOF
## Fix run

Date: 2026-10-20 · at $short

- 1: fixed $short, verified (\`bash tests/orders.test.sh\`)
- wave 1: 1
- duplication scan: skip: no test asset changed
- diff tests: \`bash tests/orders.test.sh\`: green
- gate: \`bash tests/orders.test.sh\`: green
- landed at $short

## Fix run

Date: 2026-10-20 · at $short

- 1: not fixed: the Fixer made no commit
- wave 1: 1
- duplication scan: skip: no Fixer commit
- diff tests: skip: no Fixer commit
- gate fixer: not needed
- gate: \`bash tests/orders.test.sh\`: green
- not landed: Finding 1 not fixed or not verified; the branch debt/orders-twice and its worktree stay in place
EOF
twice_before="$(sha256sum "$twice")"
run orders-twice "$twice"
check_lines "a landed Fix run followed by a not-landed one resumes debt/<slug>: the last landing line decides: exit 0" \
  0 "$rc" "cut=resumed" "worktree=$twice_wt"
expect "the debt/<slug> resumed after a later not-landed run is not removed and stays at the Fixed point" \
  test "$(g -C "$main" rev-parse -q --verify refs/heads/debt/orders-twice)" = "$fixed_point"
expect "the worktree of the debt/<slug> resumed after a later not-landed run is still listed on its branch" \
  test "$(branch_of_worktree "$main" "$twice_wt")" = "refs/heads/debt/orders-twice"
expect "the Debt review keeps every byte after resuming past an earlier landed run" \
  test "$(sha256sum "$twice")" = "$twice_before"

cut_with_fixer() { # $1 slug, $2 review: cuts debt/$1 and commits a Fixer change in its worktree; that commit's sha in $fixer
  run "$1" "$2"
  expect "fixture: the first run cut debt/$1 in its worktree" \
    test "$(branch_of_worktree "$main" "$main/.claude/worktrees/debt-$1")" = "refs/heads/debt/$1"
  printf 'fixed\n' >"$main/.claude/worktrees/debt-$1/orders.txt"
  g -C "$main/.claude/worktrees/debt-$1" add -A >/dev/null
  g -C "$main/.claude/worktrees/debt-$1" commit -qm "fix Finding 1"
  fixer="$(g -C "$main" rev-parse -q --verify "refs/heads/debt/$1")"
  expect "fixture: debt/$1 holds a Fixer commit past the Fixed point" \
    test "$(g -C "$main" rev-parse "$fixer^")" = "$fixed_point"
}
kept_resumed() { # $1 the state the review is in, $2 slug, $3 review, $4 the review's sha256sum before the run: the run's outcome over a debt/<slug> holding $fixer
  check_lines "a debt/<slug> holding a Fixer commit, with $1, is resumed in its worktree: exit 0" \
    0 "$rc" "cut=resumed" "worktree=$main/.claude/worktrees/debt-$2"
  expect "the debt/<slug> resumed with $1 keeps the Fixer's commit as its tip" \
    test "$(g -C "$main" rev-parse -q --verify "refs/heads/debt/$2")" = "$fixer"
  expect "the worktree of the debt/<slug> resumed with $1 is still listed on its branch" \
    test "$(branch_of_worktree "$main" "$main/.claude/worktrees/debt-$2")" = "refs/heads/debt/$2"
  expect "the Debt review keeps every byte after resuming with $1" \
    test "$(sha256sum "$3")" = "$4"
}

landed="$feature/landed.debt.review.md"
sed '/^## Fix run$/,$d' "$review" >"$landed"
cut_with_fixer orders-landed "$landed"
cat >>"$landed" <<EOF
## Fix run

Date: 2026-10-20 · at $short

- 1: fixed $short, verified (\`bash tests/orders.test.sh\`)
- wave 1: 1
- duplication scan: skip: no test asset changed
- diff tests: \`bash tests/orders.test.sh\`: green
- gate: \`bash tests/orders.test.sh\`: green
- landed at $short
EOF
expect "fixture: the review's landed sha is inside the developer's branch" \
  g -C "$main" merge-base --is-ancestor "$fixed_point" refs/heads/orders
expect "fixture: debt/orders-landed holds a commit the landed sha lacks" \
  test "$(g -C "$main" merge-base refs/heads/debt/orders-landed "$fixed_point")" != "$fixer"
landed_before="$(sha256sum "$landed")"
run orders-landed "$landed"
kept_resumed "a last landed at line its tip is past" orders-landed "$landed" "$landed_before"

unrecorded="$feature/unrecorded.debt.review.md"
sed '/^## Fix run$/,$d' "$review" >"$unrecorded"
cut_with_fixer orders-unrecorded "$unrecorded"
expect "fixture: the review holds no ## Fix run section" \
  test "$(grep -c '^## Fix run$' "$unrecorded")" = 0
unrecorded_before="$(sha256sum "$unrecorded")"
run orders-unrecorded "$unrecorded"
kept_resumed "no Fix run section in the review" orders-unrecorded "$unrecorded" "$unrecorded_before"

interrupted="$feature/interrupted.debt.review.md"
sed '/^## Fix run$/,$d' "$review" >"$interrupted"
cut_with_fixer orders-interrupted "$interrupted"
cat >>"$interrupted" <<EOF
## Fix run

Date: 2026-10-20 · at $short

- 1: fixed $(g -C "$main" rev-parse --short "$fixer"), verified (\`bash tests/orders.test.sh\`)
- wave 1: 1
EOF
interrupted_before="$(sha256sum "$interrupted")"
run orders-interrupted "$interrupted"
kept_resumed "a last Fix run section that stops before its landing line" orders-interrupted "$interrupted" "$interrupted_before"

fresh recut
main="$tmp/recut"
printf '.scratch/\n' >.gitignore
printf 'base\n' >README.md
commit base
g checkout -q -b shipments
printf 'export\n' >shipments.txt
commit "shipments export"
short="$(g rev-parse --short HEAD)"
fixed_point="$(g rev-parse HEAD)"
feature="$main/.scratch/20261020-shipments-export"
mkdir -p "$feature"
printf '# Spec: Shipments export\n' >"$feature/spec.md"
review="$feature/spec.debt.review.md"
printf '# Review: Shipments export\n\nSpec: %s\nFixed point: shipments (%s)\nCommit: %s\nSpec source: %s\nMode: default\nLanguage: English\n\n## Act on\n\nnone\n\n## Consider\n\nnone\n\n## Noted\n\nnone\n\n## Cleared\n\nnone\n\n## Axes\n\n' \
  "$feature/spec.md" "$short" "$short" "$feature/spec.md" >"$review"
wt="$main/.claude/worktrees/debt-shipments-export"
cut_with_fixer shipments-export "$review"
g merge -q --ff-only refs/heads/debt/shipments-export
landed_short="$(g rev-parse --short "$fixer")"
cat >>"$review" <<EOF
## Fix run

Date: 2026-10-20 · at $short

- 1: fixed $landed_short, verified (\`bash tests/shipments.test.sh\`)
- wave 1: 1
- duplication scan: skip: no test asset changed
- diff tests: \`bash tests/shipments.test.sh\`: green
- gate: \`bash tests/shipments.test.sh\`: green
- landed at $landed_short
EOF
printf 'later\n' >>shipments.txt
commit "after the landing"
tip="$(g rev-parse refs/heads/shipments)"
tip_short="$(g rev-parse --short refs/heads/shipments)"
expect "fixture: debt/shipments-export's tip is the landed sha and inside the developer's branch" \
  g -C "$main" merge-base --is-ancestor "$fixer" refs/heads/shipments
expect "fixture: the developer's tip moved past the landed sha" test "$tip" != "$fixer"
expect "fixture: the worktree is still listed on debt/shipments-export" \
  test "$(branch_of_worktree "$main" "$wt")" = "refs/heads/debt/shipments-export"
head_before="$(g -C "$main" symbolic-ref HEAD) $(g -C "$main" rev-parse HEAD)"
rest_before="$(sed '1,/^## /{/^Fixed point: /d;/^Commit: /d}' "$review" | sha256sum)"
run shipments-export "$review"
check_lines "a landed debt/<slug> is removed with its worktree and cut again at the target's tip: exit 0" \
  0 "$rc" "cut=recut" "branch=debt/shipments-export" "worktree=$wt" "target=shipments" "tip=$tip_short" \
  "call=fix $review shipments"
expect "the recut debt/<slug> points at the target's tip, not at the old landed sha" \
  test "$(g -C "$main" rev-parse -q --verify refs/heads/debt/shipments-export)" = "$tip"
expect "the recut worktree is listed at the same path, checked out on debt/<slug>" \
  test "$(branch_of_worktree "$main" "$wt")" = "refs/heads/debt/shipments-export"
expect "the recut worktree's HEAD is the target's tip" \
  test "$(g -C "$wt" rev-parse HEAD)" = "$tip"
expect "the developer's branch keeps its tip after the recut" \
  test "$(g -C "$main" rev-parse refs/heads/shipments)" = "$tip"
expect "the main checkout's HEAD stays on the developer's branch at its commit after the recut" \
  test "$(g -C "$main" symbolic-ref HEAD) $(g -C "$main" rev-parse HEAD)" = "$head_before"
expect "after a recut the Debt review's Fixed point names the target at the tip the recut cut at" \
  test "$(sed -n '1,/^## /{/^Fixed point: /p}' "$review")" = "Fixed point: shipments ($tip_short)"
expect "after a recut the Debt review's Commit names the same tip as the Fixed point" \
  test "$(sed -n '1,/^## /{/^Commit: /p}' "$review")" = "Commit: $tip_short"
expect "the recut changes no byte of the Debt review besides its Fixed point and Commit lines" \
  test "$(sed '1,/^## /{/^Fixed point: /d;/^Commit: /d}' "$review" | sha256sum)" = "$rest_before"

dirty="$feature/dirty.debt.review.md"
printf 'pending\n' >orders.txt
commit "orders pending again"
fixed_point="$(g rev-parse refs/heads/shipments)"
fixed_short="$(g rev-parse --short refs/heads/shipments)"
printf '# Review: Shipments export\n\nSpec: %s\nFixed point: shipments (%s)\nCommit: %s\nSpec source: %s\nMode: default\nLanguage: English\n\n## Act on\n\nnone\n\n## Consider\n\nnone\n\n## Noted\n\nnone\n\n## Cleared\n\nnone\n\n## Axes\n\n' \
  "$feature/spec.md" "$fixed_short" "$fixed_short" "$feature/spec.md" >"$dirty"
dirty_wt="$main/.claude/worktrees/debt-shipments-dirty"
cut_with_fixer shipments-dirty "$dirty"
g merge -q --ff-only refs/heads/debt/shipments-dirty
dirty_landed="$(g rev-parse --short "$fixer")"
cat >>"$dirty" <<EOF
## Fix run

Date: 2026-10-20 · at $fixed_short

- 1: fixed $dirty_landed, verified (\`bash tests/shipments.test.sh\`)
- wave 1: 1
- duplication scan: skip: no test asset changed
- diff tests: \`bash tests/shipments.test.sh\`: green
- gate: \`bash tests/shipments.test.sh\`: green
- landed at $dirty_landed
EOF
printf 'later again\n' >>shipments.txt
commit "after the second landing"
printf 'still writing\n' >"$dirty_wt/draft.txt"
expect "fixture: debt/shipments-dirty's tip is the landed sha and inside the developer's branch" \
  g -C "$main" merge-base --is-ancestor "$fixer" refs/heads/shipments
expect "fixture: the landed worktree holds an untracked file" \
  test "$(g -C "$dirty_wt" status --porcelain)" = "?? draft.txt"
state_before="$(door_state && g worktree list --porcelain)"
dirty_before="$(sha256sum "$dirty")"
run shipments-dirty "$dirty"
refused_once "a landed debt/<slug> whose worktree has uncommitted changes is refused with one line=: exit 3"
check_lines "the refusal over a dirty landed worktree names the branch and the worktree, and that nothing was removed" \
  3 "$rc" "line=debt/shipments-dirty landed but its worktree $dirty_wt has uncommitted changes; nothing removed"
expect "the landed debt/<slug> with a dirty worktree keeps its tip" \
  test "$(g -C "$main" rev-parse -q --verify refs/heads/debt/shipments-dirty)" = "$fixer"
expect "the dirty worktree is still listed on its debt/<slug>" \
  test "$(branch_of_worktree "$main" "$dirty_wt")" = "refs/heads/debt/shipments-dirty"
expect "the dirty worktree keeps its uncommitted change" \
  test "$(cat "$dirty_wt/draft.txt" 2>/dev/null)" = "still writing"
expect "every ref, the working tree and the worktree list are as they were after refusing over a dirty landed worktree" \
  test "$(door_state && g worktree list --porcelain)" = "$state_before"
expect "the Debt review keeps every byte, its Fixed point and Commit lines included, after refusing over a dirty landed worktree" \
  test "$(sha256sum "$dirty")" = "$dirty_before"

held="$feature/held.debt.review.md"
printf 'pending\n' >orders.txt
commit "orders pending a third time"
fixed_point="$(g rev-parse refs/heads/shipments)"
fixed_short="$(g rev-parse --short refs/heads/shipments)"
printf '# Review: Shipments export\n\nSpec: %s\nFixed point: shipments (%s)\nCommit: %s\nSpec source: %s\nMode: default\nLanguage: English\n\n## Act on\n\nnone\n\n## Consider\n\nnone\n\n## Noted\n\nnone\n\n## Cleared\n\nnone\n\n## Axes\n\n' \
  "$feature/spec.md" "$fixed_short" "$fixed_short" "$feature/spec.md" >"$held"
held_wt="$main/.claude/worktrees/debt-shipments-held"
cut_with_fixer shipments-held "$held"
g merge -q --ff-only refs/heads/debt/shipments-held
held_landed="$(g rev-parse --short "$fixer")"
cat >>"$held" <<EOF
## Fix run

Date: 2026-10-20 · at $fixed_short

- 1: fixed $held_landed, verified (\`bash tests/shipments.test.sh\`)
- wave 1: 1
- duplication scan: skip: no test asset changed
- diff tests: \`bash tests/shipments.test.sh\`: green
- gate: \`bash tests/shipments.test.sh\`: green
- landed at $held_landed
EOF
printf 'later a third time\n' >>shipments.txt
commit "after the third landing"
expect "fixture: debt/shipments-held's tip is the landed sha and inside the developer's branch" \
  g -C "$main" merge-base --is-ancestor "$fixer" refs/heads/shipments
expect "fixture: the developer's tip moved past debt/shipments-held's landed sha" \
  test "$(g rev-parse refs/heads/shipments)" != "$fixer"
expect "fixture: the landed worktree of debt/shipments-held is clean" \
  test -z "$(g -C "$held_wt" status --porcelain)"
held_before="$(sha256sum "$held")"
for dirt in tracked untracked; do
  if [ "$dirt" = tracked ]; then
    dirt="an uncommitted edit to a tracked file"
    printf 'unsaved\n' >>shipments.txt
    expect "fixture: the main checkout's only change is an uncommitted edit to a tracked file" \
      test "$(g status --porcelain)" = " M shipments.txt"
  else
    dirt="a new untracked file"
    printf 'draft\n' >shipments-draft.txt
    expect "fixture: the main checkout's only change is a new file never added and not ignored" \
      test "$(g status --porcelain)" = "?? shipments-draft.txt"
  fi
  state_before="$(door_state && g worktree list --porcelain)"
  run shipments-held "$held"
  check_lines "$dirt in the main checkout refuses a landed debt/<slug> before recutting it: exit 4" \
    4 "$rc" "line=working tree has uncommitted changes; commit or stash before fix"
  same "the refusal over $dirt in the main checkout ahead of a recut prints that one line and nothing else" \
    "line=working tree has uncommitted changes; commit or stash before fix"
  expect "the landed debt/<slug> keeps its tip over $dirt in the main checkout" \
    test "$(g -C "$main" rev-parse -q --verify refs/heads/debt/shipments-held)" = "$fixer"
  expect "the landed worktree is still listed on its debt/<slug> over $dirt in the main checkout" \
    test "$(branch_of_worktree "$main" "$held_wt")" = "refs/heads/debt/shipments-held"
  expect "every ref, the working tree and the worktree list are as they were after refusing a recut over $dirt" \
    test "$(door_state && g worktree list --porcelain)" = "$state_before"
  expect "the Debt review keeps every byte, its Fixed point and Commit lines included, after refusing a recut over $dirt" \
    test "$(sha256sum "$held")" = "$held_before"
  g checkout -q -- shipments.txt
  rm -f shipments-draft.txt
done

moved="$feature/moved.debt.review.md"
printf 'pending\n' >orders.txt
commit "orders pending a fourth time"
fixed_point="$(g rev-parse refs/heads/shipments)"
fixed_short="$(g rev-parse --short refs/heads/shipments)"
printf '# Review: Shipments export\n\nSpec: %s\nFixed point: shipments (%s)\nCommit: %s\nSpec source: %s\nMode: default\nLanguage: English\n\n## Act on\n\nnone\n\n## Consider\n\nnone\n\n## Noted\n\nnone\n\n## Cleared\n\nnone\n\n## Axes\n\n' \
  "$feature/spec.md" "$fixed_short" "$fixed_short" "$feature/spec.md" >"$moved"
moved_wt="$main/.claude/worktrees/debt-shipments-moved"
elsewhere="$tmp/shipments-moved-elsewhere"
cut_with_fixer shipments-moved "$moved"
g merge -q --ff-only refs/heads/debt/shipments-moved
moved_landed="$(g rev-parse --short "$fixer")"
cat >>"$moved" <<EOF
## Fix run

Date: 2026-10-20 · at $fixed_short

- 1: fixed $moved_landed, verified (\`bash tests/shipments.test.sh\`)
- wave 1: 1
- duplication scan: skip: no test asset changed
- diff tests: \`bash tests/shipments.test.sh\`: green
- gate: \`bash tests/shipments.test.sh\`: green
- landed at $moved_landed
EOF
printf 'later a fourth time\n' >>shipments.txt
commit "after the fourth landing"
g -C "$main" worktree move "$moved_wt" "$elsewhere"
expect "fixture: debt/shipments-moved's tip is the landed sha and inside the developer's branch" \
  g -C "$main" merge-base --is-ancestor "$fixer" refs/heads/shipments
expect "fixture: nothing is left at debt/shipments-moved's worktree path under the main checkout" \
  test ! -e "$moved_wt"
expect "fixture: git lists debt/shipments-moved checked out in the worktree outside the main checkout" \
  test "$(branch_of_worktree "$main" "$elsewhere")" = "refs/heads/debt/shipments-moved"
state_before="$(door_state && g worktree list --porcelain)"
moved_before="$(sha256sum "$moved")"
run shipments-moved "$moved"
refused_once "a debt/<slug> checked out in a worktree at another path is refused with one line=: exit 3"
check_lines "the refusal over a debt/<slug> checked out elsewhere names the branch and the other worktree's path, and that nothing was cut" \
  3 "$rc" "line=debt/shipments-moved is checked out at $elsewhere; nothing cut"
expect "no folder is created at the skill's worktree path for a debt/<slug> checked out elsewhere" \
  test ! -e "$moved_wt"
expect "the debt/<slug> checked out elsewhere keeps its tip" \
  test "$(g -C "$main" rev-parse -q --verify refs/heads/debt/shipments-moved)" = "$fixer"
expect "the other worktree is still listed on its debt/<slug>" \
  test "$(branch_of_worktree "$main" "$elsewhere")" = "refs/heads/debt/shipments-moved"
expect "every ref, the working tree and the worktree list are as they were after refusing a debt/<slug> checked out elsewhere" \
  test "$(door_state && g worktree list --porcelain)" = "$state_before"
expect "the Debt review keeps every byte, its Fixed point and Commit lines included, after refusing a debt/<slug> checked out elsewhere" \
  test "$(sha256sum "$moved")" = "$moved_before"

exit "$fails"
