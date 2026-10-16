#!/usr/bin/env bash
# do-doc-playbooks.sh: docs/do.md, the page a developer browses for what to type, lists the `pr`
# Playbook among the Playbooks, says what matches it and what its run does, and shows `/do` typed
# with a pull request. A page still listing six Playbooks leaves them opening pull requests by hand,
# or typing a PR number and getting a Ticket run.
# Run: bash skills/do/tests/do-doc-playbooks.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
do_doc="$here/../../../docs/do.md"
fails=0

first_cell() { awk -F'|' '{ c = $2; gsub(/^ +| +$/, "", c); print c }' <<<"$1"; }
cell() { awk -F'|' -v n="$2" '{ c = $(n + 1); gsub(/^ +| +$/, "", c); print c }' <<<"$1"; } # $1 row, $2 the cell's index from 1

playbook_rows="$(passage_of "$do_doc" "## The Playbook" "## The door" | grep -E '^\| `')"
names="$(while IFS= read -r row; do first_cell "$row"; done <<<"$playbook_rows")"
pr_row="$(while IFS= read -r row; do [ "$(first_cell "$row")" = '`pr`' ] && printf '%s\n' "$row"; done <<<"$playbook_rows")"

echo "# docs/do.md / ## The Playbook: the table has a pr row saying what matches it and what its run does"
expect "the table has a row for the \`pr\` Playbook" test -n "$pr_row"
# shellcheck disable=SC2034 # lib.sh's carries_each reads $flat
flat="$(cell "$pr_row" 2)"
carries_each "its Matched by cell names a pull request URL" \
  "pull request" "PR" -- \
  "URL" "url"
carries_each "its Matched by cell names words naming a pull request with its number" \
  "pull request" "PR" -- \
  "number" "#"
flat="$(cell "$pr_row" 3)"
carries_any "its run cell says the run follows that pull request" "follow" "Follow"

echo "# docs/do.md / ## What it does: the Playbooks it lists are the table's, pr among them, and their count agrees"
flat="$(flat_section "$do_doc" "## What it does")"
carries "it names the \`pr\` Playbook" '`pr`'
missing=""
while IFS= read -r name; do
  grep -qF -- "$name" <<<"$flat" || missing="$missing $name"
done <<<"$names"
expect "it names every Playbook the table holds (missing:${missing:- none})" test -z "$missing"
count_word="$(grep -oE '(One|Two|Three|Four|Five|Six|Seven|Eight|Nine|Ten|[0-9]+) Playbooks exist' <<<"$flat" | head -n 1 | cut -d' ' -f1)"
want_word="$(sed -n "$(grep -c . <<<"$names")p" <<<$'One\nTwo\nThree\nFour\nFive\nSix\nSeven\nEight\nNine\nTen')"
expect "the count it states (${count_word:-none}) is the table's (${want_word})" \
  test -z "$count_word" -o "$count_word" = "$want_word" -o "$count_word" = "$(grep -c . <<<"$names")"

echo "# docs/do.md / ## When to reach for it: a row types /do with a pull request"
ask_rows="$(passage_of "$do_doc" "## When to reach for it" "## " | grep -E '^\| ' | tail -n +3)"
pr_ask="$(while IFS= read -r row; do
  use="$(cell "$row" 2)"
  grep -qF '/do ' <<<"$use" && grep -qE 'pull request|PR' <<<"$use" && printf '%s\n' "$row"
done <<<"$ask_rows")"
expect "a row's Use cell types \`/do\` with a pull request" test -n "$pr_ask"

[ "$fails" -eq 0 ] && exit 0
exit 1
