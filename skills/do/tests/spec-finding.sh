#!/usr/bin/env bash
# spec-finding.sh: the contract of scripts/spec-finding.sh, what the Spec holds once a run finds work
# for a repository at the Plan step, exercised in throwaway sibling git repositories.
# Run: bash skills/do/tests/spec-finding.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/spec-finding.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT
export HOME="$tmp/home"
mkdir -p "$HOME"

run() {
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines reads $out
  out="$(bash "$script" "$@" 2>&1)" || rc=$?
}
entries_of() { # $1 Spec: the entry lines of its Repositories section, sorted, on stdout
  passage_of "$1" "## Repositories" "## " | grep '^- ' | sort
}
decisions_of() { # $1 Spec: its Implementation Decisions section, on stdout
  passage_of "$1" "## Implementation Decisions" "## "
}

feature="20261013-finding"
sibling_repos finding-home finding-build "$feature"
fresh finding-third
printf 'one\n' >notes.txt
commit fixture
third="$(pwd -P)"
# shellcheck disable=SC2154 # lib.sh's sibling_repos assigns $home
cd "$home" || exit 1
spec="$home/.scratch/$feature/spec.md"
# shellcheck disable=SC2154 # lib.sh's sibling_repos assigns $home and $build
repositories_spec "$home/.scratch/$feature" "- finding-home (Home repository): $home" "- finding-build: $build"
printf '\n## Implementation Decisions\n\n- The total is a sum of the invoice lines.\n\n## Testing Decisions\n\n- The totals module, through its public call.\n' >>"$spec"
ticket 03-total.md '**Status:** claimed' 'None (can start immediately)'

behaviour="the tax rate of an invoice line is read from the rates service"
finding="- Moved by the run on Ticket 03: Title of 03-total at the Plan step: $behaviour. Belongs to: finding-third."

run ".scratch/$feature/issues/03-total.md" finding-third "$behaviour" "$third"
check_lines "a repository the Spec does not list reads as not listed, added to the list, with the finding line written" 0 "$rc" \
  "spec=$spec" "repository=finding-third" "listed=no" "list=added" "line=written"
expect "the Spec's Repositories section holds one new entry for the repository beside the two it had, unchanged" \
  test "$(entries_of "$spec")" = "$(printf '%s\n' "- finding-home (Home repository): $home" "- finding-build: $build" "- finding-third: $third" | sort)"
expect "the Spec's Implementation Decisions hold the finding line once, marked with the Ticket and the repository it belongs to" \
  test "$(decisions_of "$spec" | grep -cxF -- "$finding")" = 1
expect "the Spec's Implementation Decisions still hold the line they had" \
  test "$(decisions_of "$spec" | grep -cxF -- "- The total is a sum of the invoice lines.")" = 1

section_of() { # $1 Spec: its Repositories section as written, closed by a sentinel so trailing blank lines count, on stdout
  passage_of "$1" "## Repositories" "## "
  echo end
}
listed_behaviour="the invoice total is rounded by the build repository's money module"
listed_finding="- Moved by the run on Ticket 03: Title of 03-total at the Plan step: $listed_behaviour. Belongs to: finding-build."
section_before="$(section_of "$spec")"

run ".scratch/$feature/issues/03-total.md" finding-build "$listed_behaviour"
check_lines "a repository the Spec already lists reads as listed, the list unchanged, with the finding line written" 0 "$rc" \
  "spec=$spec" "repository=finding-build" "listed=yes" "list=unchanged" "line=written"
expect "the Spec's Repositories section is what it was before a finding for a listed repository" \
  test "$(section_of "$spec")" = "$section_before"
expect "the Spec's Implementation Decisions hold the listed repository's finding line once" \
  test "$(decisions_of "$spec" | grep -cxF -- "$listed_finding")" = 1

run ".scratch/$feature/issues/03-total.md" finding-build "$listed_behaviour"
check_lines "the same finding given a second time reads as already in the Spec" 0 "$rc" \
  "listed=yes" "list=unchanged" "line=present"
expect "the Spec's Implementation Decisions still hold that finding line once after the second call" \
  test "$(decisions_of "$spec" | grep -cxF -- "$listed_finding")" = 1

run ".scratch/$feature/issues/03-total.md" finding-build "the rounding mode is read from the build repository's settings" "$third"
expect "the Spec's Repositories section is what it was when a listed repository is named with another location" \
  test "$(section_of "$spec")" = "$section_before"

sibling_behaviour="the invoice currency is formatted by the build repository's locale module"
sibling_finding="- Moved by the run on Ticket 03: Title of 03-total at the Plan step: $sibling_behaviour. Belongs to: finding-build."

cd "$build" || exit 1
run "$home/.scratch/$feature/issues/03-total.md" finding-build "$sibling_behaviour"
check_lines "a run from the sibling Build repository reads the Home repository as another checkout, by its root and its name" 0 "$rc" \
  "spec=$spec" "line=written" "home=$home" "home_name=finding-home" "here=no"
expect "the Home repository's root, its name and whether the run is in it close the output, in that order after the finding line's state" \
  test "$(keys_in_order | grep -c 'line home home_name here $')" = 1
expect "the Home repository's Spec holds the finding line written from the sibling Build repository once" \
  test "$(decisions_of "$spec" | grep -cxF -- "$sibling_finding")" = 1
expect "the sibling Build repository holds no Feature folder of its own after the run" \
  test ! -e "$build/.scratch"
expect "the sibling Build repository is left with no change after the run" \
  test -z "$(g -C "$build" status --porcelain)"

cd "$home" || exit 1
run ".scratch/$feature/issues/03-total.md" finding-build "the invoice due date is computed by the build repository's calendar module"
check_lines "a run from the Home repository reads it as this checkout, by its root and its name" 0 "$rc" \
  "line=written" "home=$home" "home_name=finding-home" "here=yes"

exit "$((fails > 0))"
