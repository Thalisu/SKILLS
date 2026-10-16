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
flat="$(grep -E '^4\. ' <<<"$steps")"
carries_any "step 4 of the checklist is the reply, after the watch" "reply" "Reply"
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
  "verdict=green" -- "### 4. Reply" "step 4" "Reply step" "the Reply" "to the Reply"

# The developer merges on this Reply: one that misses the green state, or hands the merge over as a
# `Yours:` choice, reads as a stop, and a run that runs `gh pr merge` lands it with nobody deciding.
echo "# pr.md / ### 4. Reply: a green watch ends on a Reply saying every check is green and mergeable, its Next step gh pr merge <n>, never run"
flat="$(passage_of "$pr" "### 4. Reply" "##" 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
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

# A run that merges lands the pull request on its base with nobody having decided to. `### 4. Reply`
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
# round section in the message breaks them. `### 3. Watch` and `### 4. Reply` already name the
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
echo "# pr.md / ### 3. Watch and ### 4. Reply, reply.md item 10: a watch awaiting a required approval ends on a Reply saying only the approval is missing, no Yours:, gh pr merge <n> never run"
flat="$(piece_with "verdict=awaiting-approval")"
expect "a bullet or paragraph of the watch step names \`verdict=awaiting-approval\`" test -n "$flat"
carries_any "it hands on to step 4, the Reply, as a green watch does" \
  "### 4. Reply" "step 4" "Reply step" "to the Reply" "on to the Reply"
reply_step="$(passage_of "$pr" "### 4. Reply" "##" 2>/dev/null)"
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

[ "$fails" -eq 0 ] && exit 0
exit 1
