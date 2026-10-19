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
reply="$here/../references/reply.md"
fails=0

router="$(passage_of "$skill" "## Router" "## ")"
rows="$(grep -E '^\| ' <<<"$router")"
# A row's argument is its first cell: the rows an issue reference reaches name it there.
argument_of() { awk -F'|' '{ print $2 }' <<<"$1"; }
pr_at=0
setup_at=0
ticket_at=0
issue_at=0
bug_fix_at=0
integrate_at=0
pr_row=""
n=0
while IFS= read -r line; do
  n=$((n + 1))
  case "$(match_of "$line")" in
    '`pr`') [ "$pr_at" = 0 ] && pr_at="$n" && pr_row="$line" ;;
    '`setup`') [ "$setup_at" = 0 ] && setup_at="$n" ;;
    '`ticket`') [ "$ticket_at" = 0 ] && ticket_at="$n" ;;
    '`bug-fix`') [ "$bug_fix_at" = 0 ] && bug_fix_at="$n" ;;
    '`integrate`') [ "$integrate_at" = 0 ] && integrate_at="$n" ;;
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

# The `ticket` row takes an issue number, so "PR 12" missing the pr row runs a Ticket on issue 12.
echo "# SKILL.md / ## Router: words naming a pull request and its number, with no URL, route to the pr Playbook"
flat="$(argument_of "$pr_row")"
carries_each "the pr row matches a pull request named by its number, as in \`PR 12\` or \`pull request #12\`" \
  "pull request" "PR" -- \
  "number" "#" "<n>" "<number>"

# A bug-fix run fixes on a branch of its own and never follows the pull request back to green.
echo "# SKILL.md / ## Router: a request to fix a named pull request's CI routes to the pr Playbook, not bug-fix"
flat="$(argument_of "$pr_row")"
carries_each "the pr row matches a request to fix that pull request's CI, as in \`fix the CI of PR 12\`" \
  "fix" "Fix" -- \
  "CI" "checks" "pipeline"
expect "the pr row sits above the bug-fix row" test "$pr_at" -gt 0 -a "$bug_fix_at" -gt "$pr_at"

# The pr row sits above the ticket row, so a pr row that reads "its number" loosely steals the issue
# number a developer starts a Ticket run with.
echo "# SKILL.md / ## Router: a bare number, with no word naming a pull request, still routes to the ticket Playbook"
flat="$(argument_of "$pr_row")"
carries_each "the pr row leaves a bare number, as in \`12\` or \`#12\`, to the rows below it" \
  "bare number" "number alone" "number on its own" "number by itself" "lone number" \
  "number with no word" "number without a word" -- \
  "next row" "rows below" "row below" "goes on" "falls through" "falls to" "left to"
flat="$(argument_of "$(sed -n "${ticket_at}p" <<<"$rows")")"
carries_any "the ticket row below it still takes an issue number" "number"

# A read-back built from the session's own wording repeats whatever it misread: only the pull request
# gh opens names the number and the two branches the run will actually follow.
echo "# pr.md / ## Steps and ### 2. Read-back: the Plan: line reads the pull request back off gh's answer, never off the request's wording"
steps="$(blocks_of "$pr" "## Steps" 2>/dev/null)"
flat="$(grep -E '^1\. ' <<<"$steps")"
carries_any "step 1 of the checklist takes the pull request from the request" "pull request"
flat="$(grep -E '^2\. ' <<<"$steps")"
carries_any "step 2 of the checklist is the read-back, before the run acts on the pull request" \
  "read-back" "read back" "Read-back"
flat="$(passage_of "$pr" "### 2. Read-back" "##" 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
carries_each "the line names the pull request by its number, its head into its base" \
  "#<n>" -- "<head>" -- "<base>" -- "into"
before "the head comes before the base it goes into" "<head>" "<base>"
carries_each "the line is read off the GitHub CLI's answer for that pull request" \
  "gh pr view" -- "headRefName" -- "baseRefName"
carries_any "never off the session's wording" \
  "never off the session's wording" "never the session's wording" "never from the session's wording" \
  "not off the session's wording" "not the session's wording" "not from the session's wording" \
  "never off the request's wording" "never the request's wording" "never from the request's wording" \
  "not off the request's wording" "not the request's wording" "not from the request's wording"
carries_each "it is recorded as the Reply's Plan: line" \
  "Plan:" -- "Reply" "reply"

# A session tells "PR 12" from issue 12, and a CI fix from a bug, by the examples under the table.
# Each example opens on its backticked request, then `: ` and its backticked Playbook.
routed_examples() { # the Router's <example> blocks: request, Playbook and the example flattened, tab-separated, one per line
  awk '/^<example>$/ { on = 1; text = ""; next } /^<\/example>$/ { on = 0; print text; next } on { text = text " " $0 }' \
    <<<"$router" | sed -E 's/^ +//' |
    sed -nE 's/^`([^`]*)`: `([^`]*)`(.*)$/\1\t\2\t&/p'
}
examples="$(routed_examples)"
echo "# SKILL.md / ## Router <examples>: one request for each pull request match, and a bare number to ticket"
expect "an example routes a pull request URL to \`pr\`" test -n \
  "$(awk -F'\t' '$2 == "pr" && tolower($1) ~ /https?:\/\/[^ ]*\/pull\/[0-9]+/' <<<"$examples")"
expect "an example routes a pull request named with its number, with no URL, to \`pr\`" test -n \
  "$(awk -F'\t' '$2 == "pr" && tolower($1) !~ /:\/\// && tolower($1) !~ /(^|[^a-z])(ci|checks?|pipeline)([^a-z]|$)/ && tolower($1) ~ /(^|[^a-z])(pr|pull request) *#?[0-9]+/' <<<"$examples")"
ci_example="$(awk -F'\t' '$2 == "pr" && tolower($1) ~ /fix|conserta|corrig/ && $1 ~ /CI|[Cc]hecks|[Pp]ipeline/ && tolower($1) ~ /(^|[^a-z])(pr|pull request)/' <<<"$examples")"
expect "an example routes a request to fix a pull request's CI to \`pr\`" test -n "$ci_example"
flat="$ci_example"
carries_any "that example names \`bug-fix\` as the near miss it is not" "not \`bug-fix\`" "never \`bug-fix\`"
expect "an example routes a bare number, with no word naming a pull request, to \`ticket\`" test -n \
  "$(awk -F'\t' '$2 == "ticket" && $1 ~ /^#?[0-9]+$/' <<<"$examples")"

# A request for a pull request between two branches names both of them, as an integration does: a
# session that reads it as `integrate` rebases or merges `dev` into `prod` itself, and one that reads
# `dev` as the base opens the pull request the wrong way round.
echo "# SKILL.md / ## Router: words asking for a pull request from one branch into another route to the pr Playbook, not integrate"
flat="$(argument_of "$pr_row")"
carries_each "the pr row matches words asking for a pull request from one branch into another, as in \`faça um PR de dev para prod\`" \
  "pull request" "PR" -- \
  "from one branch into another" "from a branch into another" "one branch into another" "branch into another" \
  "from one branch to another" "branch pair" "pair of branches" "two branches"
carries_each "naming the branch it comes from its head and the one it goes into its base" \
  "head" -- "base"
expect "the pr row sits above the integrate row" test "$pr_at" -gt 0 -a "$integrate_at" -gt "$pr_at"
branch_pair_example="$(awk -F'\t' '$2 == "pr" && $1 == "faça um PR de dev para prod"' <<<"$examples")"
expect "an example routes \`faça um PR de dev para prod\` to \`pr\`" test -n "$branch_pair_example"
flat="$branch_pair_example"
carries_any "that example names \`integrate\` as the near miss it is not" "not \`integrate\`" "never \`integrate\`"

# A logged-out gh fails the read-back as if the pull request were wrong: the developer whose session
# expired reads a refusal blaming the pull request, or a choice where one input is broken, and types
# the same request again.
echo "# pr.md: a GitHub CLI that is not logged in stops the run before the read-back, naming gh auth login and following nothing"
auth_step="$(item_holding "$pr" '### ' "gh auth login" 2>/dev/null)"
expect "a step of pr.md names \`gh auth login\`" test -n "$auth_step"
auth_heading_at="$(grep -nxF -- "$(head -n 1 <<<"$auth_step")" "$pr" 2>/dev/null | head -n 1 | cut -d: -f1)"
read_back_at="$(grep -nE '^### [0-9]+\. Read-back' "$pr" 2>/dev/null | head -n 1 | cut -d: -f1)"
expect "that step comes before the read-back's first call to gh" \
  test -n "$auth_step" -a "${auth_heading_at:-0}" -gt 0 -a "${read_back_at:-0}" -gt "${auth_heading_at:-0}"
flat="$(tr '\n' ' ' <<<"$auth_step" | tr -s ' ')"
carries_any "it asks the GitHub CLI whether it is logged in" \
  "gh auth status" "gh auth token" "gh api user"
carries_any "and stops when that check fails" \
  "fails" "non-zero" "not logged in" "logged out" "no session" "expired"
carries_each "the stop is one line naming \`gh auth login\`" \
  "gh auth login" -- \
  "one line" "One line" "single line" "a line naming" "a line that names"
carries "the stop names the pr Playbook" "Playbook: pr"
carries_any "on its first line" \
  "first line" "First line" "opens with" "opens on" "opening line" "line one" "the reply opens"
carries_any "with no \`Yours:\` line" \
  "no \`Yours:\`" "No \`Yours:\`" "without a \`Yours:\`" "without the \`Yours:\`" "never a \`Yours:\`" \
  "not a \`Yours:\`" "no Yours:" "without a Yours:"
carries_any "and follows nothing: no read-back, no watch, no worktree, no push, no file written" \
  "follows nothing" "nothing is followed" "nothing followed" "follows none" "follows no step" \
  "no step after" "no later step" "no further step" "runs nothing else" "nothing else runs" "does nothing else"

# A machine with no gh fails the auth check with the shell's "command not found", which reads as a
# broken run instead of a CLI to install, or lets the run go on without the pull request.
echo "# pr.md: a GitHub CLI that is not installed takes the same stop as one not logged in"
flat="$(tr '\n' ' ' <<<"$auth_step" | tr -s ' ')"
carries_any "the step that names \`gh auth login\` covers a \`gh\` missing from the PATH" \
  "not installed" "isn't installed" "is not on the PATH" "not on the \`PATH\`" "not on the PATH" \
  "missing from the PATH" "missing from the \`PATH\`" "no \`gh\` on the" "no gh on the" \
  "command not found" "\`gh\` is missing" "gh is missing" "absent from the PATH" "absent from the \`PATH\`"
carries_any "and stops it the same way, with the line naming \`gh auth login\`" \
  "same stop" "same line" "same way" "the same one line" "stops the same" "either case" "both cases" \
  "either way" "in both" "as when" "as for" "likewise" "also stops" "stops too" "too stops"

# A wrong number, or a URL of a repository gh cannot reach, leaves the read-back with no answer to
# read: a session that goes on invents a read-back, or a watch, for a pull request that is not there.
# The passage already speaks of "the Reply's first lines", so a bare "first line" proves nothing here.
echo "# pr.md / ### 2. Read-back: a pull request gh cannot open stops the run with one line on Playbook: pr, following nothing"
flat="$(passage_of "$pr" "### 2. Read-back" "##" 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
carries_any "the read-back stops when \`gh pr view\` fails to open the pull request" \
  "fails" "non-zero" "errors" "an error" "cannot open" "can't open" "could not open" "couldn't open" \
  "cannot be opened" "could not be opened" "can't be opened" "couldn't be opened"
carries_each "the stop is one line saying the pull request could not be opened" \
  "could not be opened" "cannot be opened" "couldn't be opened" "can't be opened" \
  "could not open" "cannot open" "couldn't open" "can't open" -- \
  "one line" "One line" "single line" "a line saying" "a line that says"
carries "the stop names the pr Playbook" "Playbook: pr"
carries_any "on its first line" \
  "on its first line" "on the first line" "its first line" "opens with" "opens on" "opening line" \
  "line one" "the reply opens"
carries_any "with no \`Yours:\` line" \
  "no \`Yours:\`" "No \`Yours:\`" "without a \`Yours:\`" "without the \`Yours:\`" "never a \`Yours:\`" \
  "not a \`Yours:\`" "no Yours:" "without a Yours:"
carries_any "and follows nothing: no watch, no worktree, no push, no file written" \
  "follows nothing" "nothing is followed" "nothing followed" "follows none" "follows no step" \
  "no step after" "no later step" "no further step" "runs nothing else" "nothing else runs" "does nothing else"

# A pull request already merged or closed opens fine in gh, so nothing above stops it: the run would
# watch its checks or push fixes onto a head nobody will merge. The unopenable stop already carries
# `Playbook: pr`, `Yours:` and "follows nothing" in this passage, so those are read off the paragraph
# that names the closed or merged state, not the whole passage.
echo "# pr.md / ### 2. Read-back: a closed or merged pull request stops the run with one line on Playbook: pr, following nothing"
read_back="$(passage_of "$pr" "### 2. Read-back" "##" 2>/dev/null)"
flat="$(tr '\n' ' ' <<<"$read_back" | tr -s ' ')"
expect "the read-back asks \`gh pr view\` for the pull request's \`state\`" test -n \
  "$(grep -oE 'gh pr view [^`]*--json ([A-Za-z]+,)*state' <<<"$flat")"
flat="$(awk 'BEGIN { RS = "" } index($0, "MERGED") { gsub(/\n/, " "); print; exit }' <<<"$read_back" | tr -s ' ')"
carries_each "a \`CLOSED\` or \`MERGED\` state stops the run" \
  "CLOSED" -- "MERGED" -- "stops" "stop" "ends the run" "the run ends"
carries_each "the stop is one line saying the pull request is closed or merged" \
  "closed or merged" "merged or closed" "is closed" "is merged" "already closed" "already merged" \
  "was closed" "was merged" -- \
  "one line" "One line" "single line" "a line saying" "a line that says"
carries_any "the stop names the pr Playbook on its first line" \
  "\`Playbook: pr\` on its first line" "\`Playbook: pr\` on the first line" "opens with \`Playbook: pr\`" \
  "same stop" "the same way" "as when \`gh pr view\` fails" "as for a pull request"
