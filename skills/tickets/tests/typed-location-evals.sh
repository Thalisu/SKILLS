#!/usr/bin/env bash
# typed-location-evals.sh: the eval cases that grade, on a live run, a location typed with the
# `tickets` command for a repository a stopped `do` run could name and not locate.
# Whoever changes skills/tickets/SKILL.md later has no other check that a typed location still
# reaches the Spec. A case whose fixture already lists the repository, whose prompt types no
# location, or whose graders never read the Spec stays green while the typed location is dropped,
# and the developer is back to editing the Spec by hand.
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

echo "# evals/location-typed-with-the-command: the fixture owes the location the prompt types"
case_name="location-typed-with-the-command"
lay_case "$case_name"
expect "the spec holds a finding line whose location is not known" test -n "$finding"
expect "which names the repository the work belongs to" test -n "$repo"
passage_of "${spec:-/dev/null}" "## Repositories" "## " >"$tmp/repositories.md"
expect "the spec's repositories list holds the home repository's entry" \
  grep -qE '^- .+ \(Home repository\): /' "$tmp/repositories.md"
label="and no entry for the repository the finding names"
if [ -n "$repo" ] && ! grep -qE "^- ${repo}( \(|:)" "$tmp/repositories.md"; then ok "$label"; else fail "$label"; fi
label="a git repository with a commit is laid beside the fixture root under that name"
if [ -n "$sibling" ] && [ "$(git -C "$sibling" rev-parse --show-toplevel 2>/dev/null)" = "$sibling" ] &&
  git -C "$sibling" rev-parse -q --verify HEAD >/dev/null 2>&1; then ok "$label"; else fail "$label"; fi
expect "the feature has a ticket still open" \
  grep -qE '^\*\*Status:\*\* (ready-for-agent|claimed|needs-triage|needs-info)' "${tickets[@]:-/dev/null}"
label="no ticket covers the finding: none is built in that repository"
if [ "${#tickets[@]}" -gt 0 ] && [ -n "$repo" ] &&
  ! grep -qE "^\*\*Build repository:\*\* ${repo}\s*$" "${tickets[@]}"; then ok "$label"; else fail "$label"; fi

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
grader=""
for g in "$case_dir"/graders/*.md; do
  [ -f "$g" ] || continue
  [ "$(key "$g" type)" = file_contains ] || continue
  case "$(key "$g" path)" in
    *.scratch/*spec.md*) ;;
    *) continue ;;
  esac
  if [ -z "$(grade "$g" "$tmp/entry-written")" ] && [ -n "$(grade "$g" "$as_laid")" ]; then
    grader="$g"
    break
  fi
done
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

exit $((fails > 0))
