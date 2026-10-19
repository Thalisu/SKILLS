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
- the config path is resolved twice
- the temp dir is never removed
- the log level is fixed at debug
- the lock file outlives the process
- the queue drops a message on restart
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
fifth="$(source_of 5)"
sixth="$(source_of 6)"
seventh="$(source_of 7)"
eighth="$(source_of 8)"
ninth="$(source_of 9)"
if [ -z "$first" ] || [ -z "$second" ] || [ -z "$third" ] || [ -z "$fourth" ] || [ -z "$fifth" ] || [ -z "$sixth" ] ||
  [ -z "$seventh" ] || [ -z "$eighth" ] || [ -z "$ninth" ]; then
  echo "FAIL  fixture: gather.sh named no source for items 1 to 9"
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
: >"$returns/item-6.md"
cat >"$returns/item-7.md" <<EOF
Source: $first
Axis: Standards
Location: src/e.sh:2
Claim: the log level is pinned to debug in production.
Evidence: a proof script started the service and read debug lines from its log.
Rung: 4
Fix: the log level is read from the environment, in src/e.sh
Small: yes
EOF
cat >"$returns/item-8.md" <<EOF
## Finding
Source: $eighth
Axis: Correctness
Location: src/f.sh:9
Claim: a killed process leaves its lock file behind.
Evidence: a proof script killed the process and found the lock file still on disk.
Rung: 4
Fix: the lock file is removed by an exit trap, in src/f.sh
Small: yes
EOF
cat >"$returns/item-9.md" <<EOF
Source: $ninth
Axis: Correctness
Location: src/g.sh:5
Claim: a restart loses the message in flight.
Evidence: a proof script restarted the worker mid-message and the message never arrived.
Rung: 4
Small: yes
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

consider_item() { # $1 a fixed string the Finding carries: that Finding of the Consider passage, on stdout
  grep -qx '## Noted' "$review" 2>/dev/null &&
    item_holding <(passage_of "$review" "## Consider" "## Noted") '### [0-9]+\.' "$1"
}
# shellcheck disable=SC2034  # lib.sh's check_lines reads $out
out="$(consider_item "Claim: the config path is resolved twice")"
check_lines "an item whose evaluator wrote no return is a Finding under Consider, marked unjudged" 0 "$rc" \
  "Claim: the config path is resolved twice" "Evidence: the evaluator did not return" "Rung: 1" \
  "Source: $fifth"
# shellcheck disable=SC2034  # lib.sh's check_lines reads $out
out="$(consider_item "Claim: the temp dir is never removed")"
check_lines "an item whose evaluator wrote an empty return is a Finding under Consider, marked unjudged" 0 "$rc" \
  "Claim: the temp dir is never removed" "Evidence: the evaluator did not return" "Rung: 1" \
  "Source: $sixth"
# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$(grep -qx '## Consider' "$review" 2>/dev/null && passage_of "$review" "## Act on" "## Consider")"
check_absent "an item the evaluator did not return stays out of Act on" 0 "$rc" \
  "the config path is resolved twice" "the temp dir is never removed"

# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$(grep -qx '## Consider' "$review" 2>/dev/null && passage_of "$review" "## Act on" "## Consider")"
check_absent "a return outside the shape stays out of Act on, at Rung 4 and small" 0 "$rc" \
  "the log level is pinned to debug in production." \
  "a killed process leaves its lock file behind." \
  "a restart loses the message in flight."
# shellcheck disable=SC2034  # lib.sh's check_lines reads $out
out="$(consider_item "Claim: the log level is fixed at debug")"
check_lines "a return whose Source names another item is a Finding under Consider, marked outside the shape" 0 "$rc" \
  "Claim: the log level is fixed at debug" "Evidence: the evaluator returned outside the shape" "Rung: 1" \
  "Source: $seventh"
# shellcheck disable=SC2034  # lib.sh's check_lines reads $out
out="$(consider_item "Claim: the lock file outlives the process")"
check_lines "a return carrying a line outside the shape is a Finding under Consider, marked outside the shape" 0 "$rc" \
  "Claim: the lock file outlives the process" "Evidence: the evaluator returned outside the shape" "Rung: 1" \
  "Source: $eighth"
# shellcheck disable=SC2034  # lib.sh's check_lines reads $out
out="$(consider_item "Claim: the queue drops a message on restart")"
check_lines "a return missing its Fix line is a Finding under Consider, marked outside the shape" 0 "$rc" \
  "Claim: the queue drops a message on restart" "Evidence: the evaluator returned outside the shape" "Rung: 1" \
  "Source: $ninth"

exit "$fails"
