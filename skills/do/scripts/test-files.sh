#!/usr/bin/env bash
# test-files.sh: which paths are test files in a project, shared by trivial-door.sh and
# changeset-check.sh. Sourced, never run: it defines two functions and does nothing else.
#
#   test_classes <project top>   loads the classes and sets classes=policy|built-in
#   is_test_file <absolute path> status 0 for a test file under the loaded classes
#
# The classes come from the project's installed Testing Policy
# (<project>/.claude/testing-policy/skip-patterns.sh, skip_pattern_for) when it exists, else from
# the built-in list below, which mirrors the policy's classes plus common ones for languages it does
# not cover. The path is absolute because the policy's patterns, and the built-in ones, need a
# leading directory.

test_classes() {
  classes=built-in
  if [ -f "$1/.claude/testing-policy/skip-patterns.sh" ]; then
    # shellcheck disable=SC1091
    . "$1/.claude/testing-policy/skip-patterns.sh"
    classes=policy
  fi
}

is_test_file() {
  if [ "$classes" = policy ]; then
    SKIP_KIND=""
    skip_pattern_for "$1"
    [ -n "${SKIP_KIND:-}" ]
    return
  fi
  case "$1" in
    *.test.ts|*.test.tsx|*.test.mts|*.test.cts|*.test.js|*.test.jsx|*.test.mjs|*.test.cjs|\
    *.spec.ts|*.spec.tsx|*.spec.mts|*.spec.cts|*.spec.js|*.spec.jsx|*.spec.mjs|*.spec.cjs|\
    *.cy.ts|*.cy.tsx|*.cy.js|*.cy.jsx|*/__tests__/*|*/__snapshots__/*|*.snap|\
    */test_*.py|*_test.py|*/conftest.py|*/.maestro/*.yaml|*/.maestro/*.yml|\
    *_test.go|*_test.rb|*_spec.rb|*Test.java|*Tests.java|*Test.kt|*Tests.cs|*.feature|\
    */tests/*|*/test/*|*/spec/*|*/e2e/*) return 0 ;;
  esac
  return 1
}