carries_any "with no \`Yours:\` line" \
  "no \`Yours:\`" "No \`Yours:\`" "without a \`Yours:\`" "without the \`Yours:\`" "never a \`Yours:\`" \
  "not a \`Yours:\`" "no Yours:" "without a Yours:" "same stop" "the same way"
carries_any "and follows nothing: no watch, no worktree, no push, no file written" \
  "follows nothing" "nothing is followed" "nothing followed" "follows none" "follows no step" \
  "no step after" "no later step" "no further step" "runs nothing else" "nothing else runs" "does nothing else" \
  "same stop" "the same way"

# `gh auth status` passes on a CLI logged in to one host while `gh pr view` fails on a URL of another
# host it holds no login for: read as unopenable, the stop sends the developer to check the number
# and the URL instead of logging in. The step 1 paragraph already names `gh auth login`, so the
# handover is read off the unopenable stop's own paragraph, not the passage.
echo "# pr.md / ### 2. Read-back: a gh pr view failure caused by a CLI not logged in takes the gh auth login line, not the unopenable one"
read_back="$(passage_of "$pr" "### 2. Read-back" "##" 2>/dev/null)"
flat="$(awk 'BEGIN { RS = "" } index($0, "could not be opened") { gsub(/\n/, " "); print; exit }' <<<"$read_back" | tr -s ' ')"
expect "the read-back has a paragraph saying the pull request could not be opened" test -n "$flat"
carries_each "that paragraph hands a failure whose cause is the CLI not being logged in to the \`gh auth login\` line instead" \
  "not logged in" "logged out" "no login" "not authenticated" "unauthenticated" "authentication" -- \
  "gh auth login" "step 1" "### 1" "the CLI's stop" "the CLI stop" "the login stop" -- \
  "instead" "rather than" "in place of" "wins" "takes precedence" "never this line" "not this line" \
  "never the line" "not the line" "never as" "not as"

# reply.md asks every refusal at a door for a `Yours:` line, and the run writing the `pr` door's
# refusals follows it: unless the exception lists those two stops beside the `ticket` door's, the
# run adds a `Yours: direction:` line the stop never offers, and a grader fails it.
echo "# reply.md / ## A refusal or a blocked run: the pr door's two stops hand over no choice, each with the one input it names"
flat="$(paragraph_with "$reply" "Every blocked Reply, and every refusal at a door" | tr -s ' ')"
expect "reply.md has the paragraph asking every refusal at a door for its line" test -n "$flat"
carries "the \`ticket\` door's Build repository stops stay listed as exceptions" \
  "verdict=elsewhere" "verdict=unbuildable"
except_at="$(first_at "except" "Except" "other than" "save for" "apart from")"
pr_door_at="$(first_at "\`pr\` door" "pr door" "\`pr\` Playbook" "pr Playbook" "Playbook: pr")"
expect "the \`pr\` door is named among the exceptions" test "$except_at" -gt 0 -a "$pr_door_at" -gt "$except_at"
carries_each "its first stop is a pull request the GitHub CLI cannot open, or closed or merged" \
  "cannot open" "can't open" "could not be opened" "cannot be opened" "fails to open" "unopenable" -- \
  "closed or merged" "merged or closed"
carries_each "that stop's one input is another pull request or the same one reopened" \
  "another pull request" "another one" "a different pull request" "another PR" -- \
  "reopen"
carries_each "its second stop is a GitHub CLI missing or not logged in, whose one input is \`gh auth login\`" \
  "missing" "not installed" "absent" -- \
  "not logged in" "logged out" "no login" "not authenticated" -- \
  "gh auth login"

# The developer who typed `/do` on a pull request has walked away: a run that ends its turn on
# `pending`, or backgrounds the watch, stands still until they come back, and one left at the Bash
# tool's two-minute default has the watch killed before it prints any verdict.
echo "# pr.md / ### 3. Watch: the run watches in the foreground at a 600000 ms timeout, re-running on pending until green hands on to the Reply"
steps="$(blocks_of "$pr" "## Steps" 2>/dev/null)"
flat="$(grep -E '^3\. ' <<<"$steps")"
carries_any "step 3 of the checklist is the watch" "watch" "Watch"
flat="$(grep -E '^5\. ' <<<"$steps")"
carries_any "step 5 of the checklist is the reply, after the watch and the fix" "reply" "Reply"
flat="$(passage_of "$pr" "### 3. Watch" "##" 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
expect "pr.md has a step \`### 3. Watch\`" test -n "$flat"
carries "the step runs the watch script on the pull request" "bash <skill-dir>/scripts/pr-watch.sh"
carries_any "with the pull request as its argument" \
  "pr-watch.sh <pr>" "pr-watch.sh <n>" "pr-watch.sh <number>"
carries_each "the call sets the Bash tool's timeout to 600000 ms" \
  "600000" -- "timeout"
carries_each "in the foreground, never backgrounded" \
  "foreground" -- \
  "never in the background" "not in the background" "never backgrounds" "never background" \
  "not background" "without backgrounding" "no background" "never \`run_in_background\`" \
  "not \`run_in_background\`" "without \`run_in_background\`" "never run_in_background"
carries_each "on \`verdict=pending\` it runs the same line again at once" \
  "verdict=pending" -- \
  "again" "re-run" "reruns" "re-runs" "rerun" -- \
  "at once" "immediately" "straight away" "right away" "with no pause" "without a pause" "without pausing"
carries_any "without ending its turn" \
  "without ending its turn" "without ending the turn" "never ends its turn" "never ends the turn" \
  "does not end its turn" "does not end the turn" "doesn't end its turn" "doesn't end the turn" \
  "not ending its turn" "not ending the turn" "never end its turn" "never end the turn" \
  "not end its turn" "not end the turn" "keeps its turn" "keeps the turn"
carries_each "until it reads \`verdict=green\`" \
  "until" -- "verdict=green"
carries_each "which hands on to the Reply step" \
  "verdict=green" -- "### 5. Reply" "step 5" "Reply step" "the Reply" "to the Reply"

# The developer merges on this Reply: one that misses the green state, or hands the merge over as a
# `Yours:` choice, reads as a stop, and a run that runs `gh pr merge` lands it with nobody deciding.
echo "# pr.md / ### 5. Reply: a green watch ends on a Reply saying every check is green and mergeable, its Next step gh pr merge <n>, never run"
flat="$(passage_of "$pr" "### 5. Reply" "##" 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
carries_each "the For whom part says every check is green" \
  "For whom" -- \
  "every check" "all checks" "each check" "all its checks" "all of its checks" "<n> checks" -- \
  "green" "passed"
carries_each "and the pull request mergeable" \
  "For whom" -- "mergeable"
carries_any "the count of checks is the watch's \`checks=<n>\`" "checks=<n>" "checks=\`" "\`checks=" "checks="
carries_any "with no \`Yours:\` line" \
  "no \`Yours:\`" "No \`Yours:\`" "without a \`Yours:\`" "without the \`Yours:\`" "never a \`Yours:\`" \
  "not a \`Yours:\`" "no Yours:" "without a Yours:"
carries_each "the Next step line ends with \`gh pr merge <n>\`" \
  "Next step" -- "gh pr merge <n>" -- "ends" "last" "closes"
carries_any "which the run never runs" \
  "never runs" "does not run" "doesn't run" "never run" "not run" "never merges" "does not merge" \
  "doesn't merge" "never merge"

# Item 10 already says a landed run's push carries no `Yours:` line and is never named under
# `outward`, so those words are read off the sentence naming `gh pr merge` and the one after it.
echo "# reply.md / ## Sections item 10: a green pr run's Next step ends with gh pr merge <n>, never run, no Yours:, never under outward"
item="$(item_holding <(passage_of "$reply" "## Sections" "## ") '[0-9]+\.' "10. **Next step.**" | tr '\n' ' ' | tr -s ' ')"
expect "reply.md's Sections carry item 10, Next step" test -n "$item"
flat="$item"
carries "the item names \`gh pr merge <n>\`" "gh pr merge <n>"
flat="$(sed 's/\. /.\n/g' <<<"$item" | awk 'index($0, "gh pr merge") { print; getline; print; exit }' | tr '\n' ' ')"
carries_each "as the line a green \`pr\` run ends on" \
  "\`pr\`" "pr run" "pull request" -- "green" "mergeable"
carries_any "which the run never runs" \
  "never runs" "does not run" "doesn't run" "never run" "not run" "never merges" "does not merge" \
  "doesn't merge" "never merge"
carries_each "with no \`Yours:\` line, never under \`outward\`, as a landed run's push" \
  "no \`Yours:\`" "No \`Yours:\`" "without a \`Yours:\`" "never a \`Yours:\`" "not a \`Yours:\`" -- \
  "outward" -- \
  "push"

# A run that merges lands the pull request on its base with nobody having decided to. `### 5. Reply`
# already names `gh pr merge <n>`, so the words are read off the bullet of `## What this run never
# does` that names it, not the whole file.
echo "# pr.md / ## What this run never does: the run never runs gh pr merge, the merge is the developer's, named as the next step"
never="$(passage_of "$pr" "## What this run never does" "## " 2>/dev/null)"
expect "pr.md has a section \`## What this run never does\`" test -n "$never"
flat="$(item_holding <(printf '%s\n' "$never") '- ' "gh pr merge" | tr '\n' ' ' | tr -s ' ')"
expect "a bullet of that section names \`gh pr merge\`" test -n "$flat"
carries_any "the merge is the developer's call" \
  "developer's" "the developer merges" "the developer decides" "left to the developer" "up to the developer"
carries_any "named as the next step" "next step" "Next step"

# A run that judges the checks off `gh pr checks` or `gh pr view` itself can call green a pull
# request whose checks are still running, and one that improvises on a verdict word it does not know
# (later Tickets add words) or on a watch that failed reports a state nobody computed. The step
# already says "its first line is its verdict" and names `verdict=pending` and `verdict=green`, so
# each guarantee is read off the bullet or paragraph that carries it, never the whole step: the two
# stops carry the same words, and only their own piece tells one from the other.
echo "# pr.md / ### 3. Watch: the run routes on the script's verdict line alone; another verdict word, or a non-zero exit, stops it on one line quoting it, nothing followed"
watch="$(passage_of "$pr" "### 3. Watch" "##" 2>/dev/null)"
piece_with() { # $1.. fixed strings: the first bullet or blank-line paragraph of $watch carrying any of them, flattened, on stdout
  # Optional: piece_in set on the call's own line reads another step's passage in place of $watch.
  piece_keys="$(printf '%s\n' "$@")" awk '
    function flush(i) {
      for (i = 1; i <= n; i++) if (!done && keys[i] != "" && index(piece, keys[i])) { print piece; done = 1 }
      piece = ""
    }
    BEGIN { n = split(ENVIRON["piece_keys"], keys, "\n") }
    /^ *$/ || /^- / { flush() }
    !/^ *$/ { piece = piece " " $0 }
    END { flush() }
  ' <<<"${piece_in:-$watch}" | tr -s ' '
}
flat="$(piece_with "gh pr checks")"
expect "a bullet or paragraph of the step names \`gh pr checks\`" test -n "$flat"
carries "and \`gh pr view\` beside it" "gh pr view"
carries_any "as what the run never judges the checks off itself" \
  "never the run's own reading" "not the run's own reading" "never its own reading" "not its own reading" \
  "never off its own reading" "never calls" "does not call" "doesn't call" "never runs" "does not run" \
  "doesn't run" "never reads" "does not read" "doesn't read" "never judges" "does not judge"
carries_each "the verdict being the script's first line" \
  "verdict" -- "first line" "verdict line" "line the script prints" "script's line"
flat="$(piece_with "any other verdict" "Any other verdict" "other verdict" "unknown verdict" \
  "verdict it does not know" "verdict word it does not know" "another verdict" "any other \`verdict=" \
  "Any other \`verdict=" "any other word" "Any other word")"
expect "a bullet or paragraph of the step takes a verdict word other than pending and green" test -n "$flat"
carries_any "it stops the run" "stops" "stop" "ends the run" "the run ends"
carries_each "on one line quoting that verdict" \
  "one line" "One line" "single line" "a line quoting" "a line that quotes" -- \
  "quoting" "quotes" "quoted" "verbatim" "as printed"
carries_any "and follows nothing" \
  "follows nothing" "nothing is followed" "nothing followed" "follows none" "follows no step" \
  "no step after" "no later step" "no further step" "runs nothing else" "nothing else runs" "does nothing else"
flat="$(piece_with "non-zero" "Non-zero" "nonzero" "exits with an error" "exit status other than 0" \
  "exit code other than 0" "exits other than 0")"
expect "a bullet or paragraph of the step takes a non-zero exit of the script" test -n "$flat"
carries_any "it stops the run" "stops" "stop" "ends the run" "the run ends"
carries_each "on one line quoting the script's stderr line" \
  "one line" "One line" "single line" "a line quoting" "a line that quotes" -- \
  "stderr" "standard error" -- \
  "quoting" "quotes" "quoted" "verbatim" "as printed"
carries_any "with no \`Yours:\` line" \
  "no \`Yours:\`" "No \`Yours:\`" "without a \`Yours:\`" "without the \`Yours:\`" "never a \`Yours:\`" \
  "not a \`Yours:\`" "no Yours:" "without a Yours:"
carries_any "and follows nothing" \
  "follows nothing" "nothing is followed" "nothing followed" "follows none" "follows no step" \
  "no step after" "no later step" "no further step" "runs nothing else" "nothing else runs" "does nothing else"

# The developer reading a `--auto` Run report sees how many rounds the watch took and how many checks
# ran, while the Reply stays its five parts, which every grader and reply-message-parts.sh read: a
# round section in the message breaks them. `### 3. Watch` and `### 5. Reply` already name the
# verdicts and `checks=<n>`, and reply.md's `## Run` list is renumbered whenever an item lands, so
# each check reads the item or the piece that names the round, never the whole step or section.
echo "# reply.md / ## Run and pr.md / ### 3. Watch: the pr watch's round is a Run section line, each call's verdict in order with the check count, written under --auto only, never a part of the Reply"
run_list="$(passage_of "$reply" "## Run" "## " 2>/dev/null)"
flat=""
for key in "verdict=pending" "pr-watch.sh" "watch"; do
  flat="$(item_holding <(printf '%s\n' "$run_list") '[0-9]+\.' "$key" | tr '\n' ' ' | tr -s ' ')"
  [ -n "$flat" ] && break
