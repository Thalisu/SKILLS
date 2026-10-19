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

fresh traced
traced="$(pwd -P)"
traced_feature="$traced/.scratch/20261019-traced-debt"
mkdir -p "$traced_feature/issues" "$traced/src"
printf '# Spec: traced debt\n' >"$traced_feature/spec.md"
printf 'retries=3\n' >"$traced/src/a.sh"
cat >"$traced_feature/issues/01-a.debt.md" <<'EOF'
## 2026-10-19 15:01

- the retry budget is hardcoded
- the cache key ignores the locale
EOF
review_at 8b1d0e4 "$traced_feature/spec.review.md" "none" "## Fix run

Date: 2026-10-19 · at 8b1d0e4

- gate fixer: not needed
- gate: \`bash tests/a.test.sh\`: green
- landed at 8b1d0e4" "" "### 1. Standards at src/c.sh:12
Claim: \`echo -e\` in \`src/\`, which CLAUDE.md forbids.
Evidence: CLAUDE.md, \"use printf\".
Rung: 2
Fix: the script writes through printf, in src/c.sh"
commit "seed the traced feature"

gathered_sources="$(cd "$traced" && bash "$gather" traced-debt 2>/dev/null |
  awk -F'\t' '/^item=/ { sub(/^source=/, "", $2); print $2 }')"
if [ "$(wc -l <<<"$gathered_sources")" != 3 ] || ! grep -qx 'spec.review.md, Finding 1' <<<"$gathered_sources"; then
  echo "FAIL  fixture: gather.sh did not name two Debt items and the Review's Finding 1"
  exit 1
fi
traced_returns="$tmp/traced-returns"
mkdir -p "$traced_returns"
cat >"$traced_returns/item-1.md" <<EOF
Source: $(sed -n 1p <<<"$gathered_sources")
Axis: Standards
Location: src/a.sh:1
Claim: the retry budget is hardcoded at three.
Evidence: \`retries=3\` in src/a.sh:1, walked through the retry loop.
Rung: 3
Fix: the retry budget is read from the config, in src/a.sh
Small: yes
EOF
cat >"$traced_returns/item-3.md" <<EOF
Source: $(sed -n 3p <<<"$gathered_sources")
Axis: Standards
Location: src/c.sh:12
Claim: \`echo -e\` writes the output, which CLAUDE.md forbids.
Evidence: the earlier Review's quote of CLAUDE.md; no run printed through it.
Rung: 2
Fix: the script writes through printf, in src/c.sh
Small: yes
EOF

finding_sources() { # $1 review: each Finding's Source: values joined on one line, one line per Finding, sorted
  awk '
    function flush() { if (on) print srcs; on = 0; srcs = "" }
    /^### [0-9]+\./ { flush(); on = 1; next }
    /^## / { flush(); next }
    on && /^Source: / { v = substr($0, 9); srcs = (srcs == "" ? v : srcs " | " v) }
    END { flush() }
  ' "$1" | LC_ALL=C sort
}
traced_review="$traced_feature/spec.debt.review.md"
for where in "the project root:" "a subdirectory:src"; do
  label="${where%%:*}"
  rm -f "$traced_review"
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines reads $out
  out="$(cd "$traced/${where#*:}" && bash "$script" traced-debt "$traced_returns" 2>&1)" || rc=$?
  check_lines "run from $label, it prints the path of the Debt review beside the Spec" 0 "$rc" \
    "review=$traced_review" "line=Written to $traced_review"
  expect "run from $label, the Debt review exists beside the Spec" test -f "$traced_review"
  # shellcheck disable=SC2034  # lib.sh's same reads $out
  out="$(finding_sources "$traced_review" 2>&1)"
  same "run from $label, every Finding carries one Source equal to its gathered item's, one per item" \
    "$(LC_ALL=C sort <<<"$gathered_sources")"
done

fresh shaped
shaped="$(pwd -P)"
spread_feature="$shaped/.scratch/20261019-spread-debt"
consider_feature="$shaped/.scratch/20261019-consider-debt"
mkdir -p "$spread_feature/issues" "$consider_feature/issues"
printf '# Notes export\n\nExport the notes as CSV.\n' >"$spread_feature/spec.md"
printf '# Session cache\n\nCache the session store.\n' >"$consider_feature/spec.md"
cat >"$spread_feature/issues/01-a.debt.md" <<'EOF'
## 2026-10-19 15:01

- a page of ten notes returns nine
- the export prints through echo -e
- the CSV writer is copied in two modules
EOF
cat >"$consider_feature/issues/01-a.debt.md" <<'EOF'
## 2026-10-19 15:01

- the session store hides its own cache
- every request reads the whole session store
EOF
commit "seed the shaped features"
shaped_sha="$(g rev-parse --short HEAD)"

shaped_sources() { # $1 slug: the sources gather.sh records for its items, in their order, one per line, on stdout
  (cd "$shaped" && bash "$gather" "$1" 2>/dev/null) |
    awk -F'\t' '/^item=/ { sub(/^source=/, "", $2); print $2 }'
}
spread_sources="$(shaped_sources spread-debt)"
consider_sources="$(shaped_sources consider-debt)"
if [ "$(grep -c . <<<"$spread_sources")" != 3 ] || [ "$(grep -c . <<<"$consider_sources")" != 2 ]; then
  echo "FAIL  fixture: gather.sh did not name three items for spread-debt and two for consider-debt"
  exit 1
fi
spread_returns="$tmp/spread-returns"
consider_returns="$tmp/consider-returns"
mkdir -p "$spread_returns" "$consider_returns"
cat >"$spread_returns/item-1.md" <<EOF
Source: $(sed -n 1p <<<"$spread_sources")
Axis: Correctness
Location: src/notes.sh:31
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, a page of ten asked for; nine rows came back, run by a proof script.
Rung: 4
Fix: a page of ten over eleven notes returns ten rows, in src/notes.sh
Small: yes
EOF
cat >"$spread_returns/item-2.md" <<EOF
Source: $(sed -n 2p <<<"$spread_sources")
Axis: Standards
Location: src/export.sh:12
Claim: the export prints through \`echo -e\`, which CLAUDE.md forbids.
Evidence: CLAUDE.md, "use printf"; src/export.sh:12.
Rung: 2
Fix: the export prints through printf, in src/export.sh
Small: yes
EOF
cat >"$spread_returns/item-3.md" <<EOF
Source: $(sed -n 3p <<<"$spread_sources")
Axis: Standards
Location: src/csv.sh:4
Claim: the CSV writer is copied in two modules.
Evidence: src/csv.sh:4 and src/report.sh:9 hold the same writer, walked line by line.
Rung: 3
Fix: one CSV writer serves both modules, across src/
Small: no
EOF
cat >"$consider_returns/item-1.md" <<EOF
Source: $(sed -n 1p <<<"$consider_sources")
Axis: Principles
Location: src/session.sh:3
Claim: the session store hides its own cache.
Evidence: deep modules, the cache leaks through the store's signature at src/session.sh:3.
Rung: 2
Fix: the store keeps its cache behind its own interface, in src/session.sh
Small: yes
EOF
cat >"$consider_returns/item-2.md" <<EOF
Source: $(sed -n 2p <<<"$consider_sources")
Axis: Principles
Location: src/session.sh:12
Claim: every request reads the whole session store.
Evidence: a proof script timed 200 requests, each one opening the store file.
Rung: 4
Fix: the session store moves behind a cache shared by every handler, across src/
Small: no
EOF

under() { # $1 file, $2 a heading line: the first non-blank line under it, on stdout
  awk -v h="$2" 'on && NF { print; exit } $0 == h { on = 1 }' "$1"
}
spec_named() { # $1 the value of a Spec: line, $2 the Spec's absolute path: success when the value names that file, absolute or from the project root
  case "$1" in
    /*) [ "$1" = "$2" ] ;;
    *) [ "$shaped/$1" = "$2" ] ;;
  esac
}
shaped_review() { # $1 label, $2 slug, $3 returns dir, $4 feature folder, $5 the Spec's title, $6 the Finding numbers wanted, space-separated, $7 the six Axes lines wanted
  local label="$1" feature="$4" review="$4/spec.debt.review.md" spec_line bucket
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check reads $out
  out="$(cd "$shaped" && bash "$script" "$2" "$3" 2>&1)" || rc=$?
  check "$label: the run writes the Debt review" 0 "$rc" "review=$review"

  # shellcheck disable=SC2034  # lib.sh's same reads $out
  out="$(awk '/^## / { exit } NF' "$review" 2>/dev/null | sed -n '1p;3p')"
  same "$label: it opens on # Review: and the Spec's title, its Fixed point the branch and its short sha" \
    "# Review: $5
Fixed point: main ($shaped_sha)"
  spec_line="$(awk '/^## / { exit } NF' "$review" 2>/dev/null | sed -n 2p)"
  expect "$label: the header's first line is Spec: with the Spec's path, never Ticket:" \
    spec_named "${spec_line#Spec: }" "$feature/spec.md"
  expect "$label: the header's first line opens on Spec:" grep -q '^Spec: ' <<<"$spec_line"

  # shellcheck disable=SC2034  # lib.sh's same reads $out
  out="$(
    grep -xE '## (Act on|Consider|Noted|Cleared|Axes)' "$review" 2>/dev/null
    grep '^## ' "$review" 2>/dev/null | tail -n 1
  )"
  same "$label: the Buckets read Act on, Consider, Noted, Cleared in that order, and ## Axes ends the review" \
    "## Act on
## Consider
## Noted
## Cleared
## Axes
## Axes"

  for bucket in "## Noted" "## Cleared"; do
    # shellcheck disable=SC2034  # lib.sh's same reads $out
    out="$(under "$review" "$bucket" 2>/dev/null)"
    same "$label: the empty Bucket $bucket reads none on the line under it" "none"
  done

  # shellcheck disable=SC2034  # lib.sh's same reads $out
  out="$(sed -n 's/^### \([0-9]*\)\. .*/\1/p' "$review" 2>/dev/null | tr '\n' ' ' | sed 's/ $//')"
  same "$label: the Findings are numbered from 1 in reading order, with no gap and no repeat" "$6"

  # shellcheck disable=SC2034  # lib.sh's same reads $out
  out="$(passage_of "$review" "## Axes" "## " 2>/dev/null | grep '^- ')"
  same "$label: ## Axes holds the six Axes in order, each its count and worst Finding or 0 findings, never not run" "$7"
}

shaped_review "Findings in both Buckets over two Axes" spread-debt "$spread_returns" "$spread_feature" \
  "Notes export" "1 2 3" "- Correctness: 1 finding, worst #1 (Act on)
- Spec: 0 findings
- Standards: 2 findings, worst #2 (Consider)
- Principles: 0 findings
- Blast radius: 0 findings
- Security: 0 findings"

shaped_review "every item under Consider" consider-debt "$consider_returns" "$consider_feature" \
  "Session cache" "1 2" "- Correctness: 0 findings
- Spec: 0 findings
- Standards: 0 findings
- Principles: 2 findings, worst #1 (Consider)
- Blast radius: 0 findings
- Security: 0 findings"
# shellcheck disable=SC2034  # lib.sh's same reads $out
out="$(under "$consider_feature/spec.debt.review.md" "## Act on" 2>/dev/null)"
same "every item under Consider: the empty Act on reads none on the line under it" "none"

fresh idle
idle="$(pwd -P)"
mkdir -p "$idle/.scratch/20261019-idle-feature"
printf '# Spec: idle feature\n' >"$idle/.scratch/20261019-idle-feature/spec.md"
commit "seed the idle feature"
idle_returns="$tmp/idle-returns"
mkdir -p "$idle_returns"
for refusal in "idle-feature:1:line=no pending debt in 20261019-idle-feature; nothing judged" \
  "Idle-Feature-Typo:3:line=no feature folder for Idle-Feature-Typo; nothing written"; do
  slug="${refusal%%:*}"
  want="${refusal#*:}"
  want_rc="${want%%:*}"
  want="${want#*:}"
  before="$(g -C "$idle" status --porcelain)"
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines reads $out
  out="$(cd "$idle" && bash "$script" "$slug" "$idle_returns" 2>&1)" || rc=$?
  check_lines "slug $slug: it relays gather's line and its exit $want_rc" "$want_rc" "$rc" "$want"
  expect "slug $slug: it writes no file in the project" test "$before" = "$(g -C "$idle" status --porcelain)"
done

exit "$fails"
