#!/usr/bin/env bash
# evals.sh: runs every eval case's scaffold in a throwaway directory and asserts the fixture the
# case relies on, since the eval runner is gated on this machine and a case whose fixture drifted
# would grade nothing. The planted defects are in place, the suite is green around them, the
# caller outside the diff breaks, and the door script reads the facts each case expects.
# Run: bash skills/do-code-review/tests/evals.sh
# shellcheck disable=SC2016
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
skill="$here/.."
door="$skill/scripts/fixed-point.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

expect() { # $1 label, $2.. a command that must succeed
  local label="$1"; shift
  if "$@"; then echo "ok    $label"; else echo "FAIL  $label"; fails=$((fails + 1)); fi
}
quiet() { "$@" >/dev/null 2>&1; }
check() { # $1 label, $2 expected exit, $3 actual exit, $4.. lines that must appear (fixed strings); output in $out
  local label="$1" want="$2" rc="$3"; shift 3
  local ok=1 line
  [ "$rc" = "$want" ] || ok=0
  for line in "$@"; do grep -qF -- "$line" <<<"$out" || ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else
    echo "FAIL  $label (exit $rc, wanted $want)"; echo "      ${out//$'\n'/$'\n'      }"; fails=$((fails + 1)); fi
}
run_door() { rc=0; out="$(bash "$door" "$@" 2>&1)" || rc=$?; }
scaffold() { # $1 case: the scaffold_script block of its case file, run in a fresh directory that becomes the cwd
  awk '/^  scaffold_script: \|/ { f = 1; next } f && /^    / { sub(/^    /, ""); print; next } f && /^[[:space:]]*$/ { print ""; next } f { exit }' \
    "$skill/evals/$1/case.yaml" > "$tmp/$1.sh"
  mkdir -p "$tmp/$1" && cd "$tmp/$1" || exit 1
  bash "$tmp/$1.sh" >"$tmp/$1.log" 2>&1
}

# planted-diff: five defects and a clean hunk on export-notes, the spec beside the diff.
expect "planted-diff scaffold runs" scaffold planted-diff
expect "the branch is export-notes" test "$(git branch --show-current)" = export-notes
expect "the tree is clean" test -z "$(git status --porcelain)"
expect "the suite is green around the defects" quiet node --test tests/
expect "the diff touches the planted files" bash -c 'git diff --name-only main | grep -qx src/notes.js && git diff --name-only main | grep -qx src/export.js && git diff --name-only main | grep -qx src/csv.js'
expect "correctness: a page returns one item short" quiet node -e 'const { page } = require("./src/notes"); process.exit(page(1, 10, [...Array(11).keys()]).length === 9 ? 0 : 1)'
expect "correctness: an export of eleven notes has ten rows" quiet node -e 'const n = require("./src/notes"); for (let i = 0; i < 11; i++) n.create("n" + i); const rows = require("./src/export").toCsv().split("\n"); process.exit(rows.length === 10 ? 0 : 1)'
expect "spec: the export has no header line" quiet node -e 'const n = require("./src/notes"); n.create("a"); process.exit(require("./src/export").toCsv().split("\n")[0] === "id,title" ? 1 : 0)'
expect "spec: the spec asks for the header line" grep -q 'header line `id,title`' .scratch/export-notes/spec.md
expect "standards: console.log sits in src/ against the documented rule" bash -c 'grep -q "console.log" src/export.js && grep -q "Never \`console.log\`" CLAUDE.md'
expect "principles: two booleans are kept in sync" bash -c 'grep -q "exported: false, unexported: true" src/notes.js && grep -q "note.unexported = false" src/notes.js'
expect "blast radius: the caller outside the diff breaks" bash -c '! node -e "require(\"./src/report\").summary()" >/dev/null 2>&1'
expect "blast radius: the caller is not in the diff" bash -c '! git diff --name-only main | grep -qx src/report.js'
expect "security: the siblings of the new route call the auth gate" bash -c 'test "$(grep -c "requireOwner(request);" src/routes.js)" = 2'
expect "security: the export route skips the gate, so a stranger reads every note" quiet node -e '
  const { handle } = require("./src/routes");
  const stranger = { params: { userId: "2" }, session: null };
  let gated = false;
  try { handle("GET /users/:userId/notes", stranger); } catch { gated = true; }
  const csv = handle("GET /users/:userId/notes/export", stranger);
  process.exit(gated && typeof csv === "string" ? 0 : 1);'
