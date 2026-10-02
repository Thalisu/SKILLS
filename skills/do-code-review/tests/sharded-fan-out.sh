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

# The Spec Axis is answered over the whole diff or not at all: a Row per Shard answers it N times
# from N partial views, and no Row leaves it unanswered. Being a Row of the sharded set is what
# puts the fork in the one message every Row is forked in, and its file in the one wait.
echo "# AGENT.md / ## 6. The fan-out: a sharded run forks one Spec reviewer over the whole diff, as the last Row of the set"
spec_rows="$(grep -F '| `subagent_type: do-code-review-spec-reviewer`' <<<"$section")"
expect "exactly one Spec reviewer is forked, whatever the Shard count" \
  test "$(grep -c . <<<"$spec_rows")" = 1
sharded_table="$(awk '
  /^\| / { block = block $0 "\n"; next }
  { if (index(block, "/shard-<n>.technical.md")) printf "%s", block; block = "" }
  END { if (index(block, "/shard-<n>.technical.md")) printf "%s", block }' <<<"$section")"
expect "it is the last Row of the sharded Row set" \
  test "$(tail -n 1 <<<"$sharded_table")" = "$spec_rows"
expect "and it comes right after the security Row" \
  test "$(tail -n 2 <<<"$sharded_table" | head -n 1)" = "$shard_sec_rows"
spec_return="$(awk -F'|' '{ print $4 }' <<<"$spec_rows")"
expect "it returns into spec.md, a file of no Shard" \
  test "$(tr -d ' ' <<<"$spec_return")" = '`<thatdirectory>/spec.md`'
# shellcheck disable=SC2034 # lib.sh's check reads $out
out="$(awk -F'|' '{ print $3 }' <<<"$spec_rows")"
check "its brief carries the manifest's path, the Loss ledger and its return file" 0 0 \
  '`Shard manifest:`' '`Loss ledger:`' '`Return file:`'
spec_brief_has_no_shard_line() { test -n "$out" && ! grep -qE '`Shard:`|`Shard` lines' <<<"$out"; } # the Spec Row's prompt cell in $out names no Shard: line
expect "its brief carries no Shard: line, since the Row has no Shard of its own" \
  spec_brief_has_no_shard_line
expect "the one sharded wait ends in the Spec reviewer's return file, after the last Shard's" \
  grep -qE 'shard-<N>\.security\.md <that directory>/spec\.md *$' <<<"$sharded_wait"

# The Row above forks a definition, and that definition is what keeps the one reviewer inside its
# window: it has no Shard of its own, so it starts from the Spec and reaches the code a path at a
# time, and it answers the one Axis the per-Shard reviewers cannot.
spec="$here/../agents/do-code-review-spec-reviewer.md"
lacks() { test -n "$flat" && ! grep -qF -- "$1" <<<"$flat"; } # $1 a fixed string the section in $flat, which must not be empty, does not carry

echo "# the Spec reviewer / ## The brief: it is handed the Spec, the manifest and the ledger, and no Shard"
flat="$(flat_section "$spec" "## The brief")"
expect "the Spec reviewer's brief lists the lines it receives" test -n "$flat"
carries "its brief carries a row for the Spec source line" "| \`Spec source:\` |"
carries "its brief carries a row for the manifest line" "| \`Shard manifest:\` |"
carries "its brief carries a row for the ledger line" "| \`Loss ledger:\` |"
carries "its brief carries a row for its return file" "| \`Return file:\` |"
expect "its brief carries no row for a Shard line, since it has no Shard of its own" \
  lacks "| \`Shard:\` |"
expect "its brief carries no row for the standards sources, an Axis it does not answer" \
  lacks "| \`Standards sources:\` |"

echo "# the Spec reviewer / ## Reading: the code is reached through the manifest, one path's diff at a time"
flat="$(flat_section "$spec" "## Reading")"
expect "the Spec reviewer lists what it opens" test -n "$flat"
carries "it reads the manifest the brief names" "Shard manifest"
carries_any "it finds the changed paths on the manifest's file lines" \
  "\`file\` line" "'^file " "\`file shard="
expect "it reads a path's changed lines one file's diff at a time" \
  grep -qE -- "$one_file_diff" <<<"$flat"

echo "# the Spec reviewer / ## The Axis: Spec is the one Axis it answers"
flat="$(flat_section "$spec" "## The Axis")"
expect "the Spec reviewer names the Axis it answers" grep -qF -- "Spec" <<<"$flat"

echo "# the Spec reviewer / ## The return: one Axis line, Spec, in the forms the Review's own Spec line takes"
spec_return="$(blocks_of "$spec" "## The return")"
expect "the Spec reviewer's return has its fenced form" test -n "$spec_return"
axis_lines="$(grep -E '^- (Correctness|Spec|Standards|Principles|Blast radius|Security): ' <<<"$spec_return")"
expect "the return carries exactly one Axis line" test "$(grep -c . <<<"$axis_lines")" = 1
expect "and that line is the Spec Axis's, under ## Axes" \
  grep -qE '^- Spec: ' <<<"$(sed -n '/^## Axes$/,$p' <<<"$spec_return")"
spec_line="$(grep -E '^- Spec: ' <<<"$axis_lines")"
expect "the Spec line keeps the no spec form" grep -qF -- "no spec" <<<"$spec_line"
expect "the Spec line keeps the Loss ledger: clause" grep -qF -- "Loss ledger:" <<<"$spec_line"
expect "every Finding heading of the return is a Spec Finding's" \
  test "$(grep '^### ' <<<"$spec_return" | sort -u)" = '### <n>. Spec at <location>'
