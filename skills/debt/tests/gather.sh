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

open="$tmp/.scratch/20261019-open-findings"
mkdir -p "$open/issues"
printf '# Spec: open findings\n' >"$open/spec.md"
printf '## first run\n\n- the timeout is hardcoded\n' >"$open/issues/01-a.debt.md"
act_on="### 1. Correctness at src/a.sh:3
Claim: a call with no argument exits on an unbound variable.
Evidence: \`bash src/a.sh\` exits 1.
Rung: 4

### 2. Correctness at src/b.sh:4
Claim: the loop skips the last line.
Evidence: \`bash src/b.sh\` prints two of three lines.
Rung: 4

### 3. Correctness at src/c.sh:5
Claim: the exit code is lost in the pipe.
Evidence: \`bash src/c.sh\` exits 0 on a failure.
Rung: 4

### 4. Correctness at src/d.sh:6
Claim: the path is unquoted.
Evidence: a path with a space splits.
Rung: 4

### 5. Correctness at src/e.sh:7
Claim: the counter starts at one.
Evidence: \`bash src/e.sh\` reports one too many.
Rung: 4

### 6. Spec at src/f.sh:8
Claim: the flag the Spec names is ignored.
Evidence: \`bash src/f.sh --dry\` writes the file.
Rung: 4

### 7. Security at src/g.sh:9
Claim: the token is echoed to the log.
Evidence: \`bash src/g.sh\` prints the token.
Rung: 4"
two_runs="## Fix run

Date: 2026-10-19 · at 8b1d0e4

- 1: not fixed: the Fixer never returned
- 2: fixed 1a2b3c4, verified (\`bash tests/b.test.sh\`)
- 6: not fixed: the Fixer could not turn it green
- 7: fixed 1a2b3c4, verified (\`bash tests/g.test.sh\`)
- gate: \`bash tests/a.test.sh\`: green
- not landed: Finding 1, 6 not fixed

## Fix run

Date: 2026-10-20 · at 1a2b3c4

- 3: fixed 5d6e7f8, not verified
- 4: stale
- 6: fixed 5d6e7f8, verified (\`bash tests/f.test.sh\`)
- 7: not fixed: the Fixer dropped its edits
- gate: \`bash tests/a.test.sh\`: green
- not landed: Finding 3 not verified, Finding 7 not fixed"
review_at 8b1d0e4 "$open/spec.review.md" "$act_on" "$two_runs" "" "### 8. Standards at src/h.sh:2
Claim: \`echo -e\` in \`src/\`, which CLAUDE.md forbids.
Evidence: CLAUDE.md, \"use printf\".
Rung: 2"
review_at 8b1d0e4 "$open/issues/01-a.review.md"
run open-findings
check_lines "an Act on Finding whose latest Fix run line reads not fixed is one record, before its Review's Consider and Noted, in the gathered order" "$rc" "$rc" \
  "item=1${tab}source=issues/01-a.debt.md, section first run, item 1${tab}text=the timeout is hardcoded" \
  "item=2${tab}source=spec.review.md, Finding 1${tab}text=Correctness at src/a.sh:3" \
  "item=3${tab}source=spec.review.md, Finding 7${tab}text=Security at src/g.sh:9" \
  "item=4${tab}source=spec.review.md, Finding 8${tab}text=Standards at src/h.sh:2" \
  "item=5${tab}source=issues/01-a.review.md, Finding 1${tab}text=Correctness at src/a.sh:3"
check_absent "an Act on Finding whose latest line reads fixed or stale, or that has no fix line, gives no item" "$rc" "$rc" \
  "src/b.sh:4" "src/c.sh:5" "src/d.sh:6" "src/e.sh:7" "src/f.sh:8" "item=6${tab}"

entries='%p %y %s %T@\n'
before="$(snapshot "$tmp" "$entries")"
run Pending-Debt-Typo
check_lines "a slug that names no folder says so, quoting the slug as typed, and exits 3" 3 "$rc" \
  "line=no feature folder for Pending-Debt-Typo; nothing written"
expect "a slug that names no folder writes nothing in the directory it ran from" \
  test "$before" = "$(snapshot "$tmp" "$entries")"

clean="$tmp/.scratch/20261019-clean-feature"
mkdir -p "$clean/issues"
printf '# Spec: clean feature\n' >"$clean/spec.md"
printf '## 2026-10-19 15:01\n\nnone\n\n## 2026-10-20 09:00\n\nnone\n' >"$clean/issues/01-a.debt.md"
fixed_last="## Fix run

Date: 2026-10-19 · at 8b1d0e4

- 1: not fixed: the Fixer never returned
- gate: \`bash tests/a.test.sh\`: green
- not landed: Finding 1 not fixed

## Fix run

Date: 2026-10-20 · at 8b1d0e4

- 1: fixed 1a2b3c4, verified (\`bash tests/a.test.sh\`)
- gate: \`bash tests/a.test.sh\`: green
- landed at 1a2b3c4"
review_at 8b1d0e4 "$clean/spec.review.md" "" "$fixed_last" "" "none" "none" "### 2. Blast radius at src/e.sh:7, outside the diff
Claim: the caller breaks on the new argument order.
Evidence: the caller passes the path first.
Rung: 4
Refuted by: a proof script that calls src/e.sh exits 0."
review_at 8b1d0e4 "$clean/issues/01-a.review.md" "none" "$landed"
before="$(snapshot "$tmp" "$entries")"
run clean-feature
check_lines "a feature with no pending debt says so, naming its folder, and exits 1" 1 "$rc" \
  "line=no pending debt in 20261019-clean-feature; nothing judged"
check_absent "a feature with no pending debt gives no item" 1 "$rc" "item="
expect "a feature with no pending debt writes nothing in the directory it ran from" \
  test "$before" = "$(snapshot "$tmp" "$entries")"

label="a feature with debt counts its items after the slug, folder and spec lines, before the first item, and ends judging that many, exit 0"
run pending-debt-review
count="$(grep -c '^item=' <<<"$out")"
order="$(grep -oE '^(slug|folder|spec|items|item)=' <<<"$out" | uniq | tr -d = | tr '\n' ' ')"
if [ "$rc" = 0 ] && [ "$order" = "slug folder spec items item " ] && [ "$(term items)" = "$count" ] &&
  [ "$(tail -n 1 <<<"$out")" = "line=Judging $count debt items of 20261019-pending-debt-review" ]; then ok "$label"; else
  fail "$label (exit $rc, wanted 0; order: $order; items=$(term items), item records: $count)"
  dump_out
fi

label="a feature with no pending debt counts zero items before its status line"
run clean-feature
counted="$(grep -E '^(items|line)=' <<<"$out" | tr '\n' '|')"
if [ "$rc" = 1 ] && [ "$counted" = "items=0|line=no pending debt in 20261019-clean-feature; nothing judged|" ]; then ok "$label"; else
  fail "$label (exit $rc, wanted 1)"
  dump_out
fi

rerun="$tmp/.scratch/20261019-rerun-debt"
mkdir -p "$rerun/issues"
printf '# Spec: rerun debt\n' >"$rerun/spec.md"
printf '## first run\n\n- the timeout is hardcoded\n- the log path is relative\n- the lock file is never removed\n' >"$rerun/issues/01-a.debt.md"
review_at 8b1d0e4 "$rerun/spec.debt.review.md" "none" "$landed" "" "### 1. Standards at src/t.sh:2
Claim: the timeout is hardcoded.
Evidence: \`timeout=30\` in src/t.sh:2.
Rung: 2
Source: issues/01-a.debt.md, section first run, item 1" "none" "### 2. Principles at src/l.sh:8, outside the diff
Claim: the lock file is never removed.
Evidence: no trap removes \`run.lock\`.
Rung: 4
Refuted by: src/l.sh removes run.lock in its EXIT trap.
Source: issues/01-a.debt.md, section first run, item 3"
run rerun-debt
check_lines "a rerun prints only the items the Debt review holds no Finding for, numbered from 1, and judges that many, exit 0" 0 "$rc" \
  "items=1" \
  "item=1${tab}source=issues/01-a.debt.md, section first run, item 2${tab}text=the log path is relative" \
  "line=Judging 1 debt items of 20261019-rerun-debt"
check_absent "a rerun gives no item for a source a Consider or a Cleared Finding of the Debt review holds" 0 "$rc" \
  "section first run, item 1" "section first run, item 3" "item=2${tab}"

moved="$tmp/.scratch/20261019-moved-debt"
mkdir -p "$moved/issues"
printf '# Spec: moved debt\n' >"$moved/spec.md"
printf '## first run\n\n- the timeout is hardcoded\n- the log path is relative\n- the lock file is never removed\n- the port is fixed\n' >"$moved/issues/01-a.debt.md"
review_at 8b1d0e4 "$moved/spec.debt.review.md" "### 3. Principles at src/l.sh:8
Claim: the lock file is never removed.
Evidence: no trap removes \`run.lock\`.
Rung: 2
Fix: an EXIT trap removes run.lock, in src/l.sh
Source: issues/01-a.debt.md, section first run, item 3

### 1. Standards at src/t.sh:2
Claim: the timeout is hardcoded.
Evidence: \`timeout=30\` in src/t.sh:2.
Rung: 2
Fix: the timeout is read from the config, in src/t.sh
Source: issues/01-a.debt.md, section first run, item 1" "$landed" "" "none" "none" "### 2. Principles at src/p.sh:4
Claim: the log path is relative.
Evidence: \`log=run.log\` in src/p.sh:4.
Rung: 2
Fix: the log path is resolved against the run directory, in src/p.sh
Source: issues/01-a.debt.md, section first run, item 2"
run moved-debt
check_lines "a rerun prints only the items no Finding holds, wherever the developer moved a Finding, and judges that many, exit 0" 0 "$rc" \
  "items=1" \
  "item=1${tab}source=issues/01-a.debt.md, section first run, item 4${tab}text=the port is fixed" \
  "line=Judging 1 debt items of 20261019-moved-debt"
check_absent "a rerun gives no item for a Finding moved from Act on to Cleared or from Consider to Act on" 0 "$rc" \
  "section first run, item 2" "section first run, item 3" "item=2${tab}"

deleted="$tmp/.scratch/20261019-deleted-debt"
mkdir -p "$deleted/issues"
printf '# Spec: deleted debt\n' >"$deleted/spec.md"
printf '## first run\n\n- the timeout is hardcoded\n- the log path is relative\n- the lock file is never removed\n- the port is fixed\n' >"$deleted/issues/01-a.debt.md"
review_at 8b1d0e4 "$deleted/spec.debt.review.md" "### 1. Standards at src/t.sh:2
Claim: the timeout is hardcoded.
Evidence: \`timeout=30\` in src/t.sh:2.
Rung: 2
Fix: the timeout is read from the config, in src/t.sh
Source: issues/01-a.debt.md, section first run, item 1

### 3. Principles at src/l.sh:8
Claim: the lock file is never removed.
Evidence: no trap removes \`run.lock\`.
Rung: 2
Fix: an EXIT trap removes run.lock, in src/l.sh
Source: issues/01-a.debt.md, section first run, item 3" "$landed" "" "### 4. Standards at src/n.sh:3
Claim: the port is fixed.
Evidence: \`port=8080\` in src/n.sh:3.
Rung: 3
Source: issues/01-a.debt.md, section first run, item 4"
run deleted-debt
check_lines "a Finding deleted from the Debt review is gathered again as a new item and judged on the next run, exit 0" 0 "$rc" \
  "items=1" \
  "item=1${tab}source=issues/01-a.debt.md, section first run, item 2${tab}text=the log path is relative" \
  "line=Judging 1 debt items of 20261019-deleted-debt"
check_absent "a rerun after a Finding was deleted still gives no item for a source the remaining Findings hold" 0 "$rc" \
  "section first run, item 1" "section first run, item 3" "section first run, item 4" "item=2${tab}"

held="$tmp/.scratch/20261019-held-debt"
mkdir -p "$held/issues"
printf '# Spec: held debt\n' >"$held/spec.md"
printf '## first run\n\n- the timeout is hardcoded\n- the log path is relative\n- the lock file is never removed\n' >"$held/issues/01-a.debt.md"
review_at 8b1d0e4 "$held/spec.debt.review.md" "none" "$landed" "" "### 1. Standards at src/t.sh:2
Claim: the timeout is hardcoded.
Evidence: \`timeout=30\` in src/t.sh:2.
Rung: 2
Source: issues/01-a.debt.md, section first run, item 1" "### 2. Principles at src/p.sh:4
Claim: the log path is relative.
Evidence: \`log=run.log\` in src/p.sh:4.
Rung: 2
Source: issues/01-a.debt.md, section first run, item 2" "### 3. Principles at src/l.sh:8, outside the diff
Claim: the lock file is never removed.
Evidence: no trap removes \`run.lock\`.
Rung: 4
Refuted by: src/l.sh removes run.lock in its EXIT trap.
Source: issues/01-a.debt.md, section first run, item 3"
run held-debt
check_lines "a rerun whose every gathered source the Debt review holds names the Debt review, counts zero items and exits 5" 5 "$rc" \
  "review=$held/spec.debt.review.md" "items=0"
expect "a rerun whose every gathered source the Debt review holds prints slug, folder, spec, review and items, and no status line or item" \
  test "$(keys_in_order)" = "slug folder spec review items "

judged="$tmp/.scratch/20261019-judged-empty"
mkdir -p "$judged"
printf '# Spec: judged empty\n' >"$judged/spec.md"
review_at 8b1d0e4 "$judged/spec.debt.review.md" "none" "$landed"
run judged-empty
check_lines "a rerun that gathers nothing beside an existing Debt review names it, counts zero items and exits 5" 5 "$rc" \
  "review=$judged/spec.debt.review.md" "items=0"
expect "a rerun that gathers nothing beside an existing Debt review prints slug, folder, spec, review and items, and no status line or item" \
  test "$(keys_in_order)" = "slug folder spec review items "

fresh detached
mkdir -p .scratch/20261019-detached-debt/issues
printf '# Spec: detached debt\n' >.scratch/20261019-detached-debt/spec.md
printf '## first run\n\n- the timeout is hardcoded\n' >.scratch/20261019-detached-debt/issues/01-a.debt.md
commit "a feature folder holding debt"
g checkout -q --detach
before="$(door_state)"
rc=0
out="$(bash "$script" detached-debt 2>&1)" || rc=$?
check_lines "a feature folder in a checkout on a detached HEAD is refused, naming the slug as typed, and exits 4" 4 "$rc" \
  "line=the checkout is on a detached HEAD; switch to the branch the fixes should land on and run /debt detached-debt again; nothing written"
check_absent "a feature folder in a checkout on a detached HEAD gives no item" 4 "$rc" "item="
expect "a feature folder in a checkout on a detached HEAD leaves every ref and the working tree as they were" \
  test "$(door_state)" = "$before"

exit "$fails"
