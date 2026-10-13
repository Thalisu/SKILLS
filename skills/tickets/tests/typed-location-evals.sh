#!/usr/bin/env bash
# typed-location-evals.sh: the eval cases that grade, on a live run, a location typed with the
# `tickets` command for a repository a stopped `do` run could name and not locate.
# Whoever changes skills/tickets/SKILL.md later has no other check that a typed location still
# reaches the Spec. A case whose fixture already lists the repository, whose prompt types no
# location, or whose graders never read the Spec stays green while the typed location is dropped,
# and the developer is back to editing the Spec by hand.
# The same holds for the stop on a location that is owed and was not typed: a case whose prompt types
# it, or whose graders accept a run that wrote a ticket or edited the Spec, stays green while
# `tickets` cuts a ticket naming a Build repository no `do` door can resolve.
# And for a typed location that is not a git repository, which is written and warned about rather than
# refused: a case whose fixture lays a real repository there, whose graders never read the Spec, or
# whose graders accept a close with no line on the location stays green while `tickets` refuses the
# location, drops it, or leaves the developer to learn of it when `do` refuses the ticket at its door.
# No model session runs here: each case is read the way a run of it would meet it, the fixture laid
# as scripts/run-eval.sh lays it, the prompt with the runner's {{fixture}} token replaced by the
# folder the fixture was laid in, and each grader run against a work folder.
# Run: bash skills/tickets/tests/typed-location-evals.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
evals="$here/../evals"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

source_grade
mapfile -t owed_location < <(owed_location_phrasings)
mapfile -t none_typed < <(none_typed_phrasings)
mapfile -t location_missing < <(location_missing_phrasings)
mapfile -t nothing_written < <(nothing_written_phrasings)
mapfile -t kept < <(kept_phrasings)
mapfile -t not_git < <(not_git_phrasings)
mapfile -t written_all_the_same < <(written_all_the_same_phrasings)
mapfile -t own_line < <(own_line_phrasings)
mapfile -t does_not_stop < <(does_not_stop_phrasings)
tr '[:upper:]' '[:lower:]' <"$evals/README.md" >"$tmp/evals.md" 2>/dev/null

# A case as a run of it starts: the fixture laid under a work folder, the feature it holds, the
# repository its finding leaves without a location, and the prompt.
lay_case() { # $1 case name
  # sets: case_dir, as_laid, fixture, spec, feature, slug, tickets, issues, finding, repo, sibling, prompt
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
  prompt="$(cat "$case_dir/prompt.md" 2>/dev/null)"
  label="the scaffold lays a feature folder with a spec"
  if [ "$scaffold_rc" = 0 ] && [ -n "$spec" ]; then ok "$label"; else
    fail "$label (scaffold exit $scaffold_rc)"
    echo "      extract: $(tail -1 "$tmp/extract.log")"
    echo "      scaffold: $(tail -1 "$tmp/scaffold.log")"
  fi
}
# The location the prompt types for a repository, as the session reads it once the runner replaced
# the token: the word after `<name>: ` on the /tickets line.
typed_location() { # $1 the repository's name: the location on stdout, empty when the prompt types none with the token
  local raw
  raw="$(awk -v pair=" $1: " 'index($0, "/tickets ") == 1 && (at = index($0, pair)) { split(substr($0, at + length(pair)), w, " "); print w[1]; exit }' <<<"$prompt")"
  case "$raw" in
    *'{{fixture}}'*) printf '%s\n' "${raw//'{{fixture}}'/$fixture}" ;;
  esac
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

echo "# evals/location-typed-with-the-command: the fixture owes the location the prompt types"
case_name="location-typed-with-the-command"
lay_case "$case_name"
owes_the_location
label="a git repository with a commit is laid beside the fixture root under that name"
if [ -n "$sibling" ] && [ "$(git -C "$sibling" rev-parse --show-toplevel 2>/dev/null)" = "$sibling" ] &&
  git -C "$sibling" rev-parse -q --verify HEAD >/dev/null 2>&1; then ok "$label"; else fail "$label"; fi