done
expect "an item of reply.md's \`## Run\` list names the \`pr\` watch's round" test -n "$flat"
carries_any "as the \`pr\` Playbook's" "\`pr\`" "pr Playbook" "pr run"
carries_each "with the verdict of each pending call and the green one with its check count" \
  "verdict=pending" -- "verdict=green" -- "checks="
carries_each "one per call, in the order the watch printed them" \
  "each call" "every call" "per call" "each run of" "every run of" "each time" -- \
  "in order" "in their order" "in the order" "as printed" "as the watch printed"
flat="$(piece_with "Run report" "Run section")"
expect "a bullet or paragraph of the watch step names the Run report" test -n "$flat"
carries_each "records each call's verdict there" \
  "verdict" -- "each call" "every call" "per call" "each run" "every run"
carries_each "written under \`--auto\` only" \
  "\`--auto\`" "--auto" -- "only" "alone"
carries_any "never as a section of the Reply" \
  "never a section of the Reply" "not a section of the Reply" "never as a section of the Reply" \
  "never a part of the Reply" "not a part of the Reply" "never part of the Reply" "not part of the Reply" \
  "never in the Reply" "not in the Reply" "never part of the message" "not part of the message" \
  "never a part of the message" "never a section of the message" "no section of the Reply" \
  "no part of the Reply" "never the Reply's"

# The developer whose pull request waits on a required review has nothing to fix and nothing to
# choose: a run that stops on that verdict reads as broken, a `Yours:` line reads as a choice, and a
# run that merges takes the approval out of their hands. Step 4 already says "every check is green",
# "no `Yours:`" and "gh pr merge <n>" for a green watch, so each of those is read off the piece of the
# step that names `awaiting-approval`, and item 10's off the sentence that names the approval.
echo "# pr.md / ### 3. Watch and ### 5. Reply, reply.md item 10: a watch awaiting a required approval ends on a Reply saying only the approval is missing, no Yours:, gh pr merge <n> never run"
flat="$(piece_with "verdict=awaiting-approval")"
expect "a bullet or paragraph of the watch step names \`verdict=awaiting-approval\`" test -n "$flat"
carries_any "it hands on to step 5, the Reply, as a green watch does" \
  "### 5. Reply" "step 5" "Reply step" "to the Reply" "on to the Reply"
reply_step="$(passage_of "$pr" "### 5. Reply" "##" 2>/dev/null)"
flat="$(piece_in="$reply_step" piece_with "awaiting-approval")"
expect "a bullet or paragraph of the Reply step names \`awaiting-approval\`" test -n "$flat"
carries_each "it says every check is green" \
  "every check" "all checks" "each check" "all its checks" "all of its checks" "<n> checks" -- \
  "green" "passed"
carries_each "and that only a required approval is missing" \
  "only" -- \
  "required approval" "required review" "approval required" "review required" "required approving review" -- \
  "missing" "pending" "outstanding" "lacks" "lacking" "still needed" "not yet given" "yet to be given"
carries_any "with no \`Yours:\` line" \
  "no \`Yours:\`" "No \`Yours:\`" "without a \`Yours:\`" "without the \`Yours:\`" "never a \`Yours:\`" \
  "not a \`Yours:\`" "no Yours:" "without a Yours:"
carries_each "its Next step line names \`gh pr merge <n>\`" \
  "Next step" -- "gh pr merge <n>"
flat="${flat#*Next step}"
approval_at="$(first_at "approval" "approve" "review")"
merge_at="$(first_at "gh pr merge <n>")"
expect "naming the approval before \`gh pr merge <n>\`" test "$approval_at" -gt 0 -a "$merge_at" -gt "$approval_at"
carries_any "which the run never runs" \
  "never runs" "does not run" "doesn't run" "never run" "not run" "never merges" "does not merge" \
  "doesn't merge" "never merge" "merges nothing"
item="$(item_holding <(passage_of "$reply" "## Sections" "## ") '[0-9]+\.' "10. **Next step.**" | tr '\n' ' ' | tr -s ' ')"
flat="$(sed 's/\. /.\n/g' <<<"$item" | awk 'index($0, "approval")' | tr '\n' ' ')"
expect "a sentence of reply.md's item 10 names a \`pr\` run missing an approval" test -n "$flat"
carries_any "as a watch that read \`awaiting-approval\`" \
  "awaiting-approval" "approval missing" "approval is missing" "missing approval" "approval pending" \
  "approval is pending"
carries "that sentence names \`gh pr merge <n>\`" "gh pr merge <n>"
carries_any "under the same no-\`Yours:\` rule" \
  "no \`Yours:\`" "No \`Yours:\`" "without a \`Yours:\`" "never a \`Yours:\`" "not a \`Yours:\`" \
  "same rule" "same way"

# Only the owner of the head branch may rewrite it: a run that rebases a branch others write rewrites
# their history, and a stop with no class, or naming the wrong branch, leaves the developer unsure
# whose move it is. Step 2's read-back already names `<head>` and `<base>`, and the never-does section
# already holds the merge bullet, so each guarantee is read off the piece that names the conflict or
# the bullet that names the rebase.
echo "# pr.md / ### 3. Watch and ## What this run never does: a conflicting pull request stops on one Yours: direction: line naming the head branch its owner rebases, rebasing and pushing nothing"
flat="$(piece_with "verdict=conflict")"
expect "a bullet or paragraph of the watch step names \`verdict=conflict\`" test -n "$flat"
carries_any "it stops the run" "stops" "stop" "ends the run" "the run ends"
carries "on a \`Yours: direction:\` line naming \`<head>\` and \`<base>\`" "Yours: direction:" "<head>" "<base>"
carries_any "where the owner of \`<head>\` rebases it onto \`<base>\`" \
  "the owner of <head> rebases it onto <base>" "the owner of <head> rebases <head> onto <base>" \
  "owner of \`<head>\` rebases it onto \`<base>\`" "<head>'s owner rebases it onto <base>"
carries_each "\`<head>\` and \`<base>\` come off the verdict's \`head=\` and \`base=\` lines" \
  "head=" -- "base="
carries_any "not off the read-back" \
  "not the read-back" "never the read-back" "not off the read-back" "never off the read-back" \
  "not from the read-back" "never from the read-back" "not step 2" "never step 2" "not off step 2" \
  "never off step 2" "not from step 2" "never from step 2" "rather than the read-back" "instead of the read-back"
carries_each "the run never rebases and never pushes" \
  "never rebases" "does not rebase" "doesn't rebase" "rebases nothing" "no rebase" -- \
  "never pushes" "does not push" "doesn't push" "pushes nothing" "no push" "nor pushes" "or pushes"
never="$(passage_of "$pr" "## What this run never does" "## " 2>/dev/null)"
flat=""
for key in "Rebase" "rebase"; do
  flat="$(item_holding <(printf '%s\n' "$never") '- ' "$key" | tr '\n' ' ' | tr -s ' ')"
  [ -n "$flat" ] && break
done
expect "a bullet of \`## What this run never does\` names the rebase" test -n "$flat"
carries_any "of the head branch" "head branch" "<head>" "its head" "the head"
carries_any "on a conflict" "conflict"

# The developer who walked away needs a run on a dead runner to stop, or it holds its turn for good,
# and only the script can tell a stall from slow checks: a run that counts its own watches stops on
# checks that are still moving. The window lives in the script's `since=` and `state=`, so the run
# hands them back untouched, and the stop is read off the piece naming `verdict=stalled`, since the
# conflict bullet carries a `Yours: direction:` line too.
echo "# pr.md / ### 3. Watch: the run hands each pending verdict's since= and state= back to the next call, and stops on verdict=stalled with one Yours: direction: line naming the pending checks"
blocks="$(blocks_of "$pr" "### 3. Watch" 2>/dev/null)"
expect "the step's call line takes the window back, \`pr-watch.sh <pr> [<since> <state>]\`" \
  grep -qF -- "bash <skill-dir>/scripts/pr-watch.sh <pr> [<since> <state>]" <<<"$blocks"
flat="$(passage_of "$pr" "### 3. Watch" "##" 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
affirms "the first call passes \`<pr>\` alone" \
  "first call" "first time" "first run" -- \
  "<pr>\` alone" "<pr> alone" "only \`<pr>\`" "only <pr>" "alone"
flat="$(piece_with "verdict=pending")"
expect "a bullet or paragraph of the watch step names \`verdict=pending\`" test -n "$flat"
carries "it passes the verdict's \`since=\` and \`state=\` back as \`<since>\` and \`<state>\`" \
  "since=" "state=" "<since>" "<state>"
carries_any "on the next call" "next call" "following call" "next run" "call after"
carries_any "copied as they stand" \
  "as they stand" "as it stands" "as printed" "verbatim" "copied" "unchanged" "untouched"
carries_each "the run never reads, compares or computes them" \
  "unread" "never reads" "does not read" "doesn't read" "never read" -- \
  "never compared" "never compares" "does not compare" "doesn't compare" "not compared" "compares nothing" -- \
  "or computed" "or computes" "nor computes" "nor computed" "never computes" "never computed" \
  "does not compute" "doesn't compute" "not computed" "computes nothing"
flat="$(piece_with "verdict=stalled")"
expect "a bullet or paragraph of the watch step names \`verdict=stalled\`" test -n "$flat"
carries_any "it stops the run" "stops" "stop" "ends the run" "the run ends"
carries "on the line \`Yours: direction: <the pending checks>; re-run or unblock the runner, then /do the pull request again\`" \
  "Yours: direction: <the pending checks>; re-run or unblock the runner, then /do the pull request again"
carries "\`<the pending checks>\` are the verdict's \`pending=\` values" "pending="
carries_any "in the order printed" "in the order" "in order" "in their order" "as printed" "order printed"
carries_any "joined with \`, \`" \
  "joined with \`, \`" "joined by \`, \`" "separated by \`, \`" "joined with a comma" "joined by a comma" \
  "comma-separated" "separated by a comma" "comma and a space"

# A session that reads `de dev para prod` backwards follows a pull request from `prod` into `dev`,
# and a Plan: line built from the request's own wording repeats that misreading: only the pull
# request gh answers for names the branches the run actually follows, so the developer sees the
# reversal on the Reply's first lines.
echo "# pr.md / ## Steps, ### 1. Pull request and ### 2. Read-back: a branch pair is taken head first, as the branch the pull request comes from, and read back off gh's answer, never off the request's wording"
steps="$(blocks_of "$pr" "## Steps" 2>/dev/null)"
flat="$(grep -E '^1\. ' <<<"$steps")"
carries_any "step 1 of the checklist takes a branch pair beside the URL or the number" \
  "branch pair" "pair of branches" "two branches" "head and base" "head and its base"
pair_keys=("branch pair" "pair of branches" "two branches")
flat="$(piece_in="$(passage_of "$pr" "### 1. Pull request" "##" 2>/dev/null)" piece_with "${pair_keys[@]}")"
expect "a paragraph of ### 1. Pull request takes a branch pair from the request" test -n "$flat"
affirms "the head is the branch the pull request comes from" \
  "head" -- "comes from" "come from" "it is from" "opened from"
affirms "the base is the branch it goes into" \
  "base" -- "goes into" "go into" "merges into" "merged into" "lands in"
carries_any "in \`de dev para prod\` or \`from dev into prod\`" \
  "de dev para prod" "from dev into prod"
carries_any "\`dev\` is the head" \
  "\`dev\` is the head" "\`dev\` the head" "\`dev\` is its head" "head \`dev\`" "head is \`dev\`"
carries_any "\`prod\` the base" \
  "\`prod\` is the base" "\`prod\` the base" "\`prod\` its base" "base \`prod\`" "base is \`prod\`"
flat="$(piece_in="$(passage_of "$pr" "### 2. Read-back" "##" 2>/dev/null)" piece_with "${pair_keys[@]}")"
expect "a paragraph of ### 2. Read-back takes up a branch pair" test -n "$flat"
carries_each "its read-back is gh's answer for the pull request the run follows, its headRefName into its baseRefName" \
  "headRefName" -- "baseRefName" -- "into"
carries_any "never off the request's wording" \
  "never off the session's wording" "never the session's wording" "never from the session's wording" \
  "not off the session's wording" "not the session's wording" "not from the session's wording" \
  "never off the request's wording" "never the request's wording" "never from the request's wording" \
  "not off the request's wording" "not the request's wording" "not from the request's wording"

# A developer who repeats the request, or whose teammate opened the pull request first, ends with two
# pull requests for one pair and reviews split across them when the run opens one without looking.
# Step 1's pair paragraph and its logged-in stop already carry `number`, `follows nothing` and the
# Reply, so the lookup is read off the piece naming `gh pr list` and the follow off the piece saying
# the pull request was already open.
echo "# pr.md / ### 1. Pull request: a branch pair whose pull request is already open is followed by its number, nothing opened, the Reply saying it was already open"
pull_request="$(passage_of "$pr" "### 1. Pull request" "##" 2>/dev/null)"
flat="$(piece_in="$pull_request" piece_with "gh pr list")"
expect "a bullet or paragraph of ### 1. Pull request names \`gh pr list\`" test -n "$flat"
carries_any "for a branch pair" "branch pair" "the pair" "pair of branches"
carries "listed by the pair's head and base" "--head <head>" "--base <base>"
carries_any "in the open state" "--state open" "open pull request" "open state" "an open one"
carries_any "before the run opens anything" \
  "before it opens" "before opening" "before the run opens" "before anything is opened" \
  "before it creates" "before creating" "first looks" "first asks" "first lists"
flat="$(piece_in="$pull_request" piece_with "already open" "already opened" "already exists" \
  "already existed" "was open")"
expect "a bullet or paragraph of ### 1. Pull request takes a pull request already open for the pair" test -n "$flat"
affirms "the run takes its number" \
  "number" -- "takes" "holds" "keeps" "reads" "uses"
affirms "and follows it as a pull request named by its number" \
  "number" -- "follow"
carries_any "from the read-back on" "read-back" "step 2" "### 2"
carries_any "opening nothing" \
  "opens nothing" "opens none" "opens no " "never opens" "does not open" "doesn't open" \
  "nothing is opened" "no pull request is opened" "no new pull request" "no second pull request"
