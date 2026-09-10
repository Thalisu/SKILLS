#!/usr/bin/env bash
# contract.sh: the parts of journey's contract a script can check, its door to a bare slug above
# all. Run: bash skills/journey/tests/contract.sh
# shellcheck disable=SC2016
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
skill="$here/.."
fails=0

expect() { # $1 label, $2.. a command that must succeed
  local label="$1"; shift
  if "$@"; then echo "ok    $label"; else echo "FAIL  $label"; fails=$((fails + 1)); fi
}

# The resolver is the one executable form of the slug rule, so the door calls it and restates
# nothing of it. The prose is read as one line, so a phrase still counts where the paragraph wraps it.
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

# dated-slug-newest: two dated feature folders for one slug, the bare slug in the prompt. The eval
# runner is gated on this machine, so the fixture is run here and put to the resolver itself: a
# grader expecting the newest spec is only right while the resolver answers with it.
case="$skill/evals/dated-slug-newest"
resolver="$skill/../../.agents/scripts/resolve-feature-folder.sh"
emdash="$(printf '\342\200\224')"
expect "the case file exists" test -f "$case/case.yaml"
expect "the prompt passes the bare slug" bash -c 'test "$(cat "$1")" = "/journey suppliers"' _ "$case/prompt.md"
expect "a grader expects the newest spec" grep -qF '20260905-suppliers' "$case/graders/newest-spec-opened.md"
expect "a grader expects the resolver called" grep -qF 'resolve-feature-folder.sh' "$case/graders/resolver-called.md"
expect "the README lists the case" grep -qF '| `dated-slug-newest` |' "$skill/evals/README.md"
# The index tells a maintainer which branch of the door each case takes, tracker file or none, so a
# case whose scaffold writes no tracker file is named there as the exception.
index="$(tr '\n' ' ' < "$skill/evals/README.md" | tr -s ' ')"
for c in "$skill"/evals/*/case.yaml; do
  grep -qF 'docs/agents/issue-tracker.md' "$c" && continue
  name="$(basename "$(dirname "$c")")"
  expect "the README names $name as the fixture with no tracker file" \
    grep -qF "except \`$name\`, which carries no tracker file" <<<"$index"
done
expect "no em-dash in the case" bash -c '! grep -rqF "$1" "$2"' _ "$emdash" "$case"
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT
awk '/^  scaffold_script: \|/ { f = 1; next } f && /^    / { sub(/^    /, ""); print; next } f && /^[[:space:]]*$/ { print ""; next } f { exit }' \
  "$case/case.yaml" > "$tmp/scaffold.sh" 2>/dev/null
mkdir -p "$tmp/fixture"
expect "the scaffold runs" bash -c 'test -s "$1" && cd "$2" && bash "$1" >/dev/null 2>&1' _ "$tmp/scaffold.sh" "$tmp/fixture"
expect "the fixture holds two dated folders for the slug" \
  test -f "$tmp/fixture/.scratch/20260801-suppliers/spec.md" -a -f "$tmp/fixture/.scratch/20260905-suppliers/spec.md"
out="$(cd "$tmp/fixture" && bash "$resolver" suppliers 2>&1)"
expect "the resolver names the newest spec in the fixture" \
  grep -qxF 'spec=.scratch/20260905-suppliers/spec.md' <<<"$out"

# The documentation page is where a person reads the rule the skill no longer spells out, so it
# states it the way the resolver's own header does, normalisation included, and names the script.
page="$(tr '\n' ' ' < "$skill/../../docs/journey.md" | tr -s ' ')"
expect "the page names the resolver" grep -qF 'resolve-feature-folder.sh' <<<"$page"
expect "the page states the slug is normalised" \
  grep -qF 'lowercased, every other character becomes a dash' <<<"$page"
expect "the page states a date typed with the slug is dropped" \
  grep -qF 'a date typed in front of it is dropped' <<<"$page"
expect "the page states the two folder names and no other" \
  grep -qF '`<slug>` or `<YYYYMMDD>-<slug>` and no other' <<<"$page"
expect "the page states the newest dated folder wins" grep -qF 'the newest of them' <<<"$page"
expect "the page states an undated folder wins over every dated one" \
  grep -qF 'an undated folder from before the dated rule over every dated one' <<<"$page"
expect "the page states a tail match is never taken" \
  grep -qF 'never a folder that only ends in the slug' <<<"$page"
expect "the page restates no tail match as the rule" bash -c '! grep -qF "ending in" <<<"$1"' _ "$page"

if [ "$fails" = 0 ]; then echo "PASS"; else echo "$fails failing"; exit 1; fi
