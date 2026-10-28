#!/usr/bin/env bash
# final-stopped-readers.sh: final-stopped.md is read by the readers its opening names, each on the
# condition that sends it, so a maintainer finds in one place when a run must read the stop's steps.
# Run: bash skills/do/tests/final-stopped-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
do_dir="$(cd "$here/.." && pwd -P)"
final_stopped="$do_dir/references/final-stopped.md"
fails=0

readers=("the Door" "The Door"
  -- "the Final integration" "The Final integration" "a Final integration" "A Final integration")
conditions=("verdict=resume-final" -- "stops")

echo "# final-stopped.md: its opening names every reader that reaches it and the condition that sends each"
expect "final-stopped.md exists" test -f "$final_stopped"
flat="$(awk '/^## /{exit} !/^# / {print}' "$final_stopped" 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
expect "final-stopped.md has an opening before its first section" grep -q '[a-z]' <<<"$flat"
carries_each "the opening names the Door and the Final integration" "${readers[@]}"
carries_each "the opening names each condition: the door printing verdict=resume-final, the Final integration when it stops" \
  "${conditions[@]}"

echo "# SKILL.md: the references-list entry for final-stopped.md names the same readers and conditions"
skill="$do_dir/SKILL.md"
flat="$(bullets_opening_on "$skill" "[final-stopped.md](references/final-stopped.md)" | tr -s ' ')"
expect "SKILL.md's references list has an entry for final-stopped.md" test -n "$flat"
carries_each "the entry names the Door and the Final integration" "${readers[@]}"
carries_each "the entry names each condition: the door printing verdict=resume-final, the Final integration when it stops" \
  "${conditions[@]}"
skill_links="$(grep -cE '\]\(([^)]*/)?final-stopped\.md\)' "$skill")"
expect "SKILL.md links final-stopped.md in its references-list entry alone" test "$skill_links" = 1

# A resume that loses a route lands nothing or lands twice: each step is read as the run meets it,
# found by what it calls rather than by its number, and each route or verdict by the bullet that
# opens on it, so one route's consequence never answers for another's.
echo "# final-stopped.md: the resume of a stopped Final integration, entry and steps"
step_marker='[0-9]+\. |#{2,4} [0-9]+\.'
bullets_of() { bullets_opening_on /dev/stdin "- " <<<"$1"; }         # $1 a step: its bullets, flattened, one per line
bullet_on() { grep -F -- "$2" <<<"$(bullets_of "$1")" | tr -s ' '; } # $1 a step, $2 a fixed string: the bullets carrying it

flat="$(tr '\n' ' ' <"$final_stopped" | tr -s ' ')"
carries_each "the resume is entered on the door's verdict=resume-final and nothing else" \
  "verdict=resume-final" -- "on nothing else" "and nothing else" "nowhere else" "nowhere earlier"
carries_each "nothing before the final integration is built again: no Digest, no Plan, no Builder, no do/<slug> worktree" \
  "no Digest" -- "no Plan" "no Planner" -- "no Builder" -- "no \`do/<slug>\` worktree" "no do/<slug> worktree"
carries "the same entry is the landing command of a feature across repositories" "landing command"
before "the landing record is read before the claim" "landing-route.sh resume" "final-claim.sh claim"
before "the claim is taken before the state is read" "final-claim.sh claim" "final-state.sh"

step="$(item_holding "$final_stopped" "$step_marker" "landing-route.sh resume")"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ')"
expect "step 1, the landing record, is found" test -n "$step"
carries "step 1 saves the landing record and hands it to landing-route.sh resume" \
  "landing-order.sh" "| tee <state>/order" "landing-route.sh resume"
