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

exit $((fails > 0))
