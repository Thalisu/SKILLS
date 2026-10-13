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
  # Optional: $6 the Ticket's file name in the feature folder (default: 03-total.md)
  cp "$spec" "$tmp/spec-before.md"
  run ".scratch/$feature/issues/${6:-03-total.md}" "$3" "$4" "$5"
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

# The readers trim the whitespace around an entry's location and cut the moved behaviour from the
# finding line at its `Belongs to:` marker: a location they would read as another string, or a
# behaviour that brings a marker of its own, makes the Spec say something the script did not report.
refuses_value location "with trailing whitespace" finding-twelfth "the twelfth repository holds the ledger" "$third "
refuses_value behaviour "carrying a Belongs to: marker of its own" finding-build "moves the thing. Belongs to: finding-forged" ""

# A Ticket's heading is text a stranger may have written (an issue's title on a tracker), and it
# sits on the finding line ahead of the two marks the readers cut the behaviour and the repository
# at: a title bringing either mark forges both, and one ending in a carriage return breaks the line.
titled_ticket() { # $1 file name, $2 the text of its `# ` heading: a Ticket in the feature folder's issues/ with that heading
  issues="$home/.scratch/$feature/issues" ticket "$1" '**Status:** claimed' 'None (can start immediately)'
  TITLE="$2" awk 'NR == 1 { print "# " ENVIRON["TITLE"]; next } { print }' "$home/.scratch/$feature/issues/$1" >"$tmp/titled.md"
  mv "$tmp/titled.md" "$home/.scratch/$feature/issues/$1"
}
hold="the invoice hold is released by the build repository's ledger module"
titled_ticket 04-step.md "04: Hold the invoice at the Plan step: delete the ledger"
refuses_value title "carrying the at the Plan step: mark" finding-build "$hold" "$build" 04-step.md
titled_ticket 05-belongs.md "05: Hold the invoice. Belongs to: evil-repo"
refuses_value title "carrying a Belongs to: mark" finding-build "$hold" "$build" 05-belongs.md
titled_ticket 06-crlf.md "06: Hold the invoice"
sed -i 's/$/\r/' "$home/.scratch/$feature/issues/06-crlf.md"
refuses_value title "ending in a carriage return, in a Ticket with CRLF line ends" finding-build "$hold" "$build" 06-crlf.md

# The readers find the section by a heading that tolerates trailing whitespace, so a Spec written
# with one has a section, and `list=added` is a claim that this section holds the entry.
spaced="20261013-finding-spaced"
spaced_spec="$home/.scratch/$spaced/spec.md"
repositories_spec "$home/.scratch/$spaced" "- finding-home (Home repository): $home" "- finding-build: $build"
sed -i 's/^## Repositories$/## Repositories /' "$spaced_spec"
printf '\n## Implementation Decisions\n\n- The total is a sum of the invoice lines.\n' >>"$spaced_spec"
issues="$home/.scratch/$spaced/issues"
ticket 01-rates.md '**Status:** claimed' 'None (can start immediately)'

run ".scratch/$spaced/issues/01-rates.md" finding-third "$behaviour" "$third"
check_lines "a repository missing from a Spec whose Repositories heading ends in whitespace reads as not listed and added" 0 "$rc" \
  "spec=$spaced_spec" "listed=no" "list=added"
expect "the section under the heading that ends in whitespace holds the new entry beside the two it had" \
  test "$(entries_of "$spaced_spec")" = "$(printf '%s\n' "- finding-home (Home repository): $home" "- finding-build: $build" "- finding-third: $third" | sort)"
expect "the Spec whose heading ends in whitespace still has one Repositories section" \
  test "$(headings_of "$spaced_spec" | grep -c '^## Repositories')" = 1

# An entry with no location is one no reader of the list can take, so a repository the run can name
# and cannot locate is recorded on the finding line alone, for the developer to locate afterwards.
unlocated_behaviour="the supplier ledger is exported by the archive repository's batch module"
unlocated_finding="- Moved by the run on Ticket 03: Title of 03-total at the Plan step: $unlocated_behaviour. Belongs to: finding-archive. Location not known."
section_before="$(section_of "$spec")"

run ".scratch/$feature/issues/03-total.md" finding-archive "$unlocated_behaviour"
check_lines "a repository the Spec does not list, named with no location, reads as not listed and not located, with the finding line written" 0 "$rc" \
  "spec=$spec" "repository=finding-archive" "listed=no" "list=no-location" "line=written"
expect "the Spec's Repositories section is byte for byte what it was after a finding for a repository with no known location" \
  test "$(section_of "$spec")" = "$section_before"
expect "the Spec's Implementation Decisions hold the finding line once, naming the repository and marking its location as not known" \
  test "$(decisions_of "$spec" | grep -cxF -- "$unlocated_finding")" = 1
cp "$spec" "$tmp/unlocated-once.md"