flat="$(bullet_on "$step" '`route=claim`')"
expect "step 1 has a bullet for route=claim" test -n "$flat"
carries_any "route=claim goes on to the claim" "to the claim" "step 2" "the claim of step"
flat="$(bullet_on "$step" '`route=out-of-order`')"
expect "step 1 has a bullet for route=out-of-order" test -n "$flat"
carries_each "route=out-of-order stops before the claim" "stop" -- "before the claim" "before the \`claim\`"
for route in skip-landed skip-elsewhere skip-open blocked-ambiguous blocked-unordered blocked-no-spec; do
  flat="$(bullet_on "$step" "\`route=$route\`")"
  expect "step 1 has a bullet for route=$route" test -n "$flat"
  carries_each "route=$route takes step 9a's route and claims nothing" \
    "9a" -- "claims nothing" "claim nothing" "no claim" "never claims"
done
flat="$(bullet_on "$step" "xit 2")"
expect "step 1 has a bullet for its exit 2" test -n "$flat"
carries "step 1's exit 2 stops as blocked" "blocked"

step="$(item_holding "$final_stopped" "$step_marker" "final-claim.sh claim")"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ')"
expect "step 2, the claim, is found" test -n "$step"
carries "step 2 takes the claim and saves it" "final-claim.sh claim" "| tee <state>/claim"
flat="$(bullet_on "$step" '`claim=claimed`')"
carries "claim=claimed holds the claim with takeover=yes" "takeover=yes"
flat="$(bullet_on "$step" '`claim=taken`')"
expect "step 2 has a bullet for claim=taken" test -n "$flat"
carries_each "claim=taken stops and writes nothing" "stop" -- "writes nothing" "write nothing" "nothing is written"
subject_denies "claim=taken never yields another holder's claim" "run|Run" \
  "yields another holder's claim" "yield another holder's claim" "yields another holder" "yields the claim of another"
flat="$(bullet_on "$step" '`claim=failed`')"
expect "step 2 has a bullet for claim=failed" test -n "$flat"
carries "claim=failed stops as blocked" "blocked"

step="$(item_holding "$final_stopped" "$step_marker" "final-state.sh")"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ')"
expect "step 3, where it stopped, is found" test -n "$step"
carries "step 3 reads the state and saves it" "final-state.sh" "| tee <state>/state"
flat="$(bullet_on "$step" '`verdict=restart`')"
expect "step 3 has a bullet for verdict=restart" test -n "$flat"
flat="$(bullet_on "$step" '`verdict=integration`')"
carries "verdict=integration points at resume.md" \
  "Read [resume.md](resume.md) when final-state.sh prints verdict=integration"
flat="$(bullet_on "$step" '`verdict=ask`')"
carries "verdict=ask points at resume.md" "Read [resume.md](resume.md) when final-state.sh prints verdict=ask"
flat="$(bullet_on "$step" '`verdict=land`')"
expect "step 3 has a bullet for verdict=land" test -n "$flat"
carries_each "verdict=land lands through the fix call with no second review" \
  "fix call" -- "never a second review" "no second review" "not a second review"
flat="$(bullet_on "$step" "xit 2")"
expect "step 3 has a bullet for its exit 2" test -n "$flat"
carries "step 3's exit 2 stops as blocked" "blocked"

step="$(item_holding "$final_stopped" "$step_marker" "landed at <commit>")"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ')"
expect "step 4, the rest of the final integration, is found" test -n "$step"
carries "step 4 ends in the release on landed at <commit>" "release" "landed at <commit>"
carries_each "after claim=released on more than one repository, landing-order.sh runs a second time over <state>/order" \
  "claim=released" -- "repositories=" -- "landing-order.sh" -- "<state>/order" -- "second time" "a second" "again"

# A stop that never yields leaves a claim no later /do can take over, and one that never reads the
# landing record again leaves a partial landing silent: the stop's steps are read in the section of
# final-stopped.md whose heading names the stop, so the resume's own yield or record never answers
# for them.
echo "# final-stopped.md: the stop of a Final integration, in a section of its own"
stop_section="$(awk '/^## / { if (on) exit; h = tolower($0); on = h ~ /stop/ && h !~ /resume/ } on' "$final_stopped")"
flat="$(tr '\n' ' ' <<<"$stop_section" | tr -s ' ')"
expect "final-stopped.md has a section whose heading names the stop" test -n "$stop_section"
carries_any "a stop makes no release call" \
  "no \`release\` call" "no release call" "never calls \`release\`" "never makes a \`release\` call"
carries_each "the tree, the Spec branch and the claim file stay in place" \
  "tree" "worktree" -- "Spec branch" -- "claim file" "the claim" -- "stay" "in place"
carries_any "the run's own Ticket stays resolved" "stays \`resolved\`" "remains \`resolved\`"
carries "the run yields the claim and saves the yield" \
  "final-claim.sh yield <the Ticket's path>" "| tee <state>/yield"
carries_each "the yield is made at every stop the run controls, a first run's or a resume's" \
  "every stop" "any stop" "each stop" -- "first run" -- "resume"
carries_any "the yield comes before the Reply" \
  "Before its Reply" "before its Reply" "Before the Reply" "before the Reply" \
  "Before that Reply" "before that Reply" "before it replies" "Before it replies"
flat="$(paragraph_with /dev/stdin "landing-order.sh" <<<"$stop_section" | tr -s ' ')"
expect "the stop's section reads the landing record" test -n "$flat"
carries_each "after the yield the landing record is read again over <state>/order, on a first run and on a resume alike" \
  "after the yield" "After the yield" "after yielding" "After yielding" -- "<state>/order" -- "first run" -- "resume"
flat="$(tr '\n' ' ' <<<"$stop_section" | tr -s ' ')"
carries_each "a repository that landed before the stop stays landed and the run moves no ref there" \
  "stays landed" "stay landed" -- "moves no ref" "no ref moved" "never moves a ref" "touches nothing there"
flat="$(paragraph_with /dev/stdin "stops again" <<<"$stop_section" | tr -s ' ')"
expect "the stop's section names a resume that stops again" test -n "$flat"
carries_any "a resume that stops again yields as any stop does" "yields" "yield"

# A Reply written from two files is two shapes of one Reply, and the developer's `Yours:` line can
# lose its `yield_command=` or a way out in the copy nobody updated: final-stopped.md carries none
# of the Reply's text and sends the session to the Reply references at each stop, which carry it.
echo "# final-stopped.md: the Reply of a stopped Final integration is read in the Reply references"
reply="$do_dir/references/reply.md"
blocked_reply="$do_dir/references/blocked-reply.md"
to_blocked='Read \[blocked-reply\.md\]\(blocked-reply\.md\) when [^ ]'
to_reply='Read \[reply\.md\]\(reply\.md\) when [^ ]'
# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$(tr '\n' ' ' <"$final_stopped" | tr -s ' ')"
check_absent "final-stopped.md carries no Reply shape: no Yours: line, no shell line, no message, blocker or quote of its own" 0 0 \
  "\`Yours:" "Yours: direction" "no shell line" "The message is the first line" \
  "The Reply says the Final integration stopped" "Its blocker is" "the Reply quotes \`yield_command=\`"
flat="$(awk 'BEGIN { RS = "" } !index($0, "stops again") { gsub(/\n/, " "); print }' <<<"$stop_section" | tr -s ' ')"
expect "the stop's section sends the Reply to blocked-reply.md" grep -qE "$to_blocked" <<<"$flat"
flat="$(paragraph_with "$final_stopped" "stops again" all | tr -s ' ')"
expect "a resume that stops again sends its Reply to blocked-reply.md" grep -qE "$to_blocked" <<<"$flat"
step="$(item_holding "$final_stopped" "$step_marker" "landing-route.sh resume")"
flat="$(paragraph_with /dev/stdin "out-of-order" all <<<"$step" | tr -s ' ')"
expect "step 1's route=out-of-order stop sends its message to reply.md" grep -qE "$to_reply" <<<"$flat"
step="$(item_holding "$final_stopped" "$step_marker" "final-claim.sh claim")"
flat="$(bullet_on "$step" '`claim=taken`')"
expect "step 2's claim=taken bullet sends its Reply to blocked-reply.md" grep -qE "$to_blocked" <<<"$flat"
flat="$(paragraph_with "$final_stopped" "resume that finishes" all | tr -s ' ')"
expect "a resume that finishes sends its Reply to reply.md" grep -qE "$to_reply" <<<"$flat"

echo "# reply.md and blocked-reply.md: every Reply line of a stopped Final integration stands there"
item="$(item_holding <(passage_of "$reply" "## Run" "## Sections") '[0-9]+\.' "**Final integration lines.**")"
flat="$(bullet_on "$item" "built no Ticket and took no claim")"
expect "reply.md's item 30 has a bullet for a run that built no Ticket and took no claim" test -n "$flat"
carries_each "that message carries no Yours: line and no shell line" \
  "no \`Yours:\` line" "no Yours: line" -- "no shell line"
carries_each "under --auto that message is the same lines with no choice-taker forked" \
  "\`--auto\`" -- "same lines" -- "no \`choice-taker\`" "no choice-taker" "\`choice-taker\` is never forked" "never forks"
flat="$(paragraph_with "$blocked_reply" "read \`taken\`" all | tr -s ' ')"
carries "blocked-reply.md's claim=taken resume quotes yield_command= on its Yours: line" "yield_command=" "Yours:"
flat="$(grep -F "Yours: direction: wait for that run" "$blocked_reply")"
carries "the claim=taken Yours: direction: line offers waiting and running the yield command" \
  "/do <ticket> again" "<yield_command>"
flat="$(paragraph_with "$blocked_reply" "Final integration stopped" | tr -s ' ')"
carries "the stopped Final integration's blocker names the Spec branch and its worktree, on outcome=final-stopped" \
  "Spec branch" "worktree" "outcome=final-stopped"
flat="$(paragraph_with "$blocked_reply" "stops again" | tr -s ' ')"
carries "a resume that stops again ends on outcome=final-stopped" "outcome=final-stopped"
row="$(grep -F "resume of one that finished" "$reply" | head -n 1)"
outcome="$(awk -F'|' '{ m = $3; gsub(/^ +| +$/, "", m); print m }' <<<"$row")"
expect "reply.md's outcome= table routes a resume that finished to final-landed" test "$outcome" = '`final-landed`'

echo "# final-stopped.md: instructions only, no ADR given as a reason"
# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$(tr '\n' ' ' <"$final_stopped" 2>/dev/null | tr -s ' ')"
expect "final-stopped.md has text" test -n "$out"
check_absent "final-stopped.md links no ADR and cites none as a step's reason" 0 0 \
  "docs/adr/" "per ADR" "ADR 0"

# ticket.md is loaded whole on every ticket run, so a stop and resume kept there rides in the window
# of every run whose Final integration never stops, and a Door that points at a section no longer
# there leaves a resume with no steps: the Door sends verdict=resume-final to final-stopped.md.
echo "# ticket.md: the stopped Final integration is read in final-stopped.md, and the Door sends it there"
ticket="$do_dir/references/ticket.md"
headings="$(grep -ciE '^#+ .*stopped final integration' "$ticket")"
expect "ticket.md has no section for a stopped Final integration" test "$headings" = 0
out="$(tr '\n' ' ' <"$ticket" | tr -s ' ')"
absent "ticket.md carries no resume step reading the landing record through landing-route.sh resume" \
  "landing-route.sh resume"
absent "ticket.md carries no resume step taking the claim over with takeover=yes" "takeover=yes"
absent "ticket.md carries no resume step reading where it stopped through final-state.sh" \
  "final-state.sh <the Ticket's path>"
door="$(passage_of "$ticket" "## Door" "## ")"
flat="$(tr '\n' ' ' <<<"$door" | tr -s ' ')"
expect "the Door is found" test -n "$door"
expect "the Door reads final-stopped.md when the door prints verdict=resume-final" grep -qE \
  'Read \[final-stopped\.md\]\(final-stopped\.md\) when ([^.]|\.[a-z])*verdict=resume-final' <<<"$flat"
units="$({
  bullets_opening_on /dev/stdin "- " <<<"$door"
  awk 'BEGIN { RS = "" } /^[^ -]/ { gsub(/\n/, " "); print }' <<<"$door"
} | tr -s ' ' | grep -F 'verdict=resume-final')"
expect "the Door names verdict=resume-final" test -n "$units"
out="$(grep -vF '](final-stopped.md)' <<<"$units" | cut -c1-160)"
same "every paragraph and bullet of the Door naming verdict=resume-final sends the run to final-stopped.md" ""
out="$units"
absent "no paragraph or bullet of the Door sends a verdict=resume-final run to a section of ticket.md" '`## '

