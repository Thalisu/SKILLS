#!/usr/bin/env bash
# pr-playbook.sh: what `/do` does with a request that carries a pull request. A row of the router's
# table whose Match is `pr` takes a pull request URL, as in `acompanhe esse PR <url>`, and sits above
# the `setup` row, the `ticket` row and the two `Playbook: none` rows for an issue reference, any of
# which would otherwise catch the URL first and read it as a Ticket or refuse it as an issue.
# The `pr` Playbook's reference is references/pr.md, titled `# Playbook: pr` and named in SKILL.md's
# Links (a matched Playbook whose reference Links lacks reads `Playbook: none`), and its message
# opens with `Playbook: pr` on its first line.
# The route and the message are prose a session follows, so they are proven over the passages that
# carry them.
# Run: bash skills/do/tests/pr-playbook.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/../SKILL.md"
pr="$here/../references/pr.md"
fails=0

router="$(passage_of "$skill" "## Router" "## ")"
rows="$(grep -E '^\| ' <<<"$router")"
# A row's argument is its first cell: the rows an issue reference reaches name it there.
argument_of() { awk -F'|' '{ print $2 }' <<<"$1"; }
pr_at=0
setup_at=0
ticket_at=0
issue_at=0
pr_row=""
n=0
while IFS= read -r line; do
  n=$((n + 1))
  case "$(match_of "$line")" in
    '`pr`') [ "$pr_at" = 0 ] && pr_at="$n" && pr_row="$line" ;;
    '`setup`') [ "$setup_at" = 0 ] && setup_at="$n" ;;
    '`ticket`') [ "$ticket_at" = 0 ] && ticket_at="$n" ;;
  esac
  if [ "$issue_at" = 0 ] && grep -qiE 'issue (reference|number)' <<<"$(argument_of "$line")"; then
    issue_at="$n"
  fi
done <<<"$rows"

echo "# SKILL.md / ## Router: a pull request URL routes to the pr Playbook, above every row an issue reference reaches"
expect "the table has a row whose Match is \`pr\`" test "$pr_at" -gt 0
flat="$(argument_of "$pr_row")"
carries_each "the pr row matches a pull request URL" \
  "pull request" "PR" -- \
  "URL" "url"
expect "the pr row sits above the setup row" test "$pr_at" -gt 0 -a "$setup_at" -gt "$pr_at"
expect "the pr row sits above the ticket row" test "$pr_at" -gt 0 -a "$ticket_at" -gt "$pr_at"
expect "the pr row sits above every row an issue reference or number reaches" \
  test "$pr_at" -gt 0 -a "$issue_at" -gt "$pr_at"

echo "# SKILL.md / ## Links: pr.md is the pr Playbook"
flat="$(bullets_opening_on <(passage_of "$skill" "## Links" "## ") "references/pr.md")"
expect "Links carries an entry for references/pr.md" test -n "$flat"
carries "the entry names it the pr Playbook" "\`pr\`" "Playbook"

echo "# pr.md / ## The message: the reply opens on Playbook: pr"
expect "the pr Playbook's reference exists" test -f "$pr"
expect "pr.md is titled # Playbook: pr" test "$(head -n 1 "$pr" 2>/dev/null)" = "# Playbook: pr"
flat="$(passage_of "$pr" "## The message" "## " 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
carries "the message names the pr Playbook" "Playbook: pr"
carries_any "on its first line" \
  "first line" "First line" "opens with" "opens on" "opening line" "line one" "the reply opens"

[ "$fails" -eq 0 ] && exit 0
exit 1
