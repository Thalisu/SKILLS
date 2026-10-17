#!/usr/bin/env bash
# negated-decisions.sh: the prose cases of additive-breakdown.sh and typed-location.sh turn red when
# the SKILL.md sentence they pin says the opposite. A case that stays green over a negated decision
# proves only that a set of words is on the page.
# Each case runs one of the two scripts inside a copy of this repo whose skills/tickets/SKILL.md had
# one sentence negated. This repo's own SKILL.md is never written to.
# Run: bash skills/tickets/tests/negated-decisions.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
root="$(cd "$here/../../.." && pwd -P)"
skill_path="skills/tickets/SKILL.md"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

mirror_of() { # $1 name: a copy of every tracked and untracked, unignored file of this repo, at $tmp/<name>
  mkdir "$tmp/$1"
  (cd "$root" && git ls-files -z --cached --others --exclude-standard |
    cpio -0pdm --quiet "$tmp/$1" 2>/dev/null)
}

run_in() { # $1 mirror name, $2 a test script of the tickets skill: its combined output in $ran, its exit in $ran_rc
  ran="$(cd "$tmp/$1" && bash "skills/tickets/tests/$2" 2>&1)"
  ran_rc=$?
}

stays_green() { # $1 label, $2 mirror name, $3 script: exit 0 and no FAIL line
  run_in "$2" "$3"
  if [ "$ran_rc" = 0 ] && ! grep -q '^FAIL' <<<"$ran"; then ok "$1"; else
    fail "$1 (exit $ran_rc)"
    grep '^FAIL' <<<"$ran" | sed 's/^/      /'
  fi
}

fails_when() { # $1 label, $2 mirror name, $3 script, $4 a perl substitution over SKILL.md, $5.. the case labels that must be reported as FAIL
  local label="$1" name="$2" script="$3" substitution="$4" missing=() case_label
  shift 4
  mirror_of "$name"
  perl -0pi -e "$substitution" "$tmp/$name/$skill_path"
  if cmp -s "$root/$skill_path" "$tmp/$name/$skill_path"; then
    fail "$label (the substitution changed nothing in SKILL.md)"
    return
  fi
  run_in "$name" "$script"
  for case_label in "$@"; do
    grep -qF -- "FAIL  $case_label" <<<"$ran" || missing+=("$case_label")
  done
  if [ "${#missing[@]}" = 0 ] && [ "$ran_rc" != 0 ]; then ok "$label"; else
    fail "$label (exit $ran_rc)"
    [ "${#missing[@]}" = 0 ] || printf '      no FAIL line for: %s\n' "${missing[@]}"
  fi
}

echo "# control: SKILL.md as it stands"
mirror_of control
stays_green "additive-breakdown.sh is green over SKILL.md as it stands" control additive-breakdown.sh
stays_green "typed-location.sh is green over SKILL.md as it stands" control typed-location.sh

echo "# additive-breakdown.sh: the run that goes on over what is uncovered"
fails_when "additive-breakdown.sh fails when the run is said to never go on" \
  never-goes-on additive-breakdown.sh \
  's/the run goes on and cuts only what is uncovered/the run never goes on and cuts only what is uncovered/' \
  "the run goes on when the open tickets leave something uncovered" \
  "it cuts only what is uncovered"

echo "# typed-location.sh: the bad location that is written all the same"
fails_when "typed-location.sh fails when nothing of the entry is said to stay as written" \
  nothing-stays typed-location.sh \
  's/the entry stays as written/nothing of the entry stays as written/' \
  "a location failing either check is written all the same"
fails_when "typed-location.sh fails when the run is said to stop on a bad location" \
  stops-on-it typed-location.sh \
  's/The run does not stop on it and asks nothing about it/For a bad one it stops and asks nothing about it/' \
  "the run does not stop on it and asks nothing about it"

exit $((fails > 0))