# A first run whose Final integration stops must reach the yield before its Reply, and every run
# whose Final integration lands carries the stop and the resume in its window when the readers of
# the final integration keep them: mechanics.md and step 9a send a stop to final-stopped.md.
echo "# mechanics.md and ticket.md step 9a: a Final integration that stops is sent to final-stopped.md"
to_stopped_on_stop='Read \[final-stopped\.md\]\(final-stopped\.md\) when ([^.]|\.[a-z])*stops'
mechanics="$do_dir/references/mechanics.md"
section="$(passage_of "$mechanics" "## The final integration" "## ")"
expect "mechanics.md's final integration section is found" test -n "$section"
out="$(tr '\n' ' ' <<<"$section" | tr -s ' ')"
absent "mechanics.md's final integration carries no paragraph of its own for a stop" \
  "**A Final integration that stops.**"
absent "mechanics.md's final integration carries no paragraph of its own for a resume" \
  "**A resumed Final integration.**"
absent "mechanics.md's final integration carries no yield call of the stop" "final-claim.sh yield"
absent "mechanics.md's final integration carries no resume step reading the landing record through landing-route.sh resume" \
  "landing-route.sh resume"
absent "mechanics.md's final integration carries no resume step taking the claim over with takeover=yes" \
  "takeover=yes"