echo "# evals/location-typed-with-the-command: the prompt types the location with the command"
command_line="$(grep -E '^/tickets ' <<<"$prompt" | head -n 1)"
expect "the prompt types /tickets" test -n "$command_line"
expect "on the fixture's spec" grep -qF -- "$slug" <<<"$command_line"
typed="$(typed_location "${repo:-none}")"
expect "followed by the repository's name, a colon and a location written with the {{fixture}} token" \
  test -n "$typed"
label="once the token is the fixture root, the location is the repository laid beside it"
if [ -n "$sibling" ] && [ "$(cd "${typed:-/nonexistent}" 2>/dev/null && pwd -P)" = "$sibling" ]; then ok "$label"; else fail "$label"; fi

echo "# evals/location-typed-with-the-command: a grader reads the Spec for the entry"
location="${typed:-$as_laid/${repo:-none}}"
with_entry entry-written "- ${repo:-none}: $location"
with_entry entry-for-another "- some-other-service: $location"
with_entry entry-elsewhere "- ${repo:-none}: /srv/checkouts/elsewhere"
spec_entry_grader "$tmp/entry-written"
found_grader grade_passes "a file_contains grader on the spec passes once the list holds the entry at the typed location" "$tmp/entry-written"
found_grader grade_fails "and fails the spec as laid, the finding line with no entry" "$as_laid"
found_grader grade_fails "an entry at that location under another repository's name fails it" "$tmp/entry-for-another"
found_grader grade_fails "an entry for the repository at another location fails it" "$tmp/entry-elsewhere"

