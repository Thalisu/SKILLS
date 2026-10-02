#!/usr/bin/env bash
# check-reading-map.sh: the contract of scripts/check-reading-map.sh, which checks that every
# heading a case file under .agents/reading/ cites still exists in the file it points at, exercised
# against throwaway roots. Run: bash scripts/tests/check-reading-map.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/lib.sh"
checker="$here/../check-reading-map.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

run() { # $1 the root holding .agents/, this repo when left out: the checker's output in $out, its exit in $rc
  rc=0
  out="$(bash "$checker" "$@" 2>&1)" || rc=$?
}

# The guideline files are refreshed by re-fetch, so a heading can be renamed under the map: the
# case file still cites it, and the reader it sends there finds nothing.
root="$tmp/renamed"
mkdir -p "$root/.agents/reading" "$root/.agents/guide"
cat >"$root/.agents/guide/page.md" <<'MD'
# Guide

## Basics

### Be clear

Say what you want.

### Renamed heading

It used to be called something else.
MD
cat >"$root/.agents/reading/some-task.md" <<'MD'
# Some task

| File | Section | Read |
|---|---|---|
| `.agents/guide/page.md` | ### Be clear | whole section |
| `.agents/guide/page.md` | ### Gone heading | whole section |
MD
run "$root"
check_lines "a cited heading the target file lacks is named and fails the check" 1 "$rc" \
  "missing .agents/reading/some-task.md: .agents/guide/page.md ### Gone heading"
absent "a cited heading the target file has is not reported" \
  "missing .agents/reading/some-task.md: .agents/guide/page.md ### Be clear"

# The guideline files quote sample documents inside code fences, and nest a three-backtick block in
# a four-backtick one: the inner closing line does not close the outer block, so a heading after it
# is still part of the sample and no section a reader can be sent to.
root="$tmp/fenced"
mkdir -p "$root/.agents/reading" "$root/.agents/guide"
cat >"$root/.agents/guide/page.md" <<'MD'
# Guide

## Real section

Structure the report the way the sample does.

````markdown
## Report structure

```markdown
# [Analysis Title]
```

## Still inside the outer fence
````
MD
cat >"$root/.agents/reading/some-task.md" <<'MD'
# Some task

| File | Section | Read |
|---|---|---|
| `.agents/guide/page.md` | ## Real section | whole section |
| `.agents/guide/page.md` | ## Still inside the outer fence | whole section |
MD
run "$root"
check_lines "a cited heading whose only matching line sits inside a fenced code block is reported missing" 1 "$rc" \
  "missing .agents/reading/some-task.md: .agents/guide/page.md ## Still inside the outer fence"
absent "a cited heading outside any fence, in a file that also holds fenced ones, is not reported" \
  "missing .agents/reading/some-task.md: .agents/guide/page.md ## Real section"

# A re-fetch can add a second heading with the same text under another parent: the reader opens the
# first line its search returns, so a heading that matches twice sends it to the wrong section.
root="$tmp/repeated"
mkdir -p "$root/.agents/reading" "$root/.agents/guide"
cat >"$root/.agents/guide/page.md" <<'MD'
# Guide

## Setup

Install it first.

## Frontend

### Testing

Render the component and read the screen.

## Backend

### Testing

Call the endpoint and read the response.
MD
cat >"$root/.agents/reading/some-task.md" <<'MD'
# Some task

| File | Section | Read |
|---|---|---|
| `.agents/guide/page.md` | ## Setup | whole section |
| `.agents/guide/page.md` | ### Testing | whole section |
MD
run "$root"
check_lines "a cited heading the target file holds twice is named ambiguous and fails the check" 1 "$rc" \
  "ambiguous .agents/reading/some-task.md: .agents/guide/page.md ### Testing (2 matches)"
absent "a cited heading the target file holds once, beside a repeated one, is not reported" \
  ".agents/guide/page.md ## Setup"

# Exit 0 reads as "every cited section is still there": a map folder that was moved, renamed or
# emptied leaves nothing to check, and a clean exit there would pass a map nobody looked at.
root="$tmp/no-map"
mkdir -p "$root/.agents/guide"
cat >"$root/.agents/guide/page.md" <<'MD'
# Guide

## Basics

Say what you want.
MD
run "$root"
check_lines "a root with no map row to check fails the check and says it found no anchors" 1 "$rc" \
  "no anchors under .agents/reading/"

# The fixtures above prove the rule; this runs it over the map agents actually read, so a refreshed
# guideline copy that renames a cited heading turns the suite red. A failure dumps the checker's
# output, which names each bad anchor.
run
check "every section this repository's read map cites exists exactly once in the file it points at" 0 "$rc"

[ "$fails" = 0 ]
