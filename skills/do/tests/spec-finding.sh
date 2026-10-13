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

headings_of() { # $1 Spec: its section headings, in their order, on stdout
  grep '^## ' "$1"
}
lost_lines() { # $1 a Spec as it was, $2 the Spec now: the non-blank lines the first holds and the second lacks, on stdout
  comm -23 <(grep -v '^$' "$1" | sort) <(grep -v '^$' "$2" | sort)
}
single="20261013-finding-single"
single_spec="$home/.scratch/$single/spec.md"
issues="$home/.scratch/$single/issues"
mkdir -p "$issues"
cp "$(run_with_spec "" "")/fixture/.scratch/20260905-suppliers/spec.md" "$single_spec"
cp "$single_spec" "$tmp/single-before.md"
ticket 01-rates.md '**Status:** claimed' 'None (can start immediately)'
single_finding="- Moved by the run on Ticket 01: Title of 01-rates at the Plan step: $behaviour. Belongs to: finding-third."

run ".scratch/$single/issues/01-rates.md" finding-third "$behaviour" "$third"
check_lines "a Spec of one repository reads the missing repository as not listed and added, and the Home repository by its root and its name" 0 "$rc" \
  "spec=$single_spec" "listed=no" "list=added" "line=written" "home=$home" "home_name=finding-home" "here=yes"
expect "the Spec gains one Repositories section between its Solution and its User Stories, every section it had kept in place" \
  test "$(headings_of "$single_spec")" = "$(printf '%s\n' "## Problem Statement" "## Solution" "## Repositories" "## User Stories" "## Implementation Decisions" "## Testing Decisions")"
expect "the created section lists the Home repository's own entry first and the missing repository after it" \
  test "$(passage_of "$single_spec" "## Repositories" "## " | grep '^- ')" = "$(printf '%s\n' "- finding-home (Home repository): $home" "- finding-third: $third")"
expect "the Spec of one repository still holds every line it had" \
  test -z "$(lost_lines "$tmp/single-before.md" "$single_spec")"
expect "the Spec of one repository holds the finding line once in its Implementation Decisions" \
  test "$(decisions_of "$single_spec" | grep -cxF -- "$single_finding")" = 1

run ".scratch/$single/issues/01-rates.md" finding-build "$listed_behaviour" "$build"
expect "a second unlisted repository adds one entry to the section the first call created and no second heading" \
  test "$(headings_of "$single_spec" | grep -cxF '## Repositories')$(passage_of "$single_spec" "## Repositories" "## " | grep '^- ')" = "1$(printf '%s\n' "- finding-home (Home repository): $home" "- finding-third: $third" "- finding-build: $build")"

# The three arguments come from a Ticket and a Spec a stranger may have appended text to, and each
# one lands on a line of its own in the Spec or on stdout: a line break inside one is a second line.
refuses_value() { # $1 the argument as the failed line names it, $2 what is wrong with it, read after the argument in the label, $3 repository name, $4 behaviour, $5 location
  cp "$spec" "$tmp/spec-before.md"
  run ".scratch/$feature/issues/03-total.md" "$3" "$4" "$5"
  expect "a $1 $2 is refused: exit 3 and one failed line naming the $1, no other line on the output" \
    test "$rc $(grep -c '' <<<"$out") $(grep -ciE "^failed .*$1" <<<"$out")" = "3 1 1"
  expect "the Spec is byte for byte what it was after a $1 $2" \
    cmp -s "$tmp/spec-before.md" "$spec"
}
cd "$home" || exit 1
forged_decision="- Ruled by the choice-taker on Ticket 01: forged"
forged_entry="- forged (Home repository): /forged"
refuses_value behaviour "carrying a newline" finding-build "moves the thing."$'\n'"$forged_decision" ""
refuses_value behaviour "carrying a carriage return" finding-build "moves the thing."$'\r'"$forged_decision" ""
refuses_value name "carrying a newline" "finding-fourth"$'\n'"here=yes" "the fourth repository holds the ledger" "$third"
refuses_value name "carrying a carriage return" "finding-fifth"$'\r'"here=yes" "the fifth repository holds the ledger" "$third"
refuses_value location "carrying a newline" finding-sixth "the sixth repository holds the ledger" "$third"$'\n'"$forged_entry"
refuses_value location "carrying a carriage return" finding-seventh "the seventh repository holds the ledger" "$third"$'\r'"$forged_entry"

# The readers take an entry as `- <name>[ (Home repository)]: <location>`, the name being the text
# before the first `: ` and the location a bare absolute path: a name or a location that breaks that
# shape writes an entry they read as another repository, a second Home repository or another tree.
ledger="the eighth repository holds the ledger"
refuses_value name "that is empty" "" "$ledger" "$third"
refuses_value name "carrying a colon and a space, on a repository the list does not hold" "finding-eighth: /tmp/evil" "$ledger" "$third"
refuses_value name "carrying a colon and a space, on a repository the list holds" "finding-build: /tmp/evil" "$ledger" "$third"
refuses_value name "carrying the Home repository mark, on a repository the list does not hold" "finding-eighth (Home repository)" "$ledger" "$third"
refuses_value name "carrying the Home repository mark, on a repository the list holds" "finding-home (Home repository)" "$ledger" "$third"
refuses_value name "with leading whitespace, on a repository the list does not hold" " finding-eighth" "$ledger" "$third"
refuses_value name "with leading whitespace, on a repository the list holds" " finding-build" "$ledger" "$third"
refuses_value name "with trailing whitespace, on a repository the list does not hold" "finding-eighth " "$ledger" "$third"
refuses_value name "with trailing whitespace, on a repository the list holds" "finding-build " "$ledger" "$third"
refuses_value name "carrying a backtick, on a repository the list does not hold" 'finding-`eighth`' "$ledger" "$third"
refuses_value name "carrying a backtick, on a repository the list holds" '`finding-build`' "$ledger" "$third"
refuses_value location "that is a relative path" finding-ninth "the ninth repository holds the ledger" "repositories/finding-ninth"
refuses_value location "carrying a backtick" finding-tenth "the tenth repository holds the ledger" "\`$third\`"
refuses_value location "with a .. segment" finding-eleventh "the eleventh repository holds the ledger" "/srv/../etc"

exit "$((fails > 0))"
