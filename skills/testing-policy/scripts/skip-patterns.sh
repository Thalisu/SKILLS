#!/usr/bin/env bash
# skip-patterns.sh: single source of the skip/only/todo/optional markers the Testing Policy forbids
# and of which files count as test files for the guard. Sourced by forbid-test-skips.sh (hook) and
# scan-test-assets.sh (skip-markers section); installed next to them in <project>/.claude/testing-policy/
# and overwritten on refresh.
#
# Built-in coverage: JS/TS (jest, vitest, bun, mocha, jasmine, node:test, Playwright, Cypress),
# Python (pytest, unittest), Maestro YAML. Anything else goes in skip-patterns.local.sh in the same
# directory, preserved on refresh, sourced last. It may append to a SKIP_PAT_* variable
# (SKIP_PAT_JS+='|\.todoIf\(') or define skip_pattern_local <path> that sets SKIP_PAT / SKIP_KIND
# for files the built-in classifier leaves empty.

SKIP_PAT_JS='\b(test|it|describe|suite|context|bench|t)(\.[A-Za-z]+)*\.(skip|only|todo|fixme|fail|fails|failing|skipIf|runIf)\(|\b(xit|xdescribe|xtest|fit|fdescribe|ftest)\('
SKIP_PAT_PY='pytest\.mark\.(skip|skipif|xfail)\b|pytest\.(skip|xfail)\(|unittest\.(skip|skipIf|skipUnless|expectedFailure)\b|^[[:space:]]*@(skip|skipIf|skipUnless|expectedFailure)\b'
SKIP_PAT_MAESTRO='optional:[[:space:]]*true'

# skip_pattern_for <path>: sets SKIP_PAT and SKIP_KIND for a test file; leaves both empty otherwise.
skip_pattern_for() {
  SKIP_PAT="" SKIP_KIND=""
  case "$1" in
    *.test.ts|*.test.tsx|*.test.mts|*.test.cts|*.test.js|*.test.jsx|*.test.mjs|*.test.cjs|\
    *.spec.ts|*.spec.tsx|*.spec.mts|*.spec.cts|*.spec.js|*.spec.jsx|*.spec.mjs|*.spec.cjs|\
    *.cy.ts|*.cy.tsx|*.cy.js|*.cy.jsx|*/__tests__/*)
      SKIP_PAT="$SKIP_PAT_JS" SKIP_KIND='skip/only/todo/fixme' ;;
    */test_*.py|test_*.py|*_test.py|*/conftest.py|conftest.py)
      SKIP_PAT="$SKIP_PAT_PY" SKIP_KIND='skip/xfail' ;;
    */.maestro/*.yaml|*/.maestro/*.yml|.maestro/*.yaml|.maestro/*.yml)
      SKIP_PAT="$SKIP_PAT_MAESTRO" SKIP_KIND='optional: true' ;;
  esac
  if [ -z "$SKIP_PAT" ] && declare -F skip_pattern_local >/dev/null; then skip_pattern_local "$1"; fi
}

_skip_local="$(dirname "${BASH_SOURCE[0]}")/skip-patterns.local.sh"
[ -f "$_skip_local" ] && . "$_skip_local"
unset _skip_local