carries_any "never running \`gh pr create\`" \
  "never runs \`gh pr create\`" "never \`gh pr create\`" "no \`gh pr create\`" \
  "does not run \`gh pr create\`" "doesn't run \`gh pr create\`" "without \`gh pr create\`" \
  "never calls \`gh pr create\`" "not \`gh pr create\`" "never running \`gh pr create\`"
carries_each "the Reply says it was already open" \
  "Reply" -- "already open" "already opened" "already exists" "already existed" "was open"

# A run that takes any pull request from the head for the pair's follows one into another base, and
# one that takes a closed or merged one reports as already open a pull request nobody can merge: in
# both cases it opens nothing. The lookup piece already carries `--head`, `--base` and `--state open`,
# so the match is read off what it says counts as the pair's open pull request and what does not.
echo "# pr.md / ### 1. Pull request: a pull request from the head into another base, or a closed or merged one for the pair, is not the pair's open pull request"
flat="$(piece_in="$pull_request" piece_with "gh pr list")"
expect "a bullet or paragraph of ### 1. Pull request names \`gh pr list\`" test -n "$flat"
carries_each "the pair's open pull request is one whose head is the pair's head, whose base is the pair's base, and which is open" \
  "whose head" "its head is" "head is the pair's" "the pair's head" -- \
  "whose base" "its base is" "base is the pair's" "the pair's base" -- \
  "open"
carries_any "a pull request open from the head into another base" \
  "another base" "other base" "different base" "base other than"
carries_each "a closed or a merged one for the pair" "closed" -- "merged"
carries_any "is not the pair's open pull request" \
  "is not the pair's" "are not the pair's" "is not it" "are not it" "not the one" "neither is" \
  "does not count" "do not count" "doesn't count" "don't count" "never counts" "never count"
carries_any "either one counts as none open for the pair" \
  "none open" "no open pull request" "no pull request open" "nothing open" "counts as none" \
  "count as none" "as if none" "as though none"

# A developer who asks for the pull request and gets nothing opened, one into the wrong base, or a
# title and body to rewrite by hand, opens it themselves. The already-open paragraph names
# `gh pr create` only to say it never runs, so the create is read off the piece naming
# `gh pr create --head`, and the never-does allowance off the bullet naming `gh pr create`.
echo "# pr.md / ### 1. Pull request and ## What this run never does: with none open for the pair, the run opens exactly one pull request from head into base, titled and described from the commits between them, pushing nothing, the Reply saying it was opened"
flat="$(piece_in="$pull_request" piece_with "gh pr create --head")"
expect "a bullet or paragraph of ### 1. Pull request names \`gh pr create --head\`" test -n "$flat"
carries "the create names the pair's head and base and fills from the commits" \
  "gh pr create --head <head> --base <base>" "--fill"
carries_any "when none is open for the pair" \
  "none open" "none is open" "no pull request is open" "no open pull request" "no pull request open" \
  "nothing open" "none was open"
carries_any "the run opens exactly one pull request" \
  "exactly one" "a single pull request" "only one pull request" "one pull request and no more"
carries_each "its title and body filled from the commits between base and head" \
  "title" -- "body" -- "commits" "commit messages" -- "between" "ahead of" "not on <base>" "not on the base"
carries_any "pushing nothing" \
  "pushes nothing" "pushing nothing" "never pushes" "does not push" "doesn't push" "no push" \
  "without pushing" "nor pushes"
carries_each "the Reply says it was opened" \
  "Reply" -- "was opened" "it opened" "opened it" "the run opened" "has been opened" "opened by the run"
never="$(passage_of "$pr" "## What this run never does" "## " 2>/dev/null)"
flat="$(item_holding <(printf '%s\n' "$never") '- ' "gh pr create" | tr '\n' ' ' | tr -s ' ')"
expect "a bullet of \`## What this run never does\` names \`gh pr create\`" test -n "$flat"
carries_each "it allows the create only when no pull request is open for the pair" \
  "only" "unless" "except" "never" -- \
  "none open" "none is open" "no pull request is open" "no open pull request" "no pull request open" \
  "nothing open" "already open" "one is open"
carries_any "and the create pushes nothing" \
  "pushes nothing" "pushing nothing" "never pushes" "does not push" "doesn't push" "no push" \
  "without pushing" "nor pushes" "nor push" "or push"

# A developer who asked for the pull request to be opened and followed gets one opened and left with
# its checks unread when the run holds no number for it: the read-back and the watch take the number,
# and only `gh pr create`'s answer, the URL it prints, carries it. The create paragraph already names
# the read-back beside the `Plan:` line, so the follow is read off a phrase that carries the run on to
# it, and the step's `Done when` off the found or opened pull request it names.
echo "# pr.md / ### 1. Pull request: the pull request the run opened for the pair is followed by the number off \`gh pr create\`'s URL, from the read-back on, the watch on that number, as an open one is"
flat="$(piece_in="$pull_request" piece_with "gh pr create --head")"
expect "a bullet or paragraph of ### 1. Pull request names \`gh pr create --head\`" test -n "$flat"
affirms "the run takes the new pull request's number" \
  "number" -- "takes" "holds" "keeps" "reads" "uses"
carries_each "off the URL \`gh pr create\` prints" \
  "URL" -- "prints" "printed" "answer" "answers" "returns" "output"
affirms "and follows it by that number" \
  "number" -- "follow"
carries_any "from the read-back on" \
  "from the read-back on" "from step 2 on" "on to the read-back" "on to step 2" \
  "to the read-back and the watch" "the read-back and the watch" "through the read-back"
affirms "the watch runs on that number" \
  "watch" -- "number"
carries_any "as an open one is followed" \
  "as an open one" "as one already open" "as a pull request already open" "as the already-open" \
  "as one found open" "named by number" "named by its number"
flat="$(piece_in="$pull_request" piece_with "Done when")"
expect "### 1. Pull request has a \`Done when\` line" test -n "$flat"
carries_each "step 1 is done holding the number of a pull request the run found or opened for the pair" \
  "number" -- "found" "already open" "listed" "looked up" "open for the pair" -- \
  "opened" "created"

# A developer who typed half the pair, as in `abra um PR de dev`, gets a pull request opened into a
# base the run picked and has to close it, or a run that ends with no word on what was missing. The
# pair paragraph of step 1 already speaks of `<head>` and `<base>`, and the create paragraph of
# opening exactly one, so the stop is read off the piece naming a request with no base.
echo "# SKILL.md / ## Router and pr.md / ### 1. Pull request: a pull request naming a head and no base routes to pr and ends on one message asking for the base, never filled in, nothing looked up or opened"
flat="$(argument_of "$pr_row")"
carries_each "the pr row takes words asking for a pull request that name one branch only, as in \`abra um PR de dev\`" \
  "pull request" "PR" -- \
  "one branch only" "only one branch" "a single branch" "names one branch" "naming one branch" \
  "head and no base" "head alone" "only the head" "no base" "without a base" "missing its base" \
  "base is missing" "missing base"
missing_base_keys=("no base" "without a base" "missing base" "missing its base" "base is missing"
  "names no base" "lacks a base" "lacking a base" "one branch only" "only one branch" "a single branch"
  "head alone" "only the head")
flat="$(piece_in="$pull_request" piece_with "${missing_base_keys[@]}")"
expect "a bullet or paragraph of ### 1. Pull request takes a request naming a head and no base" test -n "$flat"
carries_any "it ends the run" "stops" "stop" "ends the run" "the run ends"
carries_any "in one message" \
  "one message" "a single message" "one line" "One line" "single line" "one Reply" "a single Reply"
affirms "asking for the base" \
  "asks" "asking" "ask" "which base" -- "base"
carries_any "the run never fills the base in itself" \
  "never fills" "does not fill" "doesn't fill" "never picks" "does not pick" "doesn't pick" \
  "never guesses" "does not guess" "doesn't guess" "never chooses" "does not choose" "never assumes" \
  "does not assume" "never supplies" "never takes a base" "never defaults"
carries_each "not with the default branch, nor \`main\`" \
  "default branch" -- "\`main\`"
carries_any "nor a branch read off the repository" \
  "repository" "checkout" "current branch"
carries_any "looking nothing up, no \`gh pr list\`" \
  "no \`gh pr list\`" "never runs \`gh pr list\`" "never \`gh pr list\`" "nor \`gh pr list\`" \
  "without \`gh pr list\`" "not \`gh pr list\`" "does not run \`gh pr list\`" "looks nothing up" \
  "looks up nothing" "nothing is looked up" "no lookup"
carries_any "and opening nothing, no \`gh pr create\`" \
  "no \`gh pr create\`" "never runs \`gh pr create\`" "never \`gh pr create\`" "nor \`gh pr create\`" \
  "without \`gh pr create\`" "not \`gh pr create\`" "does not run \`gh pr create\`" "opens nothing" \
  "nothing is opened" "never opens" "does not open" "opens no "

# A developer standing on an unrelated branch who types `abra um PR para prod` gets that branch
# opened as a pull request into `prod` and has to close it, when the run fills the missing head with
# the branch checked out. The missing-base paragraph already says `checkout` for the base, so the
# stop is read off the piece naming a request with no head, and the current branch off the phrasings
# naming the branch checked out, which that paragraph does not carry.
echo "# pr.md / ### 1. Pull request: a pull request naming a base and no head ends on one message asking for the head, never the branch checked out, nothing looked up or opened"
missing_head_keys=("no head" "without a head" "missing head" "missing its head" "head is missing"
  "lacks a head" "lacking a head" "base alone" "only the base")
flat="$(piece_in="$pull_request" piece_with "${missing_head_keys[@]}")"
expect "a bullet or paragraph of ### 1. Pull request takes a request naming a base and no head" test -n "$flat"
carries_any "it ends the run" "stops" "stop" "ends the run" "the run ends"
carries_any "in one message" \
  "one message" "a single message" "one line" "One line" "single line" "one Reply" "a single Reply"
affirms "asking for the head" \
  "asks" "asking" "ask" "which head" -- "head" "missing branch" "missing half"
carries_any "the run never takes a head itself" \
  "never fills the head" "never fills in the head" "does not fill the head" "doesn't fill the head" \
  "never picks the head" "never picks a head" "never guesses the head" "never guesses a head" \
  "never takes a head" "never assumes the head" "never assumes a head" "never infers the head" \
  "never defaults the head" "never takes the current branch" "never takes the checked-out branch" \
  "never takes the branch checked out" "never the current branch" "not the current branch" \
  "not with the current branch" "never with the current branch" "never the checked-out branch" \
  "not the checked-out branch" "not with the checked-out branch" "never the branch checked out" \
  "not the branch checked out" "not with the branch checked out" "is never the head" \
  "never becomes the head" "never used as the head" "never as the head" "not as the head"
carries_any "not the current branch, the one checked out" \
  "current branch" "checked out" "checked-out"
carries_any "looking nothing up, no lookup by the pair" \
  "no \`gh pr list\`" "never runs \`gh pr list\`" "never \`gh pr list\`" "nor \`gh pr list\`" \
  "without \`gh pr list\`" "not \`gh pr list\`" "does not run \`gh pr list\`" "looks nothing up" \
  "looks up nothing" "nothing is looked up" "no lookup"
carries_any "and opening nothing, no \`gh pr create\`" \
  "no \`gh pr create\`" "never runs \`gh pr create\`" "never \`gh pr create\`" "nor \`gh pr create\`" \
  "without \`gh pr create\`" "not \`gh pr create\`" "does not run \`gh pr create\`" "opens nothing" \
  "nothing is opened" "never opens" "does not open" "opens no "

# A developer who mistyped the head sees the CLI's raw error, or a pull request attempted from a
# branch that is not there, with no word on which name was wrong, when the run looks the pair up or
# opens one before it knows both branches are there. Step 1 already says `Playbook: pr`, "one line",
# `gh pr list` and `gh pr create` for other stops and the lookup, so the stop is read off the piece
# naming a branch that does not exist; a piece saying it of either branch of the pair answers for the head.
echo "# pr.md / ### 1. Pull request: a branch pair whose head does not exist, neither locally nor on the remote, stops on Playbook: pr and one line naming that branch, nothing looked up or opened"
missing_branch_keys=("does not exist" "doesn't exist" "no such branch" "not exist" "nonexistent"
  "non-existent")
flat="$(piece_in="$pull_request" piece_with "${missing_branch_keys[@]}")"
expect "a bullet or paragraph of ### 1. Pull request takes a branch of the pair that does not exist" test -n "$flat"
carries_any "the head counts" \
  "head" "branch of the pair" "branches of the pair" "pair's branches" "either branch" "each branch" \
  "both branches"
carries_each "a branch exists when it is a local branch or a branch on the remote" \
  "local" -- "remote" "origin"
carries_any "it ends the run" "stops" "stop" "ends the run" "the run ends"
carries "the Reply names the pr Playbook" "Playbook: pr"
carries_any "on its first line" "first line" "opens with" "opens on"
carries_each "then one line naming that branch" \
  "one line" "One line" "single line" -- \
  "naming" "names" "that names" "quoting" "quotes" -- \
  "<head>" "the branch" "that branch" "the missing branch" "branch name" "its name" "the name"
carries_any "the check runs ahead of the lookup by the pair, nothing looked up" \
  "before the lookup" "before it looks" "before looking" "before the run looks" "before any lookup" \
  "before \`gh pr list\`" "ahead of the lookup" "ahead of \`gh pr list\`" "no \`gh pr list\`" \
  "never runs \`gh pr list\`" "never \`gh pr list\`" "nor \`gh pr list\`" "without \`gh pr list\`" \
  "not \`gh pr list\`" "does not run \`gh pr list\`" "looks nothing up" "looks up nothing" \
  "nothing is looked up" "no lookup"
carries_any "and opening nothing, no \`gh pr create\`" \
  "no \`gh pr create\`" "never runs \`gh pr create\`" "never \`gh pr create\`" "nor \`gh pr create\`" \
  "without \`gh pr create\`" "not \`gh pr create\`" "does not run \`gh pr create\`" "opens nothing" \
  "nothing is opened" "never opens" "does not open" "opens no "

