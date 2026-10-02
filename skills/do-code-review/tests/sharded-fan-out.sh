#!/usr/bin/env bash
# sharded-fan-out.sh: what the orchestrator's fan-out does with the cut `scripts/shards.sh` prints.
# A diff the cut reports as one Shard is the run a developer already knows: one technical reviewer
# and one security reviewer, the same brief, the same two return files.
# The cases pin the script call, where it sits and the literal tokens a run acts on, never the
# contract's sentences.
# Run: bash skills/do-code-review/tests/sharded-fan-out.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
agent="$here/../AGENT.md"
fails=0

section="$(passage_of "$agent" "## 6. The fan-out" "## 7.")"
flat="$(flat_section "$agent" "## 6. The fan-out")"

echo "# AGENT.md / ## 6. The fan-out: the diff is cut before any reviewer is forked"
expect "AGENT.md carries the fan-out" test -n "$flat"
expect "the fan-out runs the cut script over the fixed point" \
  grep -qE 'do-code-review/scripts/shards\.sh <fixed[ _]point>' <<<"$flat"
before "the cut is taken before the reviewers are forked" \
  "scripts/shards.sh" "| \`subagent_type:"

echo "# AGENT.md / ## 6. The fan-out: a cut of one Shard is the unsharded run"
carries "the fan-out says what a cut of one Shard runs" "shards=1"

# The unsharded run's forks are the rows whose return file is the one a single reviewer of its kind
# writes: a sharded run's forks, when the table grows them, return into other files.
tech_rows="$(grep -F '| `subagent_type: do-code-review-technical-reviewer`' <<<"$section" | grep -F '/technical.md')"
sec_rows="$(grep -F '| `subagent_type: do-code-review-security-reviewer`' <<<"$section" | grep -F '/security.md')"
expect "one technical reviewer is forked, returning into technical.md" \
  test "$(grep -c . <<<"$tech_rows")" = 1
expect "one security reviewer is forked, returning into security.md" \
  test "$(grep -c . <<<"$sec_rows")" = 1
# shellcheck disable=SC2034 # lib.sh's absent reads $out
out="$tech_rows"$'\n'"$sec_rows"
absent "neither of the two prompts carries a Shard line" "Shard"
absent "and the manifest is named to neither of them" "manifest"

echo "# AGENT.md / ## 6. The fan-out: a cut of more than one Shard forks both reviewers per Shard"
kind_rows="$(sed -n '/^| Kind |/,/^$/p' <<<"$section")"
expect "the run kinds carry a sharded one, decided by the shards= line" \
  grep -qE '^\| sharded \|.*shards=' <<<"$kind_rows"
# A per-Shard fork is a row whose return file carries the Shard's number, so two Shards never
# return into one file and neither returns into the unsharded run's.
shard_tech_rows="$(grep -F '| `subagent_type: do-code-review-technical-reviewer`' <<<"$section" | grep -F '<that directory>/shard-<n>.technical.md')"
shard_sec_rows="$(grep -F '| `subagent_type: do-code-review-security-reviewer`' <<<"$section" | grep -F '<that directory>/shard-<n>.security.md')"
expect "each Shard forks one technical reviewer, returning into its own shard-<n>.technical.md" \
  test "$(grep -c . <<<"$shard_tech_rows")" = 1
expect "each Shard forks one security reviewer, returning into its own shard-<n>.security.md" \
  test "$(grep -c . <<<"$shard_sec_rows")" = 1
before "within a Shard the technical reviewer comes before the security reviewer" \
  "/shard-<n>.technical.md" "/shard-<n>.security.md"

echo "# the per-Shard fan-out is the cut's answer, whoever called the review"
# shellcheck disable=SC2034 # lib.sh's check_absent reads $out
out="$(flat_section "$agent" "## The arguments")"
expect "AGENT.md carries its arguments" test -n "$out"
check_absent "no argument of the review carries a Shard count" 0 0 "Shard" "shard"
# shellcheck disable=SC2034
out="$(passage_of "$here/../../do/references/mechanics.md" "### What the call carries" "##")"
expect "do's mechanics carry the review call" test -n "$out"
check_absent "do passes no Shard count on its review call" 0 0 "Shard" "shard"