absent "mechanics.md's final integration carries no resume step reading where it stopped through final-state.sh" \
  "final-state.sh <the Ticket's path>"
expect "mechanics.md's final integration reads final-stopped.md when the Final integration stops" \
  grep -qE "$to_stopped_on_stop" <<<"$out"

step="$(passage_of "$ticket" "**9a. Final integration.**" "**10. Reply.**")"
expect "ticket.md's step 9a is found" test -n "$step"
out="$(tr '\n' ' ' <<<"$step" | tr -s ' ')"
absent "ticket.md's step 9a makes no yield call of its own: the stop's yield is final-stopped.md's" \
  "final-claim.sh yield"
expect "ticket.md's step 9a reads final-stopped.md when the Final integration stops" \
  grep -qE "$to_stopped_on_stop" <<<"$out"

# A maintainer finds every way into final-stopped.md by its one shape, and misses a reader written
# in another. Each paragraph is flattened first, so a pointer hard-wrapped across two lines is one
# pointer, and a link with no `Read ` before it or no ` when <condition>` after it is misshaped.
echo "# skills/do: every pointer to final-stopped.md reads Read [final-stopped.md](final-stopped.md) when <condition>"
link_to_stopped='\]\(([^)]*/)?final-stopped\.md(#[^)]*)?\)'
stopped_shape='Read \[final-stopped\.md\]\(final-stopped\.md\) when [^ ]'
pointers=0
misshaped=""
while IFS= read -r file; do
  case "$file" in "$skill" | "$final_stopped") continue ;; esac
  while IFS= read -r para; do
    links="$(grep -oE "$link_to_stopped" <<<"$para" | wc -l)"
    shaped="$(grep -oE "$stopped_shape" <<<"$para" | wc -l)"
    pointers=$((pointers + links))
    [ "$links" = "$shaped" ] || misshaped+="${file#"$do_dir"/}: ${para:0:160}"$'\n'
  done < <(awk 'BEGIN { RS = "" } { gsub(/\n/, " "); print }' "$file" | tr -s ' ')