echo "# evals/location-typed-with-the-command: a grader holds the new ticket to that repository"
last="$(for t in "${tickets[@]}"; do basename "$t" | cut -d- -f1; done | sort -n | tail -n 1)"
next="$(printf '%02d' "$((10#${last:-0} + 1))")"
issues="$(mutated ticket-published)/issues"
mkdir -p "$issues"
ticket "$next-the-moved-behaviour.md" \
  "**Status:** ready-for-agent"$'\n\n'"**Kind:** logic"$'\n\n'"**Build repository:** ${repo:-none}" \
  "None (can start immediately)"
criteria=""
held=no
for g in "$case_dir"/graders/*.md; do
  [ -f "$g" ] || continue
  case "$(key "$g" type)" in
    llm) criteria="$criteria $(key "$g" criteria)" ;;
    file_contains)
      case "$(key "$g" path)" in
        *issues/*) ;;
        *) continue ;;
      esac
      # A ticket published under --auto is a file a code grader reads: built in the repository it
      # passes, and the feature as laid, where no ticket is, fails.
      [ -n "$(grade "$g" "$tmp/ticket-published")" ] || [ -z "$(grade "$g" "$as_laid")" ] || held=yes
      ;;
  esac
done
flat="$(tr '\n' ' ' <<<"$criteria" | tr -s ' ')"
flat="${flat,,}"
label="the new ticket of the breakdown is graded as built in the repository the finding names"
if [ "$held" = yes ]; then ok "$label"; else
  carries_each "$label" \
    "new ticket" "ticket it adds" "added ticket" "ticket of the breakdown" "ticket numbered" "$next" -- \
    "build repository" "built in" "cut for" "builds in" -- \
    "$(tr '[:upper:]' '[:lower:]' <<<"${repo:-no repository named}")" "repository the finding names" "repository the command names"
fi

echo "# skills/tickets/evals/README.md: the row of location-typed-with-the-command"
flat="$(checks_of "$case_name")"
expect "$case_name has a row" test -n "${flat// /}"
carries_each "which says the location is typed with the command" \
  "location" -- \
  "typed" "with the command" "on the command" "command carries" "command line"
carries_each "that the entry is written into the spec's repositories list" \
  "repositories" -- \
  "entry" "entries" -- \
  "writ" "gain" "added" "adds" "holds" "lands"
carries_each "and that the ticket is cut for that repository" \
  "ticket" -- \
  "build repository" "built in" "cut for" "builds in" "for that repository" "in that repository"

echo "# evals/location-owed-and-not-typed-stops: the fixture owes a location"
case_name="location-owed-and-not-typed-stops"
lay_case "$case_name"
owes_the_location

echo "# evals/location-owed-and-not-typed-stops: the prompt types the command and no location"
command_line="$(grep -E '^/tickets( |$)' <<<"$prompt" | head -n 1)"
read -ra typed_words <<<"$command_line"
expect "the prompt types /tickets" test -n "$command_line"
label="on the fixture's spec, and nothing after it"
if [ -n "$spec" ] && [ "${#typed_words[@]}" = 2 ] && grep -qF -- "$slug" <<<"${typed_words[1]}"; then ok "$label"; else
  fail "$label (typed: ${command_line:-nothing})"
fi
label="no pair names the repository the finding leaves without a location"
if [ -n "$prompt" ] && [ -n "$repo" ] && [ -z "$(typed_location "$repo")" ] &&
  ! grep -qF -- "$repo:" <<<"$prompt"; then ok "$label"; else fail "$label"; fi
label="and the prompt carries no {{fixture}} token"
if [ -n "$prompt" ] && ! grep -qF -- '{{fixture}}' <<<"$prompt"; then ok "$label"; else fail "$label"; fi

echo "# evals/location-owed-and-not-typed-stops: the graders hold the run to the stop"
with_entry owed-entry-written "- ${repo:-none}: /srv/checkouts/${repo:-none}"
criteria=""
held=no
for g in "$case_dir"/graders/*.md; do
  [ -f "$g" ] || continue
  if [ "$(key "$g" type)" = llm ]; then
    criteria="$criteria $(key "$g" criteria)"
    continue
  fi
  case "$(key "$g" path)" in
    *.scratch/*spec.md*) ;;
    *) continue ;;
  esac
  # A Spec that gained the entry is a file a code grader reads: as laid it passes, and with the
  # entry it fails.
  [ -n "$(grade "$g" "$as_laid")" ] || [ -z "$(grade "$g" "$tmp/owed-entry-written")" ] || held=yes
done
flat="$(tr '\n' ' ' <<<"$criteria" | tr -s ' ')"
flat="${flat,,}"
named="$(tr '[:upper:]' '[:lower:]' <<<"${repo:-no repository named}")"
expect "an llm grader judges the run" test -n "${flat// /}"
carries_each "the run ends on one message naming the repository whose location is missing" \
  "one message" "single message" "one short message" "a message" -- \
  "$named" -- \
  "location" -- \
  "${location_missing[@]}"
carries_each "no ticket file is created or edited" \
  "ticket" "issues" -- \
  "${nothing_written[@]}" "no ticket" "no new ticket" "no file" "no new file" "created or edited" \
  "not created" "not written" "${kept[@]}"
carries_each "the spec is left as it was" \
  "spec" -- \
  "${nothing_written[@]}" "${kept[@]}"
label="no entry for the repository is added to the spec's repositories list"
if [ "$held" = yes ]; then ok "$label"; else
  carries_each "$label" \
    "repositories" -- \
    "entry" "entries" "line" -- \
    "no entry" "no new entry" "no line" "no new line" "gained no" "gains no" "not added" "never added" \
    "adds no" "added no" "nothing added" "not written" "never written" "holds no" "still holds" \
    "${kept[@]}"
fi

echo "# skills/tickets/evals/README.md: the row of location-owed-and-not-typed-stops"
flat="$(checks_of "$case_name")"
expect "$case_name has a row" test -n "${flat// /}"
carries_each "which says a location is owed" \
  "location" -- \
  "${owed_location[@]}"
carries_each "and was not typed with the command" \
  "${none_typed[@]}" -- \
  "typed" "the command" "pair"
carries_each "that the run ends on one message naming the repository" \
  "one message" "single message" "one short message" "a message" -- \
  "repositor" "$named"
carries_any "and that nothing is written" "${nothing_written[@]}"

echo "# evals/location-typed-is-not-a-git-repository: the fixture owes the location, and no repository is there"
case_name="location-typed-is-not-a-git-repository"
lay_case "$case_name"
owes_the_location
expect "a directory is laid beside the fixture root under that name" test -n "$sibling" -a -d "${sibling:-/nonexistent}"
label="and it is not a git repository"
if [ -n "$sibling" ] && [ -d "$sibling" ] &&
  ! git -C "$sibling" rev-parse --is-inside-work-tree >/dev/null 2>&1; then ok "$label"; else fail "$label"; fi

echo "# evals/location-typed-is-not-a-git-repository: the prompt types that location, and the run reaches the close"
command_line="$(grep -E '^/tickets ' <<<"$prompt" | head -n 1)"
expect "the prompt types /tickets" test -n "$command_line"
expect "on the fixture's spec" grep -qF -- "$slug" <<<"$command_line"
typed="$(typed_location "${repo:-none}")"
expect "followed by the repository's name, a colon and a location written with the {{fixture}} token" \
  test -n "$typed"
label="once the token is the fixture root, the location is the plain directory laid beside it"
if [ -n "$sibling" ] && [ "$(cd "${typed:-/nonexistent}" 2>/dev/null && pwd -P)" = "$sibling" ]; then ok "$label"; else fail "$label"; fi
expect "under --auto, so the breakdown is published and the close is reached" \
  grep -qE '(^| )--auto( |$)' <<<"$command_line"
expect "the case unlinks the real choice-taker" \
  grep -qx "choice-taker" <(yq -r '.context.unlinked_agents // [] | .[]' "$case_dir/case.yaml" 2>/dev/null)
stand_in="$fixture/.claude/agents/choice-taker.md"
expect "the fixture holds the choice-taker stand-in" test -f "$stand_in"
flat="$(cat "$stand_in" 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
flat="${flat,,}"
carries_any "which rules to publish the breakdown" "publish"

echo "# evals/location-typed-is-not-a-git-repository: a grader reads the Spec for the entry as typed"
location="${typed:-$as_laid/fixture/../${repo:-none}}"
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

echo "# evals/location-typed-is-not-a-git-repository: the judges hold the run to the warning and nothing more"
criteria=""
for g in "$case_dir"/graders/*.md; do
  [ -f "$g" ] || continue
  [ "$(key "$g" type)" = llm ] || continue
  criteria="$criteria $(key "$g" criteria)"
done
flat="$(tr '\n' ' ' <<<"$criteria" | tr -s ' ')"
flat="${flat,,}"
expect "an llm grader judges the run" test -n "${flat// /}"
carries_each "the location is reported as not a git repository" \
  "location" "${named,,}" -- \
  "${not_git[@]}"
carries_each "and not as missing" \
  "missing" "does not exist" "nothing exists" "nothing is there" "nothing there" "not there" "absent" -- \
  "not as" "never as" "nor as" "rather than" "instead of" "and not " "not that"
carries_any "the run does not stop on it" \
  "${does_not_stop[@]}" "goes on" "went on" "carries on" "carried on" "continues" "continued"
carries_any "or ask about it" \
  "not ask" "never ask" "nor ask" "or ask" "asks no" "asked no" "asks nothing" "asked nothing" \
  "no question" "without asking"
carries_each "nothing is created, cloned or initialised at the location" \
  "nothing" "no " "not " "never" "nor " "neither" -- \
  "creat" "mkdir" "made" -- \
  "clon" -- \
  "initiali" "git init"

echo "# skills/tickets/evals/README.md: the row of location-typed-is-not-a-git-repository"
flat="$(checks_of "$case_name")"
expect "$case_name has a row" test -n "${flat// /}"
carries_each "which says the location typed with the command is not a git repository" \
  "location" -- \
  "typed" "with the command" "on the command" "command carries" "command line" -- \
  "${not_git[@]}"
carries_each "that the entry is written all the same" \
  "entry" "entries" -- \
  "writ" "gain" "added" "adds" "holds" "lands" -- \
  "${written_all_the_same[@]}" "still" "anyway" "although" "though" "despite" "even so" "and yet"
carries_each "and that the close names it in a line of its own" \
  "close" "closing" "last message" "final message" -- \
  "${own_line[@]}"

exit $((fails > 0))