expect "the return ends in its Safe because: line" \
  grep -qE '^Safe because: ' <<<"$(grep . <<<"$spec_return" | tail -n 1)"

format="$here/../../../.agents/formats/review-format.md"

echo "# AGENT.md / ## 7. The Review, in one write: every Shard's Findings go into the one Review, numbered once"
review_section="$(passage_of "$agent" "## 7. The Review, in one write" "## 8.")"
expect "AGENT.md carries the Review's write" test -n "$review_section"
# Numbering that restarts per Shard gives the Fixers two Findings under one number, so the merge is
# read where it speaks of Shards: the paragraphs naming one, and nothing the unsharded run says.
flat="$(paragraph_with /dev/stdin "Shard" all <<<"$review_section" | tr '\n' ' ')"
expect "the write says what a sharded run puts together" test -n "$flat"
carries "the returns of a sharded run are taken in Row order" "Row"
carries_any "and their Findings are numbered once across the Shards" \
  "from 1" "numbered once" "one numbering" "a single numbering"

echo "# AGENT.md / ## 7. The Review, in one write: a location both reviewers of a Shard reported appears once, as the security reviewer's"
# Two Findings left at one location fork two Fixers on it. `location` is the format's own term for
# what appears once, so the rule is found by it, apart for each kind of run.
flat="$(paragraph_with /dev/stdin "location" all <<<"$review_section" | grep -vF "Shard" | tr '\n' ' ')"
expect "the unsharded run's write still says what happens at a location reported twice" test -n "$flat"
carries "and still decides it between the security reviewer and the technical one" "security" "technical"
flat="$(paragraph_with /dev/stdin "Shard" all <<<"$review_section" | grep -F "location" | tr '\n' ' ')"
expect "the sharded run's write says what happens at a location reported twice" test -n "$flat"
carries "and decides it between a Shard's security reviewer and its technical one" "security" "technical"

echo "# review-format.md: the one numbering holds across Shards, over the four Buckets in their order"
flat="$(flat_section "$format" "## Rules")"
expect "the format carries its rules" test -n "$flat"
carries "a rule covers the Review of a sharded run" "Shard"
flat="$(flat_section "$format" "## Findings, by Bucket")"
expect "the format carries its Buckets" test -n "$flat"
before "Act on comes before Consider" '`## Act on`' '`## Consider`'
before "Consider comes before Noted" '`## Consider`' '`## Noted`'
before "Noted comes before Cleared" '`## Noted`' '`## Cleared`'
carries "every Finding is numbered within the file, from 1" "numbered within the file, from 1"

# A Shard whose reviewer failed twice holds files nobody judged on that reviewer's Axes. A line
# reading `0 findings` there, or no Review at all, hides them, so the Axis line, the safety line and
# the line `do` relays each name the Shard. The forms are the ones a reader and `do` parse.
echo "# review-format.md / ## Axes: an Axis a Shard's reviewer never ran names that Shard, beside what the other Shards found"
flat="$(flat_section "$format" "## Axes")"
expect "the format carries its Axis lines" test -n "$flat"
carries "the section still gives one line per Axis, all six" "One line per Axis, all six"
carries "an Axis not run on a Shard names the Shard and the reason" 'not run on Shard <n> (<reason>)'
carries "and the same line keeps the count over the Shards that returned" '<k> of <N> Shards returned'

echo "# review-format.md / ## Safe because: the safety line names the Axes no reviewer ran on a Shard"
flat="$(flat_section "$format" "## Safe because")"
expect "the format carries its safety line" test -n "$flat"
carries "the line names the Shard and the Axes not run on it" 'Not run on Shard <n>:'

echo "# AGENT.md / ## 6 and ## 7: a Row that failed twice leaves its Axes not run, and the Review is still written"
written="$(passage_of "$agent" "## 6. The fan-out" "## 8.")"
flat="$({
  paragraph_with /dev/stdin "Shard" all <<<"$written"
  paragraph_with /dev/stdin "sharded" all <<<"$written"
} | grep -F "failed twice" | tr '\n' ' ')"
expect "the sharded run says what a Row that failed twice leaves in the Review" test -n "$flat"
carries "its Axes read not run, never a count" "not run"

echo "# AGENT.md / ## 9. The return: the line do relays names the Shard an Axis did not run on"
return_lines="$(blocks_of "$agent" "## 9. The return")"
expect "AGENT.md carries the return's lines" test -n "$return_lines"
expect "an unsharded run keeps its Axis not run: line" \
  grep -qxF 'Axis not run: <Axis>, <the reason>' <<<"$return_lines"
expect "a sharded run's line keeps that prefix and names the Shard and the reason" \
  grep -qE '^Axis not run: <Axis>, Shard <n> \(<reason>\)' <<<"$return_lines"

# A sharded Review's Axis line keeps a count beside its `not run on Shard <n>`, so a definition that
# only says "every Axis ran" lets a reader take that line for an Axis that ran and land the branch
# with a Shard unread. The two tokens are the ones the Review itself carries.
echo "# fix.md / ## The landing: a Review with an Axis not run on a Shard is not Green"
fix="$here/../references/fix.md"
flat="$(passage_of "$fix" "## The landing" "## " | paragraph_with /dev/stdin "Green")"
expect "fix.md defines Green" test -n "$flat"
carries "Green keeps its conditions: every Act on Finding fixed and verified, the Gate green" \
  '`fixed`' '`verified`' "Gate"
carries "Green reads every Axis ran off the Review: no line of ## Axes carries not run" \
  "## Axes" "not run"

exit $((fails > 0))
