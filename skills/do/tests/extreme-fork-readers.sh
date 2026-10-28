#!/usr/bin/env bash
# extreme-fork-readers.sh: extreme-fork.md is read only by the step of a `ticket` run that meets an
# Extreme fork, so a run whose Design fork is settled loads none of its text, and every step that
# meets one is sent to it in the `Read <file> when <condition>` shape.
# Run: bash skills/do/tests/extreme-fork-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
do_dir="$(cd "$here/.." && pwd -P)"
extreme="$do_dir/references/extreme-fork.md"
forks="$do_dir/references/forks.md"
ticket="$do_dir/references/ticket.md"
resume="$do_dir/references/resume.md"
builder="$do_dir/references/builder.md"
fails=0
pointer="Read [extreme-fork.md](extreme-fork.md) when "

template_in() { # $1 file: the fenced `/discuss Ticket` line a stop copies, on stdout
  awk '/^```$/ { fence = !fence; next } fence && /^\/discuss Ticket/ { print; exit }' "$1" 2>/dev/null
}

echo "# extreme-fork.md carries the Extreme stop, and forks.md no longer does"
flat="$({ tr '\n' ' ' <"$extreme"; } 2>/dev/null | tr -s ' ')"
expect "extreme-fork.md exists" test -n "$flat"
carries_each "it says which fork is Extreme: a side weakening a guarantee in a risk class, or one that cannot be undone" \
  "security, privacy, data loss, auth, billing, migration" -- "cannot be undone once landed"
carries "the stop writes the \`<Ticket>.extreme.md\` sidecar a resume stops on" "<Ticket>.extreme.md"
carries "the reply ends on the line next-step.sh prints on \`outcome=extreme-fork\`" "outcome=extreme-fork"
expect "it holds the \`/discuss\` command a stop copies" test -n "$(template_in "$extreme")"
expect "forks.md holds no Extreme fork section" test -z "$(grep -E '^#+ Extreme fork' "$forks")"
expect "forks.md holds no \`/discuss\` template of its own" test -z "$(template_in "$forks")"

echo "# each step that meets an Extreme fork is sent to extreme-fork.md"
flat="$(bullets_opening_on "$resume" "An \`extreme=\` line")"
carries "resume.md's Resume, on a sidecar an Extreme stop left" "$pointer"
flat="$(bullets_opening_on "$resume" "A Spec amended while the Ticket")"
carries "resume.md's Resume, on a Spec amended after an Extreme stop" "$pointer"
flat="$(bullets_opening_on "$ticket" "\`fork\`: the Builder met")"
carries "ticket.md's build step, on a Builder's \`fork\` return the \`choice-taker\` reads as extreme" "$pointer"
flat="$(paragraph_with "$builder" "The fork report is the whole" | tr -s ' ')"
carries "builder.md's \`fork\` return, which classes nothing as Extreme itself" "$pointer"
flat="$(passage_of "$forks" "### Design fork" "### When no" | tr '\n' ' ' | tr -s ' ')"
carries "forks.md's Design fork steps, on a side read as Extreme or an \`extreme\` return" "$pointer"

echo "# every pointer to extreme-fork.md reads \`Read [extreme-fork.md](extreme-fork.md) when <condition>\`"
pointers_shaped "every pointer to extreme-fork.md has the \`Read <file> when <condition>\` shape" \
  "$do_dir" extreme-fork.md 5

echo "# extreme-fork.md and SKILL.md's entry name its readers and the condition that sends them"
readers=(
  "the Plan step" -- "the build step" -- "Resume" -- "the close" -- "the unruled stop" -- "change-of-direction"
)
condition=("read as Extreme" "reads as Extreme" -- "\`extreme\`" -- "\`extreme=\`")
flat="$(awk 'BEGIN { RS = "" } !/^#/ { gsub(/\n/, " "); print; exit }' "$extreme" 2>/dev/null | tr -s ' ')"
carries_each "the opening names the Plan and build steps, the Resume, the close, and the two stops that copy its command" \
  "${readers[@]}"
carries_each "the opening names the condition: a side read as Extreme, an \`extreme\` return, or the Resume's \`extreme=\` line" \
  "${condition[@]}"
flat="$(bullets_opening_on "$do_dir/SKILL.md" "[extreme-fork.md](references/extreme-fork.md)")"
expect "SKILL.md's references list has an entry for extreme-fork.md" test -n "$flat"
carries_each "the entry names the same readers" "${readers[@]}"
carries_each "the entry names the same condition" "${condition[@]}"

[ "$fails" -eq 0 ]