done < <(grep -rlE "$link_to_stopped" "$do_dir" --exclude-dir=tests)
expect "the do skill carries pointers to final-stopped.md outside SKILL.md's references list" test "$pointers" -gt 0
expect "no pointer to final-stopped.md has another shape" test -z "$misshaped"
[ -z "$misshaped" ] || echo "      ${misshaped//$'\n'/$'\n'      }"

# resume.md and not-landed.md are read from the stopped Final integration, which now lives in
# final-stopped.md: an opening still placing it in ticket.md sends a maintainer to the wrong file.
echo "# resume.md and not-landed.md: their openings name the stopped Final integration as final-stopped.md"
clauses_of_opening() { # $1 file: its text before the first section, flattened, one clause (cut at "; " and ". ") per line
  awk '/^## /{exit} !/^# / {print}' "$1" 2>/dev/null | tr '\n' ' ' | tr -s ' ' | sed -E 's/(; |\. )/\n/g'
}
for opened in resume.md not-landed.md; do
  stop_clauses="$(clauses_of_opening "$do_dir/references/$opened" | grep -iF "final integration" | grep -iE 'stop')"
  expect "$opened's opening names the stopped Final integration among its readers" test -n "$stop_clauses"
  unnamed="$(grep -vF '`final-stopped.md`' <<<"$stop_clauses")"
  expect "$opened's opening names the stopped Final integration as \`final-stopped.md\`, beside it" \
    test -n "$stop_clauses" -a -z "$unnamed"
  [ -z "$unnamed" ] || echo "      ${unnamed//$'\n'/$'\n'      }"
done

exit $((fails > 0))