run ".scratch/$feature/issues/03-total.md" finding-archive "$unlocated_behaviour"
check_lines "the same finding with no known location given a second time reads as already in the Spec" 0 "$rc" \
  "listed=no" "list=no-location" "line=present"
expect "the Spec is byte for byte what the first call left after the second call" \
  cmp -s "$tmp/unlocated-once.md" "$spec"

bare="20261013-finding-bare"
bare_spec="$home/.scratch/$bare/spec.md"
issues="$home/.scratch/$bare/issues"
mkdir -p "$issues"
cp "$(run_with_spec "" "")/fixture/.scratch/20260905-suppliers/spec.md" "$bare_spec"
ticket 01-rates.md '**Status:** claimed' 'None (can start immediately)'
bare_headings="$(headings_of "$bare_spec")"
bare_finding="- Moved by the run on Ticket 01: Title of 01-rates at the Plan step: $unlocated_behaviour. Belongs to: finding-archive. Location not known."

run ".scratch/$bare/issues/01-rates.md" finding-archive "$unlocated_behaviour"
check_lines "a repository with no known location on a Spec of one repository reads as not listed and not located, with the finding line written" 0 "$rc" \
  "spec=$bare_spec" "repository=finding-archive" "listed=no" "list=no-location" "line=written"
expect "the Spec of one repository gains no Repositories section for a repository with no known location" \
  test "$(headings_of "$bare_spec")" = "$bare_headings"
expect "the Spec of one repository holds the finding line once, its location marked as not known" \
  test "$(decisions_of "$bare_spec" | grep -cxF -- "$bare_finding")" = 1

# A Ticket of a feature of one repository carries no Build repository line, and the doors and the
# landing record read a lineless Ticket of a Spec with a list as naming none of its entries: the
# call that creates the list must leave every Ticket the feature already had buildable and ordered.
door="$here/../scripts/ticket-door.sh"
landing="$here/../scripts/landing-order.sh"
sibling_repos lineless-home lineless-build 20261013-lineless
# shellcheck disable=SC2154 # lib.sh's sibling_repos assigns $home, $build and $issues
lineless_spec="$home/.scratch/20261013-lineless/spec.md"
cp "$(run_with_spec "" "")/fixture/.scratch/20260905-suppliers/spec.md" "$lineless_spec"
ticket 01-first.md '**Status:** ready-for-agent' 'None (can start immediately)'
ticket 02-second.md '**Status:** claimed' 'None (can start immediately)'
cd "$build" || exit 1
rc=0
out="$(cd "$home" && bash "$door" "$issues/01-first.md" 2>&1)" || rc=$?
check_lines "a Ticket with no Build repository line of a Spec with no list passes the door before any finding" 0 "$rc" \
  "build_check=none" "verdict=start"

lineless_behaviour="the invoice currency is formatted by the build repository's locale module"
run "$issues/02-second.md" lineless-build "$lineless_behaviour" "$build"
check_lines "a finding for a repository on a Spec with no list creates the list" 0 "$rc" \
  "listed=no" "list=added" "line=written"
rc=0
out="$(cd "$home" && bash "$door" "$issues/01-first.md" 2>&1)" || rc=$?
check_lines "a Ticket with no Build repository line that the feature already had still passes the door once the list exists" 0 "$rc" \
  "build_repository=lineless-home" "build_check=here" "verdict=start"
rc=0
out="$(cd "$home" && bash "$door" "$issues/02-second.md" 2>&1)" || rc=$?
check_lines "the stopped Ticket still passes the door once the list exists" 0 "$rc" \
  "build_repository=lineless-home" "build_check=here" "verdict=start-over"

ticket 03-third.md $'**Status:** ready-for-agent\n\n**Build repository:** lineless-build' 'None (can start immediately)'
sed -i 's/^\*\*Blocked by:\*\* .*/**Blocked by:** 03, Title of 03-third/' "$issues/02-second.md"
rc=0
out="$(cd "$home" && bash "$door" "$issues/02-second.md" 2>&1)" || rc=$?
check_lines "the stopped Ticket reads blocked once its blocker is added, the blocker's repository named" 1 "$rc" \
  "next_blocker=$issues/03-third.md" "next_blocker_build=lineless-build" "verdict=blocked"

for n in 01-first 02-second 03-third; do sed -i 's/^\*\*Status:\*\* .*/**Status:** resolved/' "$issues/$n.md"; done
for repo in "$home" "$build"; do
  (cd "$repo" && g branch -q --track spec/lineless main && spec_commit spec/lineless) ||
    echo "FAIL  fixture: the unlanded Spec branch of $repo could not be built"
done
rc=0
out="$(bash "$landing" "$issues/03-third.md" 2>&1)" || rc=$?
check_lines "the landing record of the completed feature counts both repositories, as it does with every Ticket carrying its line" 0 "$rc" \
  "repositories=2"
expect "the landing record of the completed feature is not ambiguous" \
  test -z "$(grep -E '^(ambiguous=|verdict=ambiguous)' <<<"$out")"

exit "$((fails > 0))"
