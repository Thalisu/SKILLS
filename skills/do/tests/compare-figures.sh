#!/usr/bin/env bash
# compare-figures.sh: the contract of skills/do/evals/compare/figures.sh, which reads one run-eval
# work folder and prints the run line the comparison's verdict reads.
# Run: bash skills/do/tests/compare-figures.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../evals/compare/figures.sh"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

work_folder() { # $1 case: a new folder named the way run-eval's mktemp names one, its path on stdout
  mktemp -d "$tmp/run-eval-$1.XXXXXX"
}
carries() { # $1 label, $2 work folder, $3.. key=value tokens its run line must carry, each as a whole token
  local label="$1" folder="$2" errfile err missing="" want
  shift 2
  errfile="$(mktemp)"
  rc=0
  out="$(bash "$script" "$folder" 2>"$errfile")" || rc=$?
  err="$(cat "$errfile")"
  rm -f "$errfile"
  for want in "$@"; do
    tr ' ' '\n' <<<"$out" | grep -qxF -- "$want" || missing="$missing $want"
  done
  if [ "$rc" = 0 ] && [ -z "$missing" ]; then ok "$label"; else
    fail "$label (exit $rc, wanted 0; missing:${missing:- nothing})"
    dump_out
    [ -n "$err" ] && echo "      stderr: ${err//$'\n'/$'\n'      }"
  fi
}

priced="$(work_folder adds-a-seam)"
cat >"$priced/transcript.jsonl" <<'EOF'
{"type":"system","subtype":"init","session_id":"s1","model":"claude-opus"}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"Building."}]}}
{"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"t1","content":"ok"}]}}
{"type":"result","subtype":"success","result":"done","total_cost_usd":4.12}
EOF
carries "a run's cost is the total_cost_usd of its result event" "$priced" cost_usd=4.12

unpriced="$(work_folder renames-a-field)"
cat >"$unpriced/transcript.jsonl" <<'EOF'
{"type":"system","subtype":"init","session_id":"s2","model":"claude-opus"}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"Building."}]}}
{"type":"result","subtype":"success","result":"done"}
EOF
carries "a result event without total_cost_usd reads as an absent cost, never as zero" "$unpriced" cost_usd=absent

unfinished="$(work_folder adds-a-seam)"
cat >"$unfinished/transcript.jsonl" <<'EOF'
{"type":"system","subtype":"init","session_id":"s3","model":"claude-opus"}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"Building."}]}}
{"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"t1","content":"ok"}]}}
EOF
carries "a transcript with no result event reads as an absent cost, never as zero" "$unfinished" cost_usd=absent

untranscribed="$(work_folder renames-a-field)"
carries "a work folder with no transcript reads as an absent cost, never as zero" "$untranscribed" cost_usd=absent

review_of() { # $1 work folder, $2 its case: the path the case's Review is written at, its directory created
  mkdir -p "$1/fixture/.scratch/$2"
  echo "$1/fixture/.scratch/$2/spec.review.md"
}

settled="$(work_folder adds-a-seam)"
review_at 8b1d0e4 "$(review_of "$settled" adds-a-seam)" "### 1. Correctness at src/notes.js:31
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, \`page(1, 10)\` called; nine rows returned.
Rung: 4
Fix: a page of size ten over eleven notes returns ten rows, in tests/notes.test.js

### 2. Correctness at src/export.js:18
Claim: an empty note list exports no header line.
Evidence: \`exportCsv([])\` returns an empty string.
Rung: 4
Fix: an empty note list exports the header line alone, in tests/export.test.js" "## Fix run

Date: 2026-09-24 · at 8b1d0e4

- 1: fixed 4c07ab2, verified (\`node --test tests/notes.test.js\`)
- 2: fixed 5d18bc3, verified (\`node --test tests/export.test.js\`)
- wave 1: 1, 2
- duplication scan: \`bash .claude/testing-policy/scan-test-assets.sh\`: clean
- diff tests: \`node --test tests\`: 4 passing
- gate fixer: not needed
- gate: \`npm test\`: green
- landed at 5d18bc3" "" "### 3. Standards at src/export.js:12
Claim: \`console.log\` in \`src/\`, which CLAUDE.md forbids.
Evidence: CLAUDE.md, \"Never \`console.log\` in \`src/\`\".
Rung: 2
Fix: the export writes through \`log()\`, in src/export.js"
carries "every Act on Finding counts, the ones its fix run settled included, and no Consider Finding does" \
  "$settled" review=present act_on=2

clean="$(work_folder renames-a-field)"
review_at 8b1d0e4 "$(review_of "$clean" renames-a-field)" "none" "## Fix run

Date: 2026-09-24 · at 8b1d0e4

- nothing remained
- duplication scan: skip: no Fixer commit
- diff tests: skip: no Fixer commit
- gate fixer: not needed
- gate: \`npm test\`: green
- landed at 8b1d0e4" "" "### 1. Standards at src/export.js:12
Claim: \`console.log\` in \`src/\`, which CLAUDE.md forbids.
Evidence: CLAUDE.md, \"Never \`console.log\` in \`src/\`\".
Rung: 2
Fix: the export writes through \`log()\`, in src/export.js"
carries "an Act on section reading none counts zero, whatever sits under Consider" "$clean" review=present act_on=0

unreviewed="$(work_folder adds-a-seam)"
carries "a case whose Review was never written reads its count as absent, never as zero" \
  "$unreviewed" review=absent act_on=absent

[ "$fails" = 0 ]