# A developer who named a base the remote does not carry gets a failed create, or a pull request into
# the wrong base, when the run checks only the head. The existence paragraph already says "both
# branches named" (of the request, not of the check), "local", "remote" and "the branch that does
# not exist" for the head, so the base is read off phrasings that put it among the branches checked
# and off a stop worded for any branch of the pair, never off "both branches" or "branch that does
# not exist" bare.
echo "# pr.md / ### 1. Pull request: a branch pair whose base does not exist, neither locally nor on the remote, stops on Playbook: pr and one line naming that branch, nothing looked up or opened"
flat="$(piece_in="$pull_request" piece_with "${missing_branch_keys[@]}")"
expect "a bullet or paragraph of ### 1. Pull request takes a branch of the pair that does not exist" test -n "$flat"
carries_any "the base is among the branches checked" \
  "<base>" "head and the base" "head and base" "head or base" "head or the base" "head or a base" \
  "base and the head" "base and head" "base or head" "base or the head" "base exists" \
  "the base exist" "either branch" "Either branch" "each branch" "Each branch" "both branches exist" \
  "both branches of the pair exist" "each of the two" "either of the two"
carries_each "it exists when it is a local branch or a branch on the remote" \
  "local" -- "remote" "origin"
carries_any "a base that does not exist stops the run" \
  "A base that does not exist" "a base that does not exist" "A base that doesn't exist" \
  "the base does not exist" "base that does not exist" "A branch that does not exist" \
  "a branch that does not exist" "A head or base that does not exist" \
  "A head or a base that does not exist" "head or base that does not exist" \
  "head or the base that does not exist" "Either branch that does not exist" \
  "either branch does not exist" "either one does not exist" "Either one that does not exist" \
  "a branch of the pair that does not exist" "A branch of the pair that does not exist"
carries_any "it ends the run" "stops" "stop" "ends the run" "the run ends"
carries "the Reply names the pr Playbook" "Playbook: pr"
carries_any "on its first line" "first line" "opens with" "opens on"
carries_each "then one line naming that branch" \
  "one line" "One line" "single line" -- \
  "naming" "names" "that names" "quoting" "quotes" -- \
  "<base>" "the branch" "that branch" "the missing branch" "branch name" "its name" "the name"
carries_any "the check runs ahead of the lookup by the pair, nothing looked up" \
  "before the lookup" "before it looks" "before looking" "before the run looks" "before any lookup" \
  "before \`gh pr list\`" "ahead of the lookup" "ahead of \`gh pr list\`" "no \`gh pr list\`" \
  "never runs \`gh pr list\`" "never \`gh pr list\`" "nor \`gh pr list\`" "without \`gh pr list\`" \
  "not \`gh pr list\`" "does not run \`gh pr list\`" "looks nothing up" "looks up nothing" \
  "nothing is looked up" "no lookup"
carries_any "and opening nothing, no \`gh pr create\`" \
  "no \`gh pr create\`" "never runs \`gh pr create\`" "never \`gh pr create\`" "nor \`gh pr create\`" \
  "without \`gh pr create\`" "not \`gh pr create\`" "does not run \`gh pr create\`" "opens nothing" \
  "nothing is opened" "never opens" "does not open" "opens no "

# A developer whose head was already merged into the base gets the GitHub CLI's error read as a
# failure, or an empty pull request opened for the pair, when the run opens one without reading the
# commits between them. The create paragraph already says "commits between base and head" and the
# existence paragraph "stops the run" and "one line", so the stop is read off the piece naming an
# empty range or nothing to open, phrasings neither of those carries.
echo "# pr.md / ### 1. Pull request: a branch pair whose head carries no commit its base lacks stops on one line saying there is nothing to open, after the existence check, nothing looked up or opened"
empty_range_keys=("nothing to open" "Nothing to open" "no commits" "no commit" "empty range"
  "range is empty" "..<head>" "rev-list" "already merged")
flat="$(piece_in="$pull_request" piece_with "${empty_range_keys[@]}")"
expect "a bullet or paragraph of ### 1. Pull request takes a pair whose head has no commit the base lacks" test -n "$flat"
carries_any "the range read is the commits the head carries that the base lacks" \
  "<base>..<head>" "base..head" "rev-list" "the base lacks" "base does not have" "base doesn't have" \
  "not in the base" "not yet in the base" "not already in the base" "missing from the base"
carries_each "an empty range ends the run" \
  "no commits" "no commit" "empty" "nothing to open" -- \
  "stops" "stop" "ends the run" "the run ends"
carries_each "on one line saying there is nothing to open" \
  "one line" "One line" "single line" "one message" "a single message" -- \
  "nothing to open" "Nothing to open"
carries_any "the range is read once both branches exist, after the existence check" \
  "once both exist" "once both branches exist" "once the head and the base exist" \
  "once the head and base exist" "once both are found" "once both were found" "after the existence" \
  "after that check" "after the check that" "after checking" "after it checks" "after both exist" \
  "With both branches existing" "with both branches existing" "both exist, the run" \
  "When both exist" "when both exist"
carries_any "ahead of the lookup by the pair, nothing looked up" \
  "before the lookup" "before it looks" "before looking" "before the run looks" "before any lookup" \
  "before \`gh pr list\`" "ahead of the lookup" "ahead of \`gh pr list\`" "no \`gh pr list\`" \
  "never runs \`gh pr list\`" "never \`gh pr list\`" "nor \`gh pr list\`" "without \`gh pr list\`" \
  "not \`gh pr list\`" "does not run \`gh pr list\`" "looks nothing up" "looks up nothing" \
  "nothing is looked up" "no lookup"
carries_any "and opening nothing, no \`gh pr create\`" \
  "no \`gh pr create\`" "never runs \`gh pr create\`" "never \`gh pr create\`" "nor \`gh pr create\`" \
  "without \`gh pr create\`" "not \`gh pr create\`" "does not run \`gh pr create\`" "opens nothing" \
  "nothing is opened" "never opens" "does not open" "opens no "

# A developer whose head was never published finds it pushed to the shared remote without having
# authorised it, or a pull request opened against a head nobody else can see, when the run takes a
# local head as good enough. The existence paragraph already says `git ls-remote`, "local" and "a
# branch on the remote", and the create paragraph "pushes nothing" and "already on the remote", so
# the stop is read off the piece naming a head the remote does not have, phrasings neither carries.
echo "# pr.md / ### 1. Pull request: a branch pair whose head exists locally with no branch on the remote stops the run, after the nothing-to-open check, nothing pushed, looked up or opened"
unpublished_head_keys=("not on the remote" "no branch on the remote" "missing from the remote"
  "absent from the remote" "never published" "unpublished" "not published" "not yet published"
  "remote does not have" "remote doesn't have" "remote does not hold" "remote doesn't hold"
  "remote lacks" "remote has no" "not pushed" "never pushed" "not yet pushed" "only locally"
  "only as a local" "local only" "local-only")
flat="$(piece_in="$pull_request" piece_with "${unpublished_head_keys[@]}")"
expect "a bullet or paragraph of ### 1. Pull request takes a head the remote does not have" test -n "$flat"
carries_each "a head that exists locally but is not on the remote" \
  "head" -- \
  "locally" "local branch" "local" -- \
  "${unpublished_head_keys[@]}"
carries_any "read off the remote itself" \
  "ls-remote" "asks the remote" "asking the remote" "queries the remote" "querying the remote" \
  "the remote itself" "the remote's own answer" "the remote answers" "what the remote holds"
carries_any "it ends the run" "stops" "stop" "ends the run" "the run ends"
carries_any "nothing pushed, no \`git push\`" \
  "nothing pushed" "pushes nothing" "nothing is pushed" "no \`git push\`" "never runs \`git push\`" \
  "never \`git push\`" "nor \`git push\`" "without \`git push\`" "not \`git push\`" \
  "does not run \`git push\`" "never pushes" "does not push" "doesn't push" "no push"
carries_any "the remote is asked after the nothing-to-open check" \
  "after the nothing-to-open check" "after the nothing to open check" "after the range check" \
  "after the empty-range check" "after the commit check" "after the commits check" \
  "after the rev-list" "after \`git rev-list" "after reading the commits" "after it reads the commits" \
  "after the run reads the commits" "once the range" "once the head carries" "once the head has commits" \
  "With commits to open" "with commits to open" "When there is something to open" \
  "when there is something to open" "once there is something to open" "With something to open" \
  "with something to open"
carries_any "ahead of the lookup by the pair, nothing looked up" \
  "before the lookup" "before it looks" "before looking" "before the run looks" "before any lookup" \
  "before \`gh pr list\`" "ahead of the lookup" "ahead of \`gh pr list\`" "no \`gh pr list\`" \
  "never runs \`gh pr list\`" "never \`gh pr list\`" "nor \`gh pr list\`" "without \`gh pr list\`" \
  "not \`gh pr list\`" "does not run \`gh pr list\`" "looks nothing up" "looks up nothing" \
  "nothing is looked up" "no lookup"
carries_any "and opening nothing, no \`gh pr create\`" \
  "no \`gh pr create\`" "never runs \`gh pr create\`" "never \`gh pr create\`" "nor \`gh pr create\`" \
  "without \`gh pr create\`" "not \`gh pr create\`" "does not run \`gh pr create\`" "opens nothing" \
  "nothing is opened" "never opens" "does not open" "opens no "