tech="$here/../agents/do-code-review-technical-reviewer.md"
sec="$here/../agents/do-code-review-security-reviewer.md"
# The command that shows one file's changed lines; the contract spells the fixed point either way.
one_file_diff='git diff <fixed[ _]point> -- <path>'

echo "# AGENT.md / ## 5. The brief: a sharded run's brief names the reviewer's Shard and the manifest"
brief_lines="$(blocks_of "$agent" "## 5. The brief")"
expect "AGENT.md carries the brief's lines" test -n "$brief_lines"
# The count and the size are the Shard's own shard= line of the cut, so a reviewer can tell a
# listing that came up short from its whole Shard.
expect "the brief has a Shard: line: which Shard of how many, its files and its tokens" \
  grep -qE '^Shard: <n> of <N>, <files> files, <tokens> tokens' <<<"$brief_lines"
expect "the brief has a Shard manifest: line, the path of the cut" \
  grep -qE '^Shard manifest: <' <<<"$brief_lines"

echo "# the reviewers' own briefs: each one is told what the two lines are for"
flat="$(flat_section "$tech" "## The brief")"
expect "the technical reviewer's brief lists the lines it receives" test -n "$flat"
carries "its brief carries a row for the Shard line" "| \`Shard:\` |"
carries "its brief carries a row for the manifest line" "| \`Shard manifest:\` |"
flat="$(flat_section "$sec" "## The brief")"
expect "the security reviewer's brief lists the lines it receives" test -n "$flat"
carries "its brief carries a row for the Shard line" "| \`Shard:\` |"
carries "its brief carries a row for the manifest line" "| \`Shard manifest:\` |"

echo "# the technical reviewer / ## Reading: its Shard's files come off the manifest, each read whole"
flat="$(flat_section "$tech" "## Reading")"
expect "the technical reviewer lists what it opens" test -n "$flat"
carries "it lists its own files off the manifest's file lines" "grep '^file shard=<n> '"
expect "it reads every changed line of each, one file's diff at a time" \
  grep -qE -- "$one_file_diff" <<<"$flat"

echo "# the security reviewer: the surface is mapped off the manifest, its Shard's lines are read whole"
flat="$(flat_section "$sec" "## The attack surface")"
expect "the security reviewer says how it maps the attack surface" test -n "$flat"
carries "it finds its own files on the manifest's file lines" "grep '^file shard=<n> '"
flat="$(tr '\n' ' ' <"$sec" | tr -s ' ')"
expect "it reads every changed line of each, one file's diff at a time" \
  grep -qE -- "$one_file_diff" <<<"$flat"

echo "# AGENT.md / ## 6. The fan-out: every Shard's reviewers are waited for together, and only the missing ones again"
flat="$(flat_section "$agent" "## 6. The fan-out")"
# A call ends at the backtick that closes it, inline or as the fence of its block.
wait_calls() { grep -oE 'returns\.sh 240[^`]*' <<<"$flat"; } # the wait script's calls in $flat, one per line with their arguments, on stdout
expect "the unsharded run still waits on its two return files" \
  grep -qF 'returns.sh 240 <technical.md> <security.md>' <<<"$(wait_calls)"
# One call over the whole Row set: a wait naming two files comes back while the other Shards'
# reviewers are still out, and the run ends early or forks again a reviewer that already returned.
sharded_wait="$(wait_calls | grep -F 'shard-1.technical.md' | grep -F 'shard-1.security.md' | grep -F 'shard-<N>.security.md')"
expect "a sharded run waits on every Shard's return files in one call, shard-1 through shard-<N>" \
  test -n "$sharded_wait"
carries "the retry is decided by the wait's missing= lines" "missing="
carries "the ceiling of the whole wait stays 1440 s, whatever the Shard count" "1440"

exit $((fails > 0))
