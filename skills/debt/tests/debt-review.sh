#!/usr/bin/env bash
# debt-review.sh: the contract of scripts/debt-review.sh, the Debt review written from the
# evaluators' returns, one per gathered item, beside the feature's Spec.
# Run: bash skills/debt/tests/debt-review.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/debt-review.sh"
gather="$here/../scripts/gather.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

fresh project
project="$tmp/project"
feature="$project/.scratch/20261019-pending-debt-review"
mkdir -p "$feature/issues" "$project/src"
printf '# Spec: pending debt review\n' >"$feature/spec.md"
printf 'retries=3\n' >"$project/src/a.sh"
cat >"$feature/issues/01-a.debt.md" <<'EOF'
## 2026-10-19 15:01

- the retry budget is hardcoded
- the cache key ignores the locale
- the error path is never logged
- the session store is read on every request
EOF
commit "seed the feature"

run() {
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check reads $out
  out="$(cd "$project" && bash "$script" "$@" 2>&1)" || rc=$?
}

source_of() { # $1 item number: its source, as gather.sh records it, on stdout
  (cd "$project" && bash "$gather" pending-debt-review 2>/dev/null) |
    awk -F'\t' -v k="item=$1" '$1 == k { sub(/^source=/, "", $2); print $2 }'
}
first="$(source_of 1)"
second="$(source_of 2)"
third="$(source_of 3)"
fourth="$(source_of 4)"
if [ -z "$first" ] || [ -z "$second" ] || [ -z "$third" ] || [ -z "$fourth" ]; then
  echo "FAIL  fixture: gather.sh named no source for items 1, 2, 3 and 4"
  exit 1
fi

returns="$tmp/returns"
mkdir -p "$returns"
cat >"$returns/item-1.md" <<EOF
Source: $first
Axis: Standards
Location: src/a.sh:1
Claim: the retry budget is hardcoded at three.
Evidence: \`retries=3\` in src/a.sh:1, walked through the retry loop.
Rung: 3
Fix: the retry budget is read from the config, in src/a.sh
Small: yes
EOF
cat >"$returns/item-2.md" <<EOF
Source: $second
Axis: Correctness
Location: src/b.sh:7
Claim: two locales share one cache entry.
Evidence: a request in fr after one in en returns the en page, run by a proof script.
Rung: 4
Fix: the cache key carries the locale, in src/b.sh
Small: yes
EOF
cat >"$returns/item-3.md" <<EOF
Source: $third
Axis: Blast radius
Location: src/c.sh:4
Claim: the error path is never logged.
Evidence: an earlier agent's note says so; no run reached the error path.
Rung: 2
Fix: the error path logs before it returns, in src/c.sh
Small: yes
EOF
cat >"$returns/item-4.md" <<EOF
Source: $fourth
Axis: Principles
Location: src/d.sh:12
Claim: every request reads the whole session store.
Evidence: a proof script timed 200 requests, each one opening the store file.
Rung: 4
Fix: the session store moves behind a cache shared by every handler, across src/
Small: no
EOF

run pending-debt-review "$returns"
review="$feature/spec.debt.review.md"
# shellcheck disable=SC2034  # lib.sh's check reads $out
out="$(grep -qx '## Consider' "$review" 2>/dev/null && passage_of "$review" "## Act on" "## Consider")"
check "a proven, small item at Rung 3 or 4 is a Finding under Act on, before Consider" 0 "$rc" \
  ". Standards at src/a.sh:1" "Claim: the retry budget is hardcoded at three." \
  ". Correctness at src/b.sh:7" "Claim: two locales share one cache entry."

# shellcheck disable=SC2034  # lib.sh's check reads $out
out="$(grep -qx '## Noted' "$review" 2>/dev/null && passage_of "$review" "## Consider" "## Noted")"
check "an unproven item at Rung 2 is a Finding under Consider, with the evaluator's own evidence" 0 "$rc" \
  ". Blast radius at src/c.sh:4" "Claim: the error path is never logged." \
  "Evidence: an earlier agent's note says so; no run reached the error path."
# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$(grep -qx '## Consider' "$review" 2>/dev/null && passage_of "$review" "## Act on" "## Consider")"
check_absent "an unproven item at Rung 2 stays out of Act on, even when small" 0 "$rc" \
  ". Blast radius at src/c.sh:4" "Claim: the error path is never logged."

# shellcheck disable=SC2034  # lib.sh's check reads $out
out="$(grep -qx '## Noted' "$review" 2>/dev/null && passage_of "$review" "## Consider" "## Noted")"
check "a proven item at Rung 3 or above whose fix is not small is a Finding under Consider" 0 "$rc" \
  ". Principles at src/d.sh:12" "Claim: every request reads the whole session store."
# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$(grep -qx '## Consider' "$review" 2>/dev/null && passage_of "$review" "## Act on" "## Consider")"
check_absent "a proven item whose fix is not small stays out of Act on" 0 "$rc" \
  ". Principles at src/d.sh:12" "Claim: every request reads the whole session store."

exit "$fails"