expect "security: the route file is in the diff" bash -c 'git diff --name-only main | grep -qx src/routes.js'
expect "security: the spec asks for the route, so only the missing gate is the defect" grep -q 'GET /users/:userId/notes/export' .scratch/export-notes/spec.md
expect "the clean hunk has its green test" quiet node --test tests/csv.test.js
expect "the Ticket the case hands over sits beside its spec" test -f .scratch/export-notes/issues/02-export-notes.md
expect "the Ticket asks for the header line the export omits" grep -q 'header line `id,title`' .scratch/export-notes/issues/02-export-notes.md
run_door
check "the door reads the planted fixture" 0 "$rc" "branch=export-notes" "dirty=no" "base=main" "commits=1" \
  "spec=.scratch/export-notes/spec.md" "review=.scratch/reviews/export-notes.md" "review_in_status=yes" "tracker=no" \
  "ticket=.scratch/export-notes/issues/02-export-notes.md" "ticket_handed=no"
run_door --ticket .scratch/export-notes/issues/02-export-notes.md
check "the door puts the Review beside the Ticket the case hands over" 0 "$rc" \
  "ticket_handed=yes" "review=.scratch/export-notes/issues/02-export-notes.review.md" \
  "spec=.scratch/export-notes/spec.md" "review_in_status=yes"

# ref-does-not-resolve: the ref the prompt names is absent.
expect "ref-does-not-resolve scaffold runs" scaffold ref-does-not-resolve
expect "the ref nope is absent" bash -c '! git rev-parse --verify -q nope >/dev/null'
run_door nope
check "the door refuses the ref in one line" 1 "$rc" "refusal=nope does not resolve; nothing reviewed"

# empty-diff: a clean tree on main with no remote.
expect "empty-diff scaffold runs" scaffold empty-diff
expect "the tree is clean on main" bash -c 'test "$(git branch --show-current)" = main && test -z "$(git status --porcelain)"'
run_door
check "the door refuses the empty diff in one line" 1 "$rc" "refusal=no diff between main ($(git rev-parse --short main)) and the working tree; nothing reviewed"

# no-spec: a branch with a diff and no spec home anywhere.
expect "no-spec scaffold runs" scaffold no-spec
expect "no spec home exists" bash -c '! test -e .scratch && ! test -e docs && ! test -e specs'
expect "the suite is green" quiet node --test tests/
run_door
check "the door names no spec and no tracker" 0 "$rc" "branch=restore-notes" "spec=none" "tracker=no" "commits=1" \
  "review=.scratch/reviews/restore-notes.md"

# triggers-pt-br: an uncommitted change, so the bare request names a diff.
expect "triggers-pt-br scaffold runs" scaffold triggers-pt-br
expect "the tree carries a diff" test -n "$(git status --porcelain)"
run_door
check "the door names the case root as the main checkout" 0 "$rc" "main_checkout=$(pwd -P)"

# reviewer-retry: a diff the technical reviewer can report on, with the security reviewer shadowed
# by a stand-in that never writes its return file.
expect "reviewer-retry scaffold runs" scaffold reviewer-retry
expect "the branch carries a diff against main" bash -c 'test -n "$(git diff --name-only main)"'
expect "the stand-in shadows the security reviewer in the project" \
  test -f .claude/agents/do-code-review-security-reviewer.md
expect "the stand-in writes no return file and ends at once" \
  grep -q "create the return file the brief names" .claude/agents/do-code-review-security-reviewer.md
expect "the technical reviewer is not shadowed" \
  bash -c '! test -e .claude/agents/do-code-review-technical-reviewer.md'
expect "the technical reviewer has a defect to report" quiet node -e 'const { page } = require("./src/notes"); process.exit(page([...Array(11).keys()], 1, 10).length === 9 ? 0 : 1)'
run_door
check "the door reads the retry fixture" 0 "$rc" "branch=paginate-notes" "dirty=no" "base=main" \
  "spec=.scratch/paginate-notes/spec.md"

if [ "$fails" = 0 ]; then echo "PASS"; else echo "$fails failing"; exit 1; fi
