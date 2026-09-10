#!/usr/bin/env bash
# contract.sh: the parts of tickets' contract a script can check, its door to a bare slug above
# all. Run: bash skills/tickets/tests/contract.sh
# shellcheck disable=SC2016
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
skill="$here/.."
fails=0

expect() { # $1 label, $2.. a command that must succeed
  local label="$1"; shift
  if "$@"; then echo "ok    $label"; else echo "FAIL  $label"; fails=$((fails + 1)); fi
}

# The resolver is the one executable form of the slug rule, the one journey's door calls too, so
# the two steps of the chain open the same spec for one slug. The prose is read as one line, so a
# phrase still counts where the paragraph wraps it.
text="$(tr '\n' ' ' < "$skill/SKILL.md" | tr -s ' ')"
expect "the door calls the resolver through the skill's own folder" \
  grep -qF 'bash <skill-dir>/../../.agents/scripts/resolve-feature-folder.sh <slug>' <<<"$text"
expect "the door names the resolver as the rule's one implementation" \
  grep -qF 'the one executable form of the rule' <<<"$text"
expect "the door reads the Spec off the resolver's spec= line" grep -qF '`spec=`' <<<"$text"
expect "the door restates no tail match" bash -c '! grep -qF "ending in" <<<"$1"' _ "$text"
expect "the door restates no newest-wins rule of its own" bash -c '! grep -qF "the newest when" <<<"$1"' _ "$text"
expect "the hop the door names reaches the resolver" test -f "$skill/../../.agents/scripts/resolve-feature-folder.sh"

# A slug that names nothing, a refusal, and a resolver the session cannot find all end the run in
# the one stop it already has, and never in a guess at the rule.
expect "the stop covers spec=none" grep -qF '`spec=none`' <<<"$text"
expect "the stop covers a refusal" grep -qF 'exits 2' <<<"$text"
expect "the stop covers a resolver the session cannot find" \
  grep -qF 'a resolver the session cannot find' <<<"$text"
expect "the stop asks for the spec's path" grep -qF 'one message asking for the path' <<<"$text"

# dated-slug: a dated feature folder for the slug, beside a newer neighbour whose name only ends in
# the slug, the bare slug in the prompt. The eval runner is gated on this machine, so the fixture is
# run here and put to the resolver itself: a grader expecting the dated spec is only right while
# the resolver answers with it, and never with the neighbour a tail match would have taken.
case="$skill/evals/dated-slug"
resolver="$skill/../../.agents/scripts/resolve-feature-folder.sh"
emdash="$(printf '\342\200\224')"
expect "the case file exists" test -f "$case/case.yaml"
expect "the prompt passes the bare slug" bash -c 'test "$(cat "$1")" = "/tickets archive-notes"' _ "$case/prompt.md"
expect "a grader expects the dated spec cut" grep -qF '20260901-archive-notes' "$case/graders/dated-spec-cut.md"
expect "a grader expects the resolver called" grep -qF 'resolve-feature-folder.sh' "$case/graders/resolver-called.md"
expect "the README lists the case" grep -qF '| `dated-slug` |' "$skill/evals/README.md"
expect "no em-dash in the case" bash -c '! grep -rqF "$1" "$2"' _ "$emdash" "$case"
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT
scaffold_of() { # $1 case folder: the scaffold_script block of its case file
  awk '/^  scaffold_script: \|/ { f = 1; next } f && /^    / { sub(/^    /, ""); print; next } f && /^[[:space:]]*$/ { print ""; next } f { exit }' \
    "$1/case.yaml" 2>/dev/null
}
scaffold_of "$case" > "$tmp/scaffold.sh"
mkdir -p "$tmp/fixture"
expect "the scaffold runs" bash -c 'test -s "$1" && cd "$2" && bash "$1" >/dev/null 2>&1' _ "$tmp/scaffold.sh" "$tmp/fixture"
expect "the fixture holds the dated folder and the newer neighbour" \
  test -f "$tmp/fixture/.scratch/20260901-archive-notes/spec.md" -a -f "$tmp/fixture/.scratch/20260905-bulk-archive-notes/spec.md"
out="$(cd "$tmp/fixture" && bash "$resolver" archive-notes 2>&1)"
expect "the resolver names the dated spec in the fixture, not the neighbour" \
  grep -qxF 'spec=.scratch/20260901-archive-notes/spec.md' <<<"$out"

# unknown-slug-stops: a bare slug that names no feature folder, beside a neighbour whose folder only
# ends in it. A grader expecting the stop is only right while the resolver answers none there.
stop="$skill/evals/unknown-slug-stops"
expect "the stop case's prompt passes the bare slug" bash -c 'test "$(cat "$1")" = "/tickets archive-notes"' _ "$stop/prompt.md"
expect "the README lists the stop case" grep -qF '| `unknown-slug-stops` |' "$skill/evals/README.md"
expect "no em-dash in the stop case" bash -c '! grep -rqF "$1" "$2"' _ "$emdash" "$stop"
scaffold_of "$stop" > "$tmp/stop.sh"
mkdir -p "$tmp/stop"
expect "the stop case's scaffold runs" bash -c 'test -s "$1" && cd "$2" && bash "$1" >/dev/null 2>&1' _ "$tmp/stop.sh" "$tmp/stop"
expect "the stop case's fixture holds only the neighbour" test -f "$tmp/stop/.scratch/20260905-bulk-archive-notes/spec.md"
out="$(cd "$tmp/stop" && bash "$resolver" archive-notes 2>&1)"
expect "the resolver names no spec in the stop case's fixture" grep -qxF 'spec=none' <<<"$out"

if [ "$fails" = 0 ]; then echo "PASS"; else echo "$fails failing"; exit 1; fi
