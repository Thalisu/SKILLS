#!/usr/bin/env bash
# gather.sh: the contract of scripts/gather.sh, the pending debt of one feature folder, named by
# its slug the way /debt is typed. Run: bash skills/debt/tests/gather.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/gather.sh"
resolve="$here/../../../.agents/scripts/resolve-feature-folder.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

run() {
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines reads $out
  out="$(cd "$tmp" && bash "$script" "$@" 2>&1)" || rc=$?
}

mkdir -p "$tmp/.scratch/20261019-pending-debt-review/issues"
printf '# Spec: pending debt review\n' >"$tmp/.scratch/20261019-pending-debt-review/spec.md"

want="$(cd "$tmp" && bash "$resolve" pending-debt-review | sed -n 's/^folder=//p')"
if [ -z "$want" ] || [ "$want" = none ]; then
  echo "FAIL  fixture: the resolver named no folder for pending-debt-review"
  exit 1
fi

# The exit code of a feature with or without debt belongs to later cases, so these accept any.
run pending-debt-review
check_lines "a bare slug gathers the folder the resolver names" "$rc" "$rc" "folder=$want"

run 20261019-pending-debt-review
check_lines "the dated folder name gathers the same folder as the bare slug" "$rc" "$rc" "folder=$want"

issues="$tmp/.scratch/20261019-pending-debt-review/issues"
cat >"$issues/01-a.debt.md" <<'EOF'
## 2026-10-19 15:01

- the retry budget is hardcoded
- the cache key ignores the locale
  when the request carries one
  - seen only on the fallback path

## 2026-10-20 09:00

none
EOF
cat >"$issues/02-b.debt.md" <<'EOF'
## second run

The fixture builder duplicates the
seeding done by the migration.
EOF
tab=$'\t'
run pending-debt-review
check_lines "each Debt item is one record numbered in file order, its source naming the file, section and bullet" "$rc" "$rc" \
  "item=1${tab}source=issues/01-a.debt.md, section 2026-10-19 15:01, item 1${tab}text=the retry budget is hardcoded" \
  "item=2${tab}source=issues/01-a.debt.md, section 2026-10-19 15:01, item 2${tab}text=the cache key ignores the locale when the request carries one - seen only on the fallback path" \
  "item=3${tab}source=issues/02-b.debt.md, section second run, item 1${tab}text=The fixture builder duplicates the seeding done by the migration."
check_absent "a section reading none gives no Debt item" "$rc" "$rc" "section 2026-10-20 09:00" "item=4${tab}"

feature="$tmp/.scratch/20261019-pending-debt-review"
landed="## Fix run

Date: 2026-10-19 · at 8b1d0e4

- gate fixer: not needed
- gate: \`bash tests/a.test.sh\`: green
- landed at 8b1d0e4"
review_at 8b1d0e4 "$feature/spec.review.md" "none" "$landed" "" "### 1. Standards at src/c.sh:12
Claim: \`echo -e\` in \`src/\`, which CLAUDE.md forbids.
Evidence: CLAUDE.md, \"use printf\".
Rung: 2
Fix: the script writes through printf, in src/c.sh" "### 2. Principles at src/d.sh:5
Claim: the parser and the printer share one function.
Evidence: \`render\` both splits the line and formats it.
Rung: 2" "### 3. Blast radius at src/e.sh:7, outside the diff
Claim: the caller breaks on the new argument order.
Evidence: the caller passes the path first.
Rung: 4
Refuted by: a proof script that calls src/e.sh exits 0."
review_at 8b1d0e4 "$feature/spec.security.review.md" "none" "$landed" "" "### 1. Correctness at src/f.sh:2
Claim: the token is compared with a plain string match.
Evidence: \`[ \"\$t\" = \"\$want\" ]\` in src/f.sh:2.
Rung: 2
Fix: the token is compared in constant time, in src/f.sh"
review_at 8b1d0e4 "$feature/spec.debt.review.md" "none" "$landed" "" "### 1. Standards at src/g.sh:4
Claim: the retry budget is hardcoded.
Evidence: \`retries=3\` in src/g.sh:4.
Rung: 2
Fix: the retry budget is read from the config, in src/g.sh
Source: issues/01-a.debt.md, item 1"
review_at 8b1d0e4 "$issues/01-a.review.md" "none" "$landed" "" "none" "### 1. Principles at src/h.sh:9
Claim: the loader reads the file twice.
Evidence: \`load\` opens the file for its size and again for its lines.
Rung: 2"
run pending-debt-review
check_lines "each Consider and Noted Finding of a Review is one record after the Debt items, the Spec's Reviews by name then the Tickets', in file order" "$rc" "$rc" \
  "item=4${tab}source=spec.review.md, Finding 1${tab}text=Standards at src/c.sh:12" \
  "item=5${tab}source=spec.review.md, Finding 2${tab}text=Principles at src/d.sh:5" \
  "item=6${tab}source=spec.security.review.md, Finding 1${tab}text=Correctness at src/f.sh:2" \
  "item=7${tab}source=issues/01-a.review.md, Finding 1${tab}text=Principles at src/h.sh:9"
check_absent "a Cleared Finding, an empty Bucket and the Debt review's own Findings give no item" "$rc" "$rc" \
  "Blast radius at src/e.sh:7" "text=none" "source=spec.debt.review.md" "Standards at src/g.sh:4"

entries='%p %y %s %T@\n'
before="$(snapshot "$tmp" "$entries")"
run Pending-Debt-Typo
check_lines "a slug that names no folder says so, quoting the slug as typed, and exits 3" 3 "$rc" \
  "line=no feature folder for Pending-Debt-Typo; nothing written"
expect "a slug that names no folder writes nothing in the directory it ran from" \
  test "$before" = "$(snapshot "$tmp" "$entries")"

exit "$fails"
