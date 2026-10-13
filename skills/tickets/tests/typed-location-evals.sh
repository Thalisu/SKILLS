#!/usr/bin/env bash
# typed-location-evals.sh: the fixtures and the code-read graders of the eval cases that grade, on a
# live run, a location typed with the `tickets` command for a repository a stopped `do` run could
# name and not locate.
# Whoever changes skills/tickets/SKILL.md later has no other check that a typed location still
# reaches the Spec. A fixture that already lists the repository, or a Spec grader that does not tell
# the entry at the typed location from a fixture without one, stays green while the typed location
# is dropped, and the developer is back to editing the Spec by hand.
# The same holds for a typed location that is not a git repository, which is written and warned
# about rather than refused: a fixture that lays a real repository there, or a close grader that
# accepts a close with no line on the location, stays green while `tickets` refuses the location,
# drops it, or leaves the developer to learn of it when `do` refuses the ticket at its door.
# No model session runs here: each fixture is laid as scripts/run-eval.sh lays it, and each code-read
# grader is run against a work folder.
# Run: bash skills/tickets/tests/typed-location-evals.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
evals="$here/../evals"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

source_grade

# A case as a run of it starts: the fixture laid under a work folder, the feature it holds, the
# repository its finding leaves without a location.
lay_case() { # $1 case name
  # sets: case_dir, as_laid, fixture, spec, feature, slug, tickets, issues, finding, repo, sibling
  case_dir="$evals/$1"
  as_laid="$tmp/$1"
  fixture="$as_laid/fixture"
  mkdir -p "$fixture"
  scaffold_rc=0
  lay_scaffold "$case_dir/case.yaml" "$fixture" || scaffold_rc=$?
  fixture="$(cd "$fixture" && pwd -P)"
  spec="$(find "$fixture/.scratch" -name spec.md 2>/dev/null | head -n 1)"
  feature="$(dirname "${spec:-$fixture/.scratch/none/spec.md}")"
  slug="$(basename "$feature")"
  issues="$feature/issues"
  mapfile -t tickets < <(find "$issues" -maxdepth 1 -name '*.md' 2>/dev/null | sort)
  finding="$(grep -E '^- Moved by the run on Ticket .+\. Belongs to: .+\. Location not known\.$' "${spec:-/dev/null}" | head -n 1)"
  repo="$(sed -nE 's/^.*\. Belongs to: (.+)\. Location not known\.$/\1/p' <<<"$finding")"
  sibling="$(cd "$as_laid/${repo:-none}" 2>/dev/null && pwd -P)"
  label="the scaffold lays a feature folder with a spec"
  if [ "$scaffold_rc" = 0 ] && [ -n "$spec" ]; then ok "$label"; else
    fail "$label (scaffold exit $scaffold_rc)"
    echo "      extract: $(tail -1 "$tmp/extract.log")"
    echo "      scaffold: $(tail -1 "$tmp/scaffold.log")"
  fi
}
# A copy of the fixture as laid whose Spec gained one line at the end of its Repositories list.
with_entry() { # $1 name of the copy under $tmp, $2 the line
  local at
  at="$(mutated "$1")"
  [ -f "$at/spec.md" ] || return 0
  awk -v line="$2" '
    /^## / { if (on && !done) { print line; print ""; done = 1 }; on = ($0 == "## Repositories") }
    on && /^$/ && seen && !done { print line; done = 1 }
    on && /^- / { seen = 1 }
    { print }
  ' "$as_laid/fixture/.scratch/$slug/spec.md" >"$at/spec.md"
}
# grade_passes and grade_fails print ok on any reason, so a grader that was never found would pass
# every refusal.
found_grader() { # $1 grade_passes|grade_fails, $2 label, $3 work folder: red when the caller's $grader is empty
  if [ -n "$grader" ]; then "$1" "$2" "$3"; else fail "$2 (no such grader in the case)"; fi
}
# The grader of the case that reads the Spec for the entry: a file_contains grader on the spec that
# passes a work folder whose Repositories list holds it and fails the fixture as laid.
spec_entry_grader() { # $1 a work folder whose spec holds the entry: sets grader, empty when the case has none
  local g
  grader=""
  for g in "$case_dir"/graders/*.md; do
    [ -f "$g" ] || continue
    [ "$(key "$g" type)" = file_contains ] || continue
    case "$(key "$g" path)" in
      *.scratch/*spec.md*) ;;
      *) continue ;;
    esac
    if [ -z "$(grade "$g" "$1")" ] && [ -n "$(grade "$g" "$as_laid")" ]; then
      grader="$g"
      return
    fi
  done
}
# The fixture a run of the case starts from leaves the finding's repository without a location, and
# nothing already cut for it.
owes_the_location() { # reads what lay_case set
  expect "the spec holds a finding line whose location is not known" test -n "$finding"
  expect "which names the repository the work belongs to" test -n "$repo"
  passage_of "${spec:-/dev/null}" "## Repositories" "## " >"$tmp/repositories.md"
  expect "the spec's repositories list holds the home repository's entry" \
    grep -qE '^- .+ \(Home repository\): /' "$tmp/repositories.md"
  label="and no entry for the repository the finding names"
  if [ -n "$repo" ] && ! grep -qE "^- ${repo}( \(|:)" "$tmp/repositories.md"; then ok "$label"; else fail "$label"; fi
  expect "the feature has a ticket still open" \
    grep -qE '^\*\*Status:\*\* (ready-for-agent|claimed|needs-triage|needs-info)' "${tickets[@]:-/dev/null}"
  label="no ticket covers the finding: none is built in that repository"
  if [ "${#tickets[@]}" -gt 0 ] && [ -n "$repo" ] &&
    ! grep -qE "^\*\*Build repository:\*\* ${repo}\s*$" "${tickets[@]}"; then ok "$label"; else fail "$label"; fi
}

echo "# evals/location-typed-with-the-command: the fixture owes the location"
case_name="location-typed-with-the-command"
lay_case "$case_name"
owes_the_location
label="a git repository with a commit is laid beside the fixture root under that name"
if [ -n "$sibling" ] && [ "$(git -C "$sibling" rev-parse --show-toplevel 2>/dev/null)" = "$sibling" ] &&
  git -C "$sibling" rev-parse -q --verify HEAD >/dev/null 2>&1; then ok "$label"; else fail "$label"; fi

typed="$fixture/../${repo:-none}"

echo "# evals/location-typed-with-the-command: a grader reads the Spec for the entry"
location="$typed"
with_entry entry-written "- ${repo:-none}: $location"
with_entry entry-for-another "- some-other-service: $location"
with_entry entry-elsewhere "- ${repo:-none}: /srv/checkouts/elsewhere"
spec_entry_grader "$tmp/entry-written"
found_grader grade_passes "a file_contains grader on the spec passes once the list holds the entry at the typed location" "$tmp/entry-written"
found_grader grade_fails "and fails the spec as laid, the finding line with no entry" "$as_laid"
found_grader grade_fails "an entry at that location under another repository's name fails it" "$tmp/entry-for-another"
found_grader grade_fails "an entry for the repository at another location fails it" "$tmp/entry-elsewhere"

echo "# evals/location-owed-and-not-typed-stops: the fixture owes a location"
case_name="location-owed-and-not-typed-stops"
lay_case "$case_name"
owes_the_location

echo "# evals/location-typed-is-not-a-git-repository: the fixture owes the location, and no repository is there"
case_name="location-typed-is-not-a-git-repository"
lay_case "$case_name"
owes_the_location
expect "a directory is laid beside the fixture root under that name" test -n "$sibling" -a -d "${sibling:-/nonexistent}"
label="and it is not a git repository"
if [ -n "$sibling" ] && [ -d "$sibling" ] &&
  ! git -C "$sibling" rev-parse --is-inside-work-tree >/dev/null 2>&1; then ok "$label"; else fail "$label"; fi

echo "# evals/location-typed-is-not-a-git-repository: the case runs under a choice-taker stand-in that publishes"
expect "the case unlinks the real choice-taker" \
  grep -qx "choice-taker" <(yq -r '.context.unlinked_agents // [] | .[]' "$case_dir/case.yaml" 2>/dev/null)
stand_in="$fixture/.claude/agents/choice-taker.md"
expect "the fixture holds the choice-taker stand-in" test -f "$stand_in"
flat="$(cat "$stand_in" 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
flat="${flat,,}"
carries_any "which rules to publish the breakdown" "publish"

echo "# evals/location-typed-is-not-a-git-repository: a grader reads the Spec for the entry as typed"
typed="$fixture/../${repo:-none}"
location="$typed"
with_entry not-git-entry-written "- ${repo:-none}: $location"
with_entry not-git-entry-for-another "- some-other-service: $location"
with_entry not-git-entry-elsewhere "- ${repo:-none}: /srv/checkouts/elsewhere"
spec_entry_grader "$tmp/not-git-entry-written"
found_grader grade_passes "a file_contains grader on the spec passes once the list holds the entry at the typed location" "$tmp/not-git-entry-written"
found_grader grade_fails "and fails the spec as laid, the finding line with no entry" "$as_laid"
found_grader grade_fails "an entry at that location under another repository's name fails it" "$tmp/not-git-entry-for-another"
found_grader grade_fails "an entry for the repository at another location fails it" "$tmp/not-git-entry-elsewhere"

echo "# evals/location-typed-is-not-a-git-repository: a grader reads the close for the location's own line"
named="${repo:-no-repository-named}"
close_head="Published the ticket the breakdown adds to ${slug:-the feature}."
close_next="/do --auto .scratch/${slug:-none}/issues"
close_on() { # $1 name, $2 the lines between the close's head and its next command: a work folder closed on that message, its path on stdout
  mkdir -p "$tmp/$1"
  local gap=$'\n\n'
  closing_on "$tmp/$1" "$close_head$gap${2:+$2$gap}$close_next"
}
warned="$(close_on close-warned "- $named: $location is not a git repository.")"
silent="$(close_on close-silent "")"
only_missing="$(close_on close-only-missing "- $named: $location is missing, nothing exists there.")"
on_two_lines="$(close_on close-on-two-lines "The entry of $named was written at $location."$'\n'"One thing to fix: what sits there is not a git repository.")"
grader=""
for g in "$case_dir"/graders/*.md; do
  [ -f "$g" ] || continue
  [ "$(key "$g" type)" = regex ] && [ "$(key "$g" target)" = last_message ] || continue
  if [ -z "$(grade "$g" "$warned")" ] && [ -n "$(grade "$g" "$silent")" ]; then
    grader="$g"
    break
  fi
done
found_grader grade_passes "a regex grader on the last message passes a close with a line naming the location as not a git repository" "$warned"
found_grader grade_fails "and fails a close with no line on the location" "$silent"
found_grader grade_fails "a close that only says the location is missing fails it" "$only_missing"
found_grader grade_fails "a close naming the location on one line and the reason on another fails it" "$on_two_lines"

exit $((fails > 0))