# A branch-pair run that stops on a branch that does not exist, or on a pair with nothing to open,
# hands over no choice: unless reply.md's exception lists both beside the `pr` door's other stops,
# the run writes a `Yours:` line under them and the developer reads a blocked run waiting on them.
echo "# reply.md / ## A refusal or a blocked run: a branch-pair run's stops on a missing branch and on nothing to open hand over no choice, each with the one input it names"
flat="$(paragraph_with "$reply" "Every blocked Reply, and every refusal at a door" | tr -s ' ')"
expect "reply.md has the paragraph asking every refusal at a door for its line" test -n "$flat"
except_at="$(first_at "except" "Except" "other than" "save for" "apart from")"
expect "the paragraph lists exceptions" test "$except_at" -gt 0
flat="${flat:$((except_at > 0 ? except_at - 1 : 0))}"
pr_door_at="$(first_at "\`pr\` door" "pr door" "\`pr\` Playbook" "pr Playbook" "Playbook: pr")"
missing_branch_at="$(first_at "does not exist" "doesn't exist" "no such branch" "nonexistent" "non-existent")"
nothing_to_open_at="$(first_at "nothing to open" "no commits" "no commit" "empty range" "nothing the base lacks" "carries nothing")"
expect "a branch that does not exist is listed among the \`pr\` door's exceptions" \
  test "$pr_door_at" -gt 0 -a "$missing_branch_at" -gt "$pr_door_at"
expect "a pair with nothing to open is listed among the \`pr\` door's exceptions" \
  test "$pr_door_at" -gt 0 -a "$nothing_to_open_at" -gt "$pr_door_at"
carries_each "a branch that does not exist names the branch to correct" \
  "branch" -- \
  "correct" "right branch" "existing branch" "a branch that exists" "rename" "typo"
carries_each "nothing to open names the commits the head still needs, or another pair" \
  "commits the head" "commit on the head" "commits on the head" "commit to the head" "head still needs" \
  "head needs" "commits to push" "push" -- \
  "another pair" "a different pair" "another branch pair" "other pair" "another base" "a different base"

# A developer whose head was never published has to push it before the run can go on: a stop with
# no command to type leaves them guessing, a `Yours:` line under another class files the push as a
# different kind of choice, and a stop listed among reply.md's exceptions reads as a branch that does
# not exist. The pr.md piece is the one the unpublished-head case above reads; the reply.md slice is
# the exception list the case above reads, past its first "except".
echo "# pr.md / ### 1. Pull request and reply.md / ## A refusal or a blocked run: the stop on a head the remote does not have carries exactly one Yours: outward: line, the push to type, and is no exception"
flat="$(piece_in="$pull_request" piece_with "${unpublished_head_keys[@]}")"
expect "a bullet or paragraph of ### 1. Pull request takes a head the remote does not have" test -n "$flat"
carries "the Reply hands over the push of that head, then the request again" \
  "Yours: outward: push <head> to the remote (git push -u origin <head>), then /do the request again"
carries_any "as one \`Yours:\` line" \
  "one \`Yours:\` line" "exactly one \`Yours:\`" "a single \`Yours:\`" "one Yours: line" \
  "exactly one Yours:" "a single Yours:" "only \`Yours:\` line" "only Yours: line"
yours_lines="$(grep -oE 'Yours: [a-z-]+:' <<<"$flat" | wc -l)"
expect "and no other \`Yours: <class>:\` line beside it" test "$yours_lines" -eq 1
flat="$(paragraph_with "$reply" "Every blocked Reply, and every refusal at a door" | tr -s ' ')"
expect "reply.md has the paragraph asking every refusal at a door for its line" test -n "$flat"
except_at="$(first_at "except" "Except" "other than" "save for" "apart from")"
flat="${flat:$((except_at > 0 ? except_at - 1 : 0))}"
unlisted_at="$(first_at "no branch on the remote" "unpublished" "never published" "not published" \
  "not on the remote" "remote does not have" "remote doesn't have" "missing from the remote")"
expect "the stop on an unpublished head is not among the stops with no \`Yours:\` line" \
  test "$except_at" -gt 0 -a "$unlisted_at" -eq 0

# A developer whose head is published, on a local branch that tracks no upstream or whose
# remote-tracking ref is stale or was never fetched, is told to push a branch the remote already has
# and gets nothing opened when the run reads "published" off local state. The paragraph already says
# `git ls-remote`, so the guarantees read here are the local state it never answers from, and the
# head the remote holds going on to be opened; read off the same piece as the two cases above.
echo "# pr.md / ### 1. Pull request: a head the remote holds under the same name is opened as before, whatever the local branch tracks, never judged off its upstream or a remote-tracking ref"
flat="$(piece_in="$pull_request" piece_with "${unpublished_head_keys[@]}")"
expect "a bullet or paragraph of ### 1. Pull request takes a head the remote does not have" test -n "$flat"
carries_each "the answer is never read off the local branch's upstream setting" \
  "upstream" "@{u}" "branch.<head>.merge" "branch.<head>.remote" "tracking setting" \
  "tracking configuration" "tracking config" "the branch it tracks" -- \
  "never off" "not off" "never read off" "not read off" "never from" "not from" "never the local" \
  "not the local" "never its" "not its" "rather than" "instead of" "regardless of" "ignores" \
  "nor off" "nor from" "nor the local" "nor its" "never by" "not by" "nor by" "never on its" \
  "not on its" "nor on its"
carries_each "nor off a remote-tracking ref, which can be stale or missing" \
  "refs/remotes/origin/<head>" "remote-tracking" "remote tracking" "origin/<head>" -- \
  "stale" "out of date" "outdated" "lag" "behind the remote" "not fetched" "never fetched" \
  "last fetch" "may not exist" "might not exist" "can be missing" "may be missing" "be missing"
carries_any "a head on the remote under the same name" \
  "same name" "its own name" "the name it has locally" "the same branch name" "named the same" \
  "under that name" "by that name" "by the same name"
affirms "a head the remote holds goes on to the lookup" \
  "remote holds" "remote has" "remote does hold" "on the remote" "remote answers" "the remote's" \
  "published" -- \
  "goes on" "go on" "proceeds" "continues" "carries on" "moves on" "on to the lookup" "to the lookup"
affirms "and is opened as before" \
  "remote holds" "remote has" "remote does hold" "on the remote" "remote answers" "the remote's" \
  "published" "it" -- \
  "opened as before" "opens it as before" "opened as usual" "as before" "as it would" "like any other"
carries_each "whether or not the local branch tracks it" \
  "tracks" "tracking" "upstream" -- \
  "whether or not" "or not" "with or without" "even when" "even if" "regardless" "no upstream" \
  "untracked" "whatever"

# A red check's log is text a stranger can write into, and the fixer reads it holding Bash and Write
# (ADR 0087): a log line that reads as an order (open this file, skip that test) steers the fork
# unless the brief fences it off as quoted data. Everything is read off the step itself, so a clause
# elsewhere in pr.md does not bind the brief this step hands over.
echo "# pr.md / ### 4. Fix the red checks: each fixer's brief carries its check's excerpt between two excerpt tags sharing one random id, quoted data from the log and never an instruction, with Failed steps: and Files: as keys of their own"
step="$(passage_of "$pr" "### 4. Fix the red checks" "##" 2>/dev/null)"
expect "pr.md has a step \`### 4. Fix the red checks\`" test -n "$step"
out="$(sed 's/^[[:space:]]*//' <<<"$step")"
check_lines "the step's brief puts the excerpt under Excerpt:, between an opening and a closing tag line sharing one id" 0 0 \
  "Excerpt:" '<excerpt id="<id>">' '</excerpt id="<id>">'
open_at="$(grep -nxF '<excerpt id="<id>">' <<<"$out" | head -1 | cut -d: -f1)"
close_at="$(grep -nxF '</excerpt id="<id>">' <<<"$out" | head -1 | cut -d: -f1)"
expect "the opening tag line comes before the closing one" test "${close_at:-0}" -gt "${open_at:-0}"
check_lines "the check's failed steps and its files are brief keys of their own" 0 0 \
  "Failed steps:" "Files:"
# shellcheck disable=SC2034  # lib.sh's carries reads $flat
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ')"
carries_each "the two tags share one short random id the session generates for that dispatch" \
  "random id" "random ID" -- \
  "same" "share" "sharing" "one short random" "one random" -- \
  "that dispatch" "each dispatch" "every dispatch" "per dispatch" "the dispatch" "each fork" \
  "every fork" "per fork" "each fixer" "every fixer"
carries_each "everything between the two tags is quoted data from the check's log" \
  "between the two tags" "between the tags" "between the two \`excerpt\` tags" \
  "between the \`excerpt\` tags" "inside the tags" "within the tags" -- \
  "quoted data" -- \
  "check's log" "the log" "its log" "job's log"
carries_each "material to reproduce, never an instruction to the fixer" \
  "reproduce" -- \
  "never an instruction" "not an instruction" "never instructions" "never as an instruction" \
  "never an order" "not an order"
carries "the excerpt is cut by pr-log.sh on the check's link and its run tree" \
  "bash <skill-dir>/scripts/pr-log.sh <link> <run tree>"

# A round can carry several unrelated failures, and a session that fixes them itself holds every log
# and every diagnosis in one window (ADR 0088): a red verdict hands each check to a fork of its own,
# in a worktree and on a branch cut for it, and a session without the Agent tool stops rather than
# fall back to fixing in place. The route is read off the watch bullet naming `verdict=red`, so the
# catch-all stop for an unknown verdict never answers for it.
echo "# pr.md / ### 3. Watch and ### 4. Fix the red checks: a red verdict forks one do-pr-fixer per red check, each in the worktree and on the branch fix-worktrees.sh add cut for it, and the session writes no fix"
flat="$(piece_with "verdict=red")"
expect "a bullet or paragraph of the watch step names \`verdict=red\`" test -n "$flat"
carries_any "it routes to step 4" "step 4" "### 4" "Fix the red checks"
carries_any "when the run has pushed no round yet" \
  "pushed no round" "no round yet" "no round pushed" "has not pushed" "hasn't pushed" "before any round" \
  "before its first push" "before any push" "first round"
carries "carrying the verdict's \`head=\`, \`sha=\` and \`red=\` lines" "head=" "sha=" "red="
step="$(passage_of "$pr" "### 4. Fix the red checks" "##" 2>/dev/null)"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ')"
carries_any "the session writes no fix" \
  "writes no fix" "never writes a fix" "writes no fixes" "never writes the fix" "no fix is written in the session"
carries "per ADR 0088" "ADR 0088"
carries_any "each red check gets one \`do-pr-fixer\` fork" \
  "one \`do-pr-fixer\`" "one do-pr-fixer" "a \`do-pr-fixer\` of its own" "a do-pr-fixer of its own"
carries_any "in check order" "check order" "in the order printed" "order of the \`red=\` lines"
carries_any "the fork goes through the Agent tool as \`do-pr-fixer\`" \
  "subagent_type: do-pr-fixer" "subagent_type: \`do-pr-fixer\`" "\`subagent_type\`: \`do-pr-fixer\`" \
  "\`subagent_type: do-pr-fixer\`"
carries "its brief's Tree: and Branch: are the worktree line's path and branch, its return file \`<dir>/check-<k>\`" \
  "Tree: <the path on the check's worktree line>" "Branch: <the branch on the check's worktree line>" \
  "Return file: <dir>/check-<k>"
carries "the run waits on the return files with returns.sh 240, its Bash timeout at 600000 ms" \
  "bash <skill-dir>/../do-code-review/scripts/returns.sh 240 " "600000"
before "the worktree is cut before the wait" "fix-worktrees.sh add" "returns.sh 240"
carries_each "called again while it reads \`missing=\`, three windows at most" \
  "missing=" -- \
  "three windows" "3 windows" "three calls" "3 calls" "three times" "three waits"
carries "a return file that never lands reads \`not fixed <k>: the fixer did not return\`" \
  "not fixed <k>: the fixer did not return"
carries "\`<dir>\` is a \`mktemp -d\` directory" "mktemp -d"
carries_each "\`<at>\` is the first 7 characters of \`<sha>\`, then \`-\`, then \`<dir>\`'s random suffix" \
  "<at>" -- \
  "first 7" "first seven" "7 characters" "seven characters" -- \
  "suffix"
flat="$(piece_in="$step" piece_with "withheld")"
expect "a bullet or paragraph of the fix step takes the Agent tool being withheld" test -n "$flat"
carries "it names the Agent tool" "Agent tool"
carries_any "the step stops" "stops" "does not start" "doesn't start" "never starts" "ends the run"
carries_each "with one line saying no fixer can be forked" \
  "one line" "One line" "single line" -- \
  "no fixer can be forked" "cannot fork" "can't fork" "no fixer can be" "no fork" "nothing can be forked"
carries_any "and the session never fixes a check itself" \
  "never fixes" "fixes no check" "does not fix" "doesn't fix" "never fix" "never writes" "writes no fix"

# Disjoint red checks are fixed at once and checks sharing a file one after the other: the Waves are
# group-waves.sh's output over each check's `file=` lines, never a grouping the session works out.
# What the run pipes to it is read off the stretch of step 4 before the first add call, since the
# grouping has to be done before any worktree is cut and item 5 already says "one line per check".
echo "# pr.md / ### 4. Fix the red checks: the red checks are grouped into Waves by group-waves.sh over their file= lines, every fixer of a Wave is forked at once, and a check sharing a file with an earlier one runs in a later Wave"
step="$(passage_of "$pr" "### 4. Fix the red checks" "##" 2>/dev/null)"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ')"
whole="$flat"
carries "the red checks are piped to group-waves.sh" "bash <skill-dir>/../do-code-review/scripts/group-waves.sh"
before "the grouping comes before any worktree is cut" "group-waves.sh" "fix-worktrees.sh add"
flat="${whole%%fix-worktrees.sh add*}"
carries_each "one record per red check, in check order" \
  "one record per" "a record per" "one line per red check" "one line per check" "a line per check" \
  "one per red check" "one per check" -- \
  "check order" "in the order printed" "order of the \`red=\` lines"
carries_each "each record is \`<k>\`, a tab, then the check's \`file=\` values joined by spaces" \
  "<k>" -- \
  "a tab" "TAB" "\\t" "tab-separated" "tab character" -- \
  "file=" -- \
  "joined by spaces" "joined by a space" "separated by spaces" "space-separated" "spaces between" \
  "one space" "a space"
carries_any "the check's files come from its \`pr-log.sh\` output" "pr-log.sh" "excerpt line" "item 3"
flat="$whole"
carries "each printed \`wave=<w> numbers=<k>[,<k>]...\` line is one Wave" "wave=<w> numbers=<k>[,<k>]..."
carries_each "its numbers are check numbers" \
  "numbers=" -- "check number" "check numbers" "the checks'" "numbers name checks" "number a check"
carries_each "checks whose files are disjoint share a Wave and run at once" \
  "disjoint" -- "at once" "in parallel" "together" "at the same time" "concurrently"
carries_each "a check sharing a file with an earlier check comes out in a later Wave and runs after it" \
  "shares a file" "share a file" "sharing a file" "a file in common" "same file" "file with an earlier" -- \
  "later Wave" "next Wave" "Wave after" "subsequent Wave" "later one"
carries_each "the Waves are taken in the order printed" \
  "each Wave" "every Wave" "per Wave" "Wave by Wave" -- \
  "order printed" "printed order" "in order" "Wave order" "one after another" "one after the other"
carries "one fix-worktrees.sh add call per Wave cuts every worktree of it, one worktree line per check" \
  "bash <skill-dir>/../do-code-review/scripts/fix-worktrees.sh add <run tree> pr-<n> <at> <w> <k>..." \
  "worktree <k> <path> <branch>"
carries_each "every \`do-pr-fixer\` of the Wave is forked in one message" \
  "one message" "a single message" "the same message" "one response" "a single response" -- \
  "every \`do-pr-fixer\`" "every do-pr-fixer" "every fixer" "all the fixers" "all of the Wave's fixers" \
  "each fixer of the Wave" "the Wave's fixers" "every fork" "all its fixers" "all of its fixers"
carries "one returns.sh 240 call waits on the Wave" "bash <skill-dir>/../do-code-review/scripts/returns.sh 240 "
carries_each "that one call waits on every return file of the Wave" \
  "one call" "a single call" "one \`returns.sh\`" "one returns.sh" "a single \`returns.sh\`" "one wait" -- \
  "every return file of the Wave" "each return file of the Wave" "the Wave's return files" \
  "all the Wave's return files" "every return file in the Wave" "return files of the Wave" \
  "every return file of that Wave" "return files of that Wave"

# A check that fails on a timeout or a crashed runner names no file in its log, so its fix may touch
# any file and would collide with a fixer beside it. Item 4 already says "a tab" and "Wave" for every
# check, so both guarantees are read off the paragraph about the check with no `file=` line alone.
echo "# pr.md / ### 4. Fix the red checks: a red check whose pr-log.sh output prints no file= line still goes to group-waves.sh as <k>, a tab and an empty field, and is forked in a Wave of its own"
step="$(passage_of "$pr" "### 4. Fix the red checks" "##" 2>/dev/null)"
flat="$(piece_in="$step" piece_with "no \`file=\`" "no file=" "without a \`file=\`" "without \`file=\`" \
  "names no file" "no file")"
expect "a paragraph of the step is about the check with no \`file=\` line" test -n "$flat"
carries_each "its record still goes in, written as \`<k>\`, a tab and an empty field after it" \
  "<k>" -- \
  "a tab" "TAB" "\\t" "tab character" -- \
  "empty field" "empty files field" "empty \`file=\` field" "field empty" "nothing after the tab" \
  "nothing after it" "empty after the tab" "an empty one"
carries_any "group-waves.sh puts that check in a Wave of its own, sharing none with another check" \
  "Wave of its own" "its own Wave" "a Wave alone" "alone in a Wave" "alone in its Wave" \
  "shares no Wave" "share no Wave" "sharing no Wave" "no other check in its Wave" "the only check in its Wave"

# The developer audits the pushed round in check order, and fix-integrate.sh takes a branch only when
# it is one commit ahead of the run tree's HEAD: a Wave cut before the earlier picks fixes a head that
# is gone by the time it is integrated. Step 4 already says "check order" for the excerpts and the
# group-waves.sh records, so the pick's order is read off the paragraph carrying the call, and the
# next Wave's cut off the paragraph that names the next Wave.
echo "# pr.md / ### 4. Fix the red checks: a Wave's fixed commits come onto the run tree through one fix-integrate.sh call in check number order, and the next Wave's worktrees are cut only after those picks, from the run tree's HEAD as they left it"
step="$(passage_of "$pr" "### 4. Fix the red checks" "##" 2>/dev/null)"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ')"
carries "one fix-integrate.sh call takes every fixed branch of the Wave, printing a picked line" \
  "bash <skill-dir>/../do-code-review/scripts/fix-integrate.sh <run tree> <k>=<branch>..." "picked <k> <sha>"
flat="$(piece_in="$step" piece_with "fix-integrate.sh <run tree> <k>=<branch>...")"
expect "a paragraph of the step carries the Wave's fix-integrate.sh call" test -n "$flat"
carries_any "it is one call per Wave" \
  "one call per Wave" "once per Wave" "one call" "a single call" "one \`fix-integrate.sh\`" \
  "one fix-integrate.sh" "per Wave" "once for the Wave"
carries_each "over the checks that returned \`fixed <k>:\` and only those" \
  "\`fixed <k>:" "\`fixed <k>\`" -- \
  "only those" "only the checks" "only them" "and no other" "no other check" "any other return gets no pick" \
  "Any other return gets no pick" "none other"
carries_any "the picks go in ascending check number" \
  "ascending" "check number order" "order of their check numbers" "increasing check number" \
  "check order" "lowest check number first"
carries_each "one picked line per check" \
  "picked <k> <sha>" -- "per check" "for each check" "each check" "every check" "per branch" "for each branch"
flat="$(piece_in="$step" piece_with "next Wave" "Next Wave" "following Wave" "Wave after this" "Wave after it")"
expect "a paragraph of the step is about the next Wave's cut" test -n "$flat"
carries_each "its worktrees are cut only after this Wave's picks" \
  "cut" "fix-worktrees.sh add" -- \
  "only after" "not before" "never before" "only once" "after this Wave's picks" "after the picks" \
  "after those picks" -- "pick"
carries_each "from the run tree's HEAD as those picks left it" \
  "HEAD" -- \
  "left it" "leave it" "left by the picks" "moved by the picks" "the picks moved" "on top of the picks" \
  "carrying the picks" "now carries"
carries_each "since fix-integrate.sh refuses a branch not cut from the HEAD it starts on" \
  "fix-integrate.sh" -- "refus" "rejects" "won't take" "will not take" "takes a branch only" -- "HEAD"

# A developer shares the head with others: a conflicted fix resolved by the run is a guess merged
# into their branch, and a conflict that stops the run leaves that check with no fix at all. Step 4
# already says "next Wave", "HEAD" and "stops the run" for other reasons, so every guarantee is read
# off the paragraph naming the script's `conflicted <k> with` line, which also keeps the stop for
# any line other than `picked` and `conflicted`.
echo "# pr.md / ### 4. Fix the red checks: a fixer whose pick conflicts with an earlier pick of the round has its pick aborted, moves to the next Wave and is forked again in a new worktree over the run tree's HEAD as it now stands, and the run neither stops on the conflict nor resolves it"
step="$(passage_of "$pr" "### 4. Fix the red checks" "##" 2>/dev/null)"
flat="$(piece_in="$step" piece_with "conflicted <k> with")"
expect "a paragraph of the step names fix-integrate.sh's \`conflicted <k> with\` line" test -n "$flat"
carries_any "the script has already aborted that pick" \
  "aborted" "aborts" "abort" "already undone" "undid" "rolled back" "rolls back" "backed out"
carries_any "the run does not stop on it" \
  "does not stop" "doesn't stop" "never stops" "not stop" "without stopping" "is not a stop" \
  "no stop" "keeps going" "carries on" "goes on"
carries_each "and never resolves it, merging or classing no conflicted hunk" \
  "never resolve" "does not resolve" "doesn't resolve" "not resolved" "never resolved" \
  "no resolution" "resolves nothing" "resolves no" "unresolved" "not resolve" -- \
  "hunk" "merge" "merged" "class"
carries_each "the check moves to the next Wave" \
  "next Wave" "later Wave" "following Wave" "Wave after" "a new Wave" -- \
  "moves" "moved" "goes" "joins" "carried" "put in" "added to" "runs in" "re-queued" "requeued"
carries_each "its do-pr-fixer is forked again in a fresh worktree" \
  "do-pr-fixer" "fixer" -- \
  "forked again" "fork it again" "forks it again" "re-forked" "forked anew" "a new fork" \
  "forked a second time" "fork again" -- \
  "fresh worktree" "new worktree" "worktree of its own" "fix-worktrees.sh add"
carries_each "cut over the run tree's HEAD as the integration left it, holding the pick it lost to" \
  "HEAD" -- \
  "left it" "now stands" "as it stands" "now carries" "now holds" "holds the pick" "carries the pick" \
  "on top of" -- \
  "lost to" "earlier pick" "pick it conflicted with" "conflicting pick" "winning pick" "the pick it" \
  "this Wave's picks" "the Wave's picks"
carries_each "any line other than picked and conflicted still stops the run quoting it" \
  "any other line" "other line" "another line" "any line other" "anything else" -- \
  "stops the run" "stop the run" -- "quoting"

# Two checks moved out of one Wave that conflicted over the same file would conflict again if forked
# side by side, spending their moves on the very collision that moved them. Step 4 already says
# "later Wave", "next Wave" and "HEAD" for other reasons, so the guarantees are read off the
# paragraph about the moved checks alone, keyed on wording no other paragraph of the step carries.
echo "# pr.md / ### 4. Fix the red checks: checks moved out of one Wave whose conflicted lines name a common file are forked in separate Waves of their own, right after that Wave and before the next printed one, and never merged into a Wave group-waves.sh printed"
step="$(passage_of "$pr" "### 4. Fix the red checks" "##" 2>/dev/null)"
flat="$(piece_in="$step" piece_with "moved out of" "moved checks" "moved check" "checks moved" "check moved")"
expect "a paragraph of the step is about the checks moved out of a Wave" test -n "$flat"
carries_any "the moved checks run in Waves of their own" \
  "Waves of their own" "Wave of their own" "their own Waves" "their own Wave" "Waves of its own" \
  "new Waves" "new Wave" "extra Wave" "extra Waves" "added Wave" "added Waves"
carries_each "right after the Wave they were moved out of" \
  "right after" "straight after" "immediately after" "just after" "directly after" "right behind" -- \
  "moved out of" "they left" "they came from" "they were moved"
carries_each "and before the next Wave group-waves.sh printed" \
  "before the next" "ahead of the next" "before group-waves.sh's next" "before any later printed" -- \
  "printed" "group-waves.sh"
carries_each "after the last printed Wave when moved out of the last one" \
  "last" -- "after"
carries_each "two moved checks whose conflicted lines name a common file are never forked together" \
  "common file" "a file in common" "share a file" "shares a file" "sharing a file" "same file" \
  "name a file" "names a file" -- \
  "conflicted" -- \
  "never forked together" "not forked together" "never together" "never in the same Wave" \
  "never share a Wave" "never in one Wave" "not in the same Wave" "never side by side"
carries_any "each going in a separate Wave" \
  "separate Wave" "separate Waves" "different Wave" "different Waves" "a Wave each" "one per Wave" \
  "Waves apart" "a Wave apart" "each in its own Wave" "each in a Wave of its own"
carries_each "and such a Wave is never merged into a Wave group-waves.sh printed" \
  "never merged" "not merged" "never folded" "not folded" "never joins" "never added to" "never put in" \
  "never mixed" "never combined" "not combined" -- \
  "printed" "group-waves.sh"

# A check moved on every conflict never ends the round, and a Reply silent about it reads as every
# check fixed. Step 4 already says "a branch twice" and "stays red this round" for other reasons, so
# the cap is read off the paragraph keyed on wording only it carries, and the round line off the
# piece naming `not fixed: conflicted with`, wherever the step puts it.
echo "# pr.md / ### 4. Fix the red checks and ### 5. Reply: a check whose pick conflicts after it was moved twice gets no third fixer and no pick that round, and its round line reads not fixed, naming the checks it conflicted with"
step="$(passage_of "$pr" "### 4. Fix the red checks" "##" 2>/dev/null)"
flat="$(piece_in="$step" piece_with "moved twice" "twice already" "moved two times" "two moves" \
  "a third time" "third conflict" "third time")"
expect "a paragraph of the step caps the moves of a conflicted check" test -n "$flat"
carries_each "a check is moved twice at most" \
  "moved twice" "two moves" "moved two times" "twice already" -- \
  "at most" "no more than" "not moved again" "never moved again" "no third move" "not a third" \
  "never a third" "is not moved" "never moved a third" "not moved a third"
carries_each "its pick conflicting a third time" \
  "a third time" "third conflict" "third time" "conflicts again" -- "conflict"
carries_each "gets no third do-pr-fixer" \
  "do-pr-fixer" "fixer" -- \
  "no third" "not forked again" "never forked again" "not forked a third" "never forked a third" \
  "no new fork" "not re-forked" "never re-forked"
carries_each "and no pick that round" \
  "no pick" "not picked" "never picked" "no further pick" "no third pick" "nothing is picked" -- \
  "round"
carries_any "it stays red this round" \
  "stays red" "remains red" "left red" "still red" "stay red" "remain red"
flat="$(piece_in="$step" piece_with "not fixed: conflicted with")"
expect "a piece of the step gives such a check's round line" test -n "$flat"
carries "its round line reads not fixed: conflicted with check <m>" \
  "not fixed: conflicted with" "check <m>"
carries_each "naming every check of the conflicted line's with list" \
  "every check" "each check" "all the checks" "every number" "each number" "all checks" \
  "every <m>" "each <m>" -- \
  "\`with\`" "with list" "with <m" "with\` list"
carries_any "as checks <m>, <m> for several" \
  "checks <m>, <m>" "checks <m>,<m>" "checks <m> and <m>" "checks <m,...>" "checks <m>, ..."
carries_each "a with none line reads not fixed: conflicted with no check of its Wave" \
  "with none" "\`none\`" -- "not fixed: conflicted with no check of its Wave"
carries_each "naming the files that line quoted" \
  "files" "paths" "<path>" -- "quoted" "quotes" "the line names" "it names" "named"
reply_step="$(passage_of "$pr" "### 5. Reply" "##" 2>/dev/null)"
flat="$(sed 's/^[[:space:]]*//' <<<"$reply_step" | grep '^round [0-9<]')"
carries "the Reply's round lines give one reading not fixed: conflicted with" \
  "not fixed: conflicted with"

# A check left red after two moves lost to a coupling the head may since have absorbed: a mark
# carried out of its round would keep it out of every later round's Waves, or spend its moves
# before it ever ran. Step 4 says "this round" throughout, so the guarantee is read off the piece
# keyed on wording only a later round's handling carries.
echo "# pr.md / ### 4. Fix the red checks: a check left red after two moves carries no mark out of its round, so a later round groups its Waves from the watch's red= lines alone and the check's moves count from zero again"
step="$(passage_of "$pr" "### 4. Fix the red checks" "##" 2>/dev/null)"
flat="$(piece_in="$step" piece_with "later round" "next round" "following round" "from zero" \
  "count again" "counted again" "lines alone")"
expect "a paragraph of the step says what a later round does with a check left red after two moves" \
  test -n "$flat"
carries_each "the count of moves belongs to the round: nothing the run keeps from it marks the check" \
  "no mark" "not marked" "never marked" "unmarked" "marks it" "marks the check" "keeps no" \
  "carries nothing" "carries no" "no record" -- \
  "round"
carries_each "a later round numbers and groups its checks from that round's watch red= lines alone" \
  "later round" "next round" "following round" -- \
  "red=" -- \
  "alone" "only" "nothing else"
carries_each "the check left red goes into that round's Waves like any other red check" \
  "like any other" "as any other" "same as any other" "with the other red checks" -- \
  "Wave"
carries_any "and its moves count from zero again" \
  "from zero" "from 0" "count again" "counted again" "counted afresh" "count afresh" "anew" \
  "start over" "starts over" "starts again" "reset"

# The developer may have the head checked out, dirty or on another branch: a round integrated in
# their checkout moves their branch or mixes the run's commits with their work in progress. The
# round is read off step 4 alone: `not fixed <k>:` already sits there, so the pick's trigger is
# pinned with its opening backtick, and what follows the pick and the removal is read off the stretch
# of the step from each command on, since step 3's sub-items already say "any other line stops the
# run quoting it" in the same paragraph.
echo "# pr.md / ### 4. Fix the red checks and ## What this run never does: the round is integrated in a detached worktree of the run's own cut at sha=, through fix-integrate.sh, and the developer's checkout is never committed in, checked out or moved"
step="$(passage_of "$pr" "### 4. Fix the red checks" "##" 2>/dev/null)"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ')"
whole="$flat"
carries "the run tree is fetched and cut detached at the watched sha, under the main checkout's worktrees" \
  "git fetch origin <head>" \
  "git worktree add --detach <main checkout>/.claude/worktrees/pr-<n>-<at> <sha>"
before "the run tree is cut before the excerpts are" "git worktree add --detach" "pr-log.sh"
carries_each "detached because the developer may have the head checked out and git refuses a branch checked out twice" \
  "detached" -- "developer" -- "twice" "checked out in two" "a second worktree" "already checked out" -- \
  "refus" "won't" "will not"
carries_each "nothing the run does moves the developer's head" \
  "developer" -- \
  "never moves" "moves nothing" "nothing the run does moves" "does not move" "doesn't move" "never move" \
  "never touches" "leaves the developer's"
carries_each "a refusal from git on either line stops the run quoting git's line" \
  "refus" -- "either line" "either of" "both lines" "each line" "either command" -- \
  "git's line" "git's own line" "git's error" "git's stderr" "line git printed" "git's message" "git's refusal"
carries_any "a fixer's \`fixed <k>:\` return is what gets picked" "\`fixed <k>:" "\`fixed <k>\`"
carries "fix-integrate.sh brings the fixer's branch onto the run tree, printing the picked line" \
  "bash <skill-dir>/../do-code-review/scripts/fix-integrate.sh <run tree> <k>=<branch>" "picked <k> <sha>"
before "the pick comes before the fixer's worktree is taken back" "fix-integrate.sh" "fix-worktrees.sh remove"
flat=""
[[ $whole == *fix-integrate.sh* ]] && flat="${whole#*fix-integrate.sh}" && flat="${flat%%fix-worktrees.sh remove*}"
carries_each "past the pick, any other line from it stops the run quoting that line" \
  "any other line" "Any other line" "other line" "anything else" -- "stops" -- "quoting" "quotes" "quoted"
carries_each "any other return gets no pick and the check stays red this round" \
  "any other return" "Any other return" "other return" "not fixed" -- \
  "no pick" "not picked" "nothing is picked" "picks nothing" "nothing picked" "never picked" -- \
  "stays red" "remains red" "still red" "left red" -- "this round" "the round"
flat="$whole"
carries "fix-worktrees.sh remove takes the fixer's worktree back" \
  "bash <skill-dir>/../do-code-review/scripts/fix-worktrees.sh remove <run tree> <branch>"
flat=""
[[ $whole == *"fix-worktrees.sh remove"* ]] && flat="${whole#*fix-worktrees.sh remove}"
carries "past the removal, its removed or kept line" "removed" "kept"
carries_each "goes to the Reply's round lines as it stands" \
  "round line" "round lines" "Round" -- "Reply" -- \
  "as it stands" "as printed" "as they stand" "verbatim" "unchanged" "as it reads"
never="$(passage_of "$pr" "## What this run never does" "##" 2>/dev/null)"
flat="$(piece_in="$never" piece_with "developer's checkout" "developer's own checkout" \
  "developer's working tree" "developer's work tree" "developer's tree" "checkout of the developer")"
expect "a bullet of \`## What this run never does\` names the developer's checkout" test -n "$flat"
carries_each "the run never commits in, checks out or moves anything in it" \
  "commit" -- "check out" "checks out" "checking out" -- "move" "moving"
flat="$(tr '\n' ' ' <<<"$never" | tr -s ' ')"
carries_each "nor fixes a check in the session" \
  "fix a check" "fixing a check" "fixes a check" "fix the check" "Fix a check" "Fixing a check" "a fix" -- \
  "session"

# Others push to the head too, such as `dev`, and a forced push or a merge loses or rewrites their
# commits: the round goes onto the head by fast-forward alone, and git refusing a non-fast-forward is
# the guard (ADR 0086). The push item is read from its own marker line, top-level or a sub-item of
# the per-check loop, to the next one, and the SKILL.md and reply.md guarantees off their one bullet,
# so a clause elsewhere in either file does not count.
echo "# pr.md / ### 4. Fix the red checks, ## What this run never does, SKILL.md / ## Non-negotiables, reply.md / **A push.**: the round is pushed to the head by fast-forward only, never --force, never a merge, never another branch, and it is the one push a run makes"
push_line="git -C <run tree> push origin HEAD:refs/heads/<head>"
step="$(passage_of "$pr" "### 4. Fix the red checks" "##" 2>/dev/null)"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ')"
whole="$flat"
carries "the step pushes the round with the exact push line" "$push_line"
before "the push comes after the fix-integrate.sh pick" "fix-integrate.sh" "$push_line"
out="$(grep -F "push origin" <<<"$step")"
expect "the step has a line carrying \`push origin\`" test -n "$out"
check_absent "the push line forces nothing: no --force, no -f, no + on the refspec" 0 0 \
  "--force" " -f" "+HEAD" "+refs/"
flat="$(item_holding <(printf '%s\n' "$step") '[0-9]+\.|[[:space:]]+[a-z]\.' "$push_line" | tr '\n' ' ' | tr -s ' ')"
expect "the push line sits in an item of the step" test -n "$flat"
carries_any "the item runs when at least one check was picked" \
  "at least one check" "at least one \`picked" "a check was picked" "any check was picked" \
  "one check was picked" "something was picked" "at least one pick"
carries_any "the push is fast-forward only" \
  "fast-forward only" "only by fast-forward" "by fast-forward only" "fast-forwards only" \
  "only a fast-forward" "only fast-forward"
carries "never --force" "--force"
carries_any "never a merge" \
  "never a merge" "never as a merge" "not a merge" "no merge" "never merges" "never merged"
carries_any "never to another branch" \
  "never to another branch" "never to any other branch" "no other branch" "never another branch" \
  "never to a branch" "any other branch" "never to any branch but"
carries "per ADR 0086" "ADR 0086"
carries_each "git's own refusal of a non-fast-forward is the guard" \
  "refus" "reject" -- "non-fast-forward" "not a fast-forward" "not fast-forward" -- "guard"
carries_each "when git refuses the push the run stops quoting git's line" \
  "refus" "reject" -- "stops" -- \
  "git's line" "git's own line" "git's error" "git's stderr" "line git printed" "git's message" "git's refusal"
carries_each "keeping <run tree> and naming it" \
  "<run tree>" -- "keep" "kept" "leaves" "left in place" -- "nam"
flat=""
[[ $whole == *fix-integrate.sh* ]] && flat="${whole#*fix-integrate.sh}"
carries_each "when no check was picked nothing is pushed" \
  "no check was picked" "no check is picked" "nothing was picked" "nothing is picked" "none was picked" \
  "no pick" "picked nothing" -- \
  "nothing is pushed" "pushes nothing" "no push" "never pushes" "nothing pushed" "is not pushed"
carries_each "the run removes <run tree> and stops with one line per check quoting its fixer's return" \
  "remove" -- "<run tree>" -- \
  "one line per check" "a line per check" "one line for each check" "a line for each check" -- \
  "quoting" "quotes" "quoted" -- "return"
never="$(passage_of "$pr" "## What this run never does" "##" 2>/dev/null)"
flat="$(piece_in="$never" piece_with "--force")"
expect "a bullet of \`## What this run never does\` names --force" test -n "$flat"
carries_any "a push with --force" "push" "Push"
flat="$(piece_in="$never" piece_with "any branch but the head" "any branch but \`<head>\`" \
  "another branch" "any other branch" "other than the head" "a branch other than")"
expect "a bullet of \`## What this run never does\` names a branch other than the head" test -n "$flat"
carries_any "a push to it" "push" "Push"
flat="$(piece_in="$never" piece_with "merge into the head" "merge into \`<head>\`" "merge it into" \
  "merge commit" "a merge into" "Merge into the head" "merging into the head" "merge onto the head")"
expect "a bullet of \`## What this run never does\` names a merge into the head" test -n "$flat"
flat="$(bullets_opening_on <(passage_of "$skill" "## Non-negotiables" "## ") \
  "The run never lands and never fixes a Finding")"
expect "SKILL.md's Non-negotiables carries the bullet on landing and fixing" test -n "$flat"
carries_any "it names the \`pr\` Playbook's push" "\`pr\` Playbook" "pr Playbook"
carries_any "as the one push a run makes" "one push" "only push"
carries_each "its own fixers' commits onto its pull request's head branch" \
  "fixer" -- "commit" -- "head branch" "pull request's head" "its head"
carries_any "by fast-forward only" \
  "fast-forward only" "only by fast-forward" "by fast-forward only" "fast-forwards only" "only a fast-forward"
carries "never --force" "--force"
carries_any "never a merge" \
  "never a merge" "never as a merge" "not a merge" "no merge" "never merges" "never merged"
carries_any "never to any other branch" \
  "any other branch" "another branch" "no other branch" "never to a branch"
carries "per ADR 0086" "0086"
flat="$(bullets_opening_on <(passage_of "$reply" "## A refusal or a blocked run" "## ") "**A push.**")"
expect "reply.md's refusal section carries the **A push.** bullet" test -n "$flat"
carries_each "the \`pr\` round's push is the exception ADR 0086 authorises" \
  "\`pr\`" -- "round" -- "ADR 0086" -- "authoris" "authoriz" "allows" "permits"
carries_each "never named under outward" \
  "outward" -- \
  "never named under" "never names it under" "not named under" "never under \`outward\`" \
  "never names that push under" "never named as" "never goes under"

# A run that ends on the push leaves the developer who walked away with a fix nobody watched, and one
# that loops on red with no round cap pushes without end: the push sends the run back to the watch,
# and a red verdict after a pushed round stops it. The second-round bullet is keyed on a pushed
# round, so the first-round bullet, which says "has pushed no round yet", never answers for it.
echo "# pr.md / ### 4. Fix the red checks and ### 3. Watch: after the push the run watches again with <pr> alone, and verdict=red after a pushed round stops it on one line naming the checks still red"
step="$(passage_of "$pr" "### 4. Fix the red checks" "##" 2>/dev/null)"
flat="$(item_holding <(printf '%s\n' "$step") '[0-9]+\.|[[:space:]]+[a-z]\.' "$push_line" | tr '\n' ' ' | tr -s ' ')"
expect "the push line sits in an item of the step" test -n "$flat"
carries_each "when git accepts the push, the run goes back to step 3" \
  "accept" -- "step 3" "### 3. Watch"
carries_any "calling the watch with \`<pr>\` alone, no \`<since>\` \`<state>\`" \
  "\`<pr>\` alone" "with \`<pr>\` alone" "\`<pr>\` and nothing else" "only \`<pr>\`" "\`<pr>\` only"
flat="$(piece_with "after step 4 has pushed" "after step 4 pushed" "once step 4 has pushed" \
  "has pushed a round" "pushed a round" "after a pushed round" "a round was pushed" "round has been pushed")"
expect "a bullet or paragraph of the watch step takes a verdict after a pushed round" test -n "$flat"
out="$flat"
absent "it is not the first-round bullet" "pushed no round"
carries "it names \`verdict=red\`" "verdict=red"
carries_any "the run stops" "stops" "ends the run" "the run ends"
carries_each "with one line quoting the names on the verdict's \`red=\` lines" \
  "one line" "One line" "single line" -- "red=" -- "quot" "nam"
carries_any "and follows nothing" "follows nothing" "nothing followed" "follows no" "never follows"
carries_any "one round per run" "one round"

# A pushed round lands commits on a head others build on, in the developer's name: a Reply that
# leaves it out hides what landed, and one that gives the round a part of its own breaks the five
# parts every grader reads. The step's intro already says "adds no part of its own" for a green
# watch, so the round's own guarantee is read off the bullet or paragraph naming the round.
echo "# pr.md / ### 5. Reply and reply.md item 1: a pr run that pushed a round lists, under For whom, each red check with its fixer, the commit pushed or what the fixer returned, and the verdict the watch read after the push"
reply_step="$(passage_of "$pr" "### 5. Reply" "##" 2>/dev/null)"
out="$(sed 's/^[[:space:]]*//' <<<"$reply_step")"
check_lines "the Reply step shows the round lines, as whole lines" 0 0 \
  'round 1: <check> red; do-pr-fixer on <fixer branch>: <picked sha> pushed to <head>' \
  'round 1: <check> red; do-pr-fixer on <fixer branch>: <its return line>; nothing pushed for it' \
  'round 1: <a `kept` line, as fix-worktrees.sh printed it>' \
  'round 1: after the push the watch read <verdict word>'
flat="$(tr '\n' ' ' <<<"$reply_step" | tr -s ' ')"
carries "the Reply keeps its five parts" "five parts"
carries_any "as the whole message" "the whole message" "whole of the message"
flat="$(piece_in="$reply_step" piece_with "pushed a round" "pushed its round" "pushed the round" \
  "a pushed round" "round lines" "round line" "the round's lines")"
expect "a bullet or paragraph of the Reply step names the pushed round" test -n "$flat"
carries "the round lines sit under For whom" "For whom"
carries_any "adding no part of their own" \
  "no part of its own" "no part of their own" "not a part of its own" "never a part of its own" \
  "no section of its own" "no section of their own" "never a section of its own" \
  "inside the five parts" "within the five parts" "in the five parts" "adds no part" "add no part"
item="$(item_holding <(passage_of "$reply" "## Sections" "## ") '[0-9]+\.' "1. **For whom.**" | tr '\n' ' ' | tr -s ' ')"
expect "reply.md's Sections carry item 1, For whom" test -n "$item"
flat="$item"
carries_each "a \`pr\` run that pushed a round carries its round lines there" \
  "\`pr\`" "pr run" "pr Playbook" -- "round" -- "pushed" "push"
carries_each "one line per red check naming the check" \
  "red check" "check that was red" "check red" -- \
  "one line per" "a line per" "one line for each" "a line for each" "each red check" "every red check"
carries_each "its fixer, do-pr-fixer and its branch" "do-pr-fixer" -- "branch"
carries_each "the commit pushed or what its fixer returned" \
  "commit" "sha" -- "pushed" -- "returned" "its return" "return line"
carries_each "and the verdict the watch read after the push" \
  "verdict" -- "after the push"

# A pushed round moves the remote head past the developer's own checkout of it: a Next step naming
# only the merge leaves their next commit on a stale head, whose push the remote then refuses. The
# green-watch bullet already names `gh pr merge <n>` and `outward`, so the words are read off the
# piece of the Reply step naming the pull, and off the sentence of item 10 naming it and the next.
echo "# pr.md / ### 5. Reply and reply.md item 10: a pr run that pushed names git pull --ff-only origin <head> for the developer's checkout ahead of gh pr merge <n>, runs neither, names neither under outward"
pull_line="git pull --ff-only origin <head>"
reply_step="$(passage_of "$pr" "### 5. Reply" "##" 2>/dev/null)"
flat="$(piece_in="$reply_step" piece_with "$pull_line")"
expect "a bullet or paragraph of the Reply step names \`$pull_line\`" test -n "$flat"
carries_any "on a run that pushed" "pushed" "push"
carries_each "for the developer's checkout of \`<head>\`" \
  "developer" -- "checkout" "local" "clone" "working tree" -- "<head>"
carries_each "on the **Next step** line, with \`gh pr merge <n>\`" "Next step" -- "gh pr merge <n>"
before "the pull comes before the merge" "$pull_line" "gh pr merge <n>"
carries_any "the run runs neither" \
  "never runs" "does not run" "doesn't run" "never run" "runs neither" "runs none" "not run" \
  "runs nothing" "never runs either"
carries_each "nor names either under \`outward\`" \
  "outward" -- \
  "never names them under" "never names either under" "never names it under" "never names either" \
  "never named under" "not named under" "nor names them under" "nor names either" "nor under" \
  "never under \`outward\`" "neither under" "never as \`outward\`" "never an \`outward\`"
item="$(item_holding <(passage_of "$reply" "## Sections" "## ") '[0-9]+\.' "10. **Next step.**" | tr '\n' ' ' | tr -s ' ')"
expect "reply.md's Sections carry item 10, Next step" test -n "$item"
flat="$(sed 's/\. /.\n/g' <<<"$item" | awk 'index($0, "git pull --ff-only") { print; getline; print; exit }' | tr '\n' ' ')"
expect "a sentence of item 10 names \`git pull --ff-only\`" test -n "$flat"
carries_each "for a \`pr\` run that pushed" "\`pr\`" "pr run" -- "push"
carries "naming \`$pull_line\`" "$pull_line"
carries_each "the pull of the developer's local head" "developer" -- "local" "checkout" "clone"
carries "then \`gh pr merge <n>\`" "gh pr merge <n>"
before "the pull first, the merge after it" "$pull_line" "gh pr merge <n>"
carries_each "the push reported on For whom's round lines" "For whom" -- "round line" "round lines"
carries_each "never an \`outward\` hand-over" \
  "outward" -- \
  "never an \`outward\`" "never \`outward\`" "never under \`outward\`" "not an \`outward\`" \
  "never named under" "never names it under" "no \`outward\`" "never an outward" "not under \`outward\`"
carries "since ADR 0086 authorised it" "ADR 0086"
[ "$fails" -eq 0 ] && exit 0
exit 1
