#!/usr/bin/env bash
# fixed-load.sh: the cuts to the fixed context load a `do` run pays before its first behaviour,
# asserted against the contract files on disk so a reviewer can rerun them: the door forks a reader
# over the Ticket's Spec and its Journey, the Digest that comes back is quoted, located and keyed by
# the Ticket's slug, the ground step takes a map and reads no source, and the shape step forks
# `sketch` and holds the build to the Sketch it files; and the estimator of that load, run against a
# scaffolded fixture, prints it by term, projects a Ticket's peak and gates nothing.
# Run: bash skills/do/tests/fixed-load.sh
# shellcheck disable=SC2016
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
repo="$(cd "$here/../../.." && pwd -P)"
refs="$repo/skills/do/references"
emdash=$'\xe2\x80\x94'
fails=0

header_has() { # $1 a fixed string that must appear in this script's own header comment
  sed -n '1,8p' "$here/fixed-load.sh" | grep -qF -- "$1"
}
after() { # $1 label, $2 file, $3 the later fixed string, $4.. the strings that must precede it
  local label="$1" file="$2" later="$3"
  shift 3
  local ok=1 lateline earlyline probe
  lateline="$(grep -n -F -m1 -- "$later" "$file" 2>/dev/null | cut -d: -f1)"
  [ -n "$lateline" ] || ok=0
  for probe in "$@"; do
    earlyline="$(grep -n -F -m1 -- "$probe" "$file" 2>/dev/null | cut -d: -f1)"
    if [ "$ok" != 1 ] || [ -z "$earlyline" ] || [ "$earlyline" -ge "$lateline" ]; then ok=0; fi
  done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else
    echo "FAIL  $label ($file)"
    fails=$((fails + 1))
  fi
}

# para_has must find a string still whole in the paragraph's prose even when the paragraph's own
# line-wrapping splits it across two lines: a paragraph is one unit of text, and reflowing it
# changes no word the pin is checking for.
para_has_selftest="$(mktemp)"
printf 'Preface paragraph, unrelated.\n\nThe body opens here and then it wraps this needle\nphrase across two lines to prove the join.\n\nTrailer paragraph, unrelated.\n' \
  >"$para_has_selftest"
para_has "para_has finds a string that wraps across a line break in the paragraph" \
  "$para_has_selftest" "The body opens here" \
  "wraps this needle phrase across two lines"
rm -f "$para_has_selftest"

# The door forks the reader, and the session opens neither document. Both files carry it: the
# Playbook's door is where the fork happens, the shared mechanics is where the mechanic lives.
has "the Playbook's door forks a reader over the Spec and the Journey" "$refs/ticket.md" \
  "the run forks the reader" \
  "opens neither itself"
has "the shared mechanics carry the reader as a mechanic of its own" "$refs/mechanics.md" \
  "## The reader"
# The section opens on the rule and its one exception, so a session reading it from the top never
# meets "never by the session" before the branches that have it read both documents.
para_has "the reader section opens by naming the no-reader branches as the exception" \
  "$refs/mechanics.md" "The Ticket's Spec and its journey are read by a fork" \
  "except on the two branches below where no reader can be forked" \
  "The session opens neither document"
# The fork returns text and a line, and the session writes that text to the file the later steps
# read: without the file the list at step 4 has nothing but the restatement to trace to.
has "the session writes the Digest whole, the door's hashes as its Sources" "$refs/mechanics.md" \
  "The session writes the Digest itself, whole" \
  'its `## Sources` lines from the door'"'"'s own hashes' \
  "read its quotes there"
has "the Playbook's door writes the Digest from the text that comes back" "$refs/ticket.md" \
  "the session writes the Digest from the text that comes back"
has "the Sources lines are the door's, never the reader's" "$refs/digest.md" \
  "the session writes them from the door's own hashes"
# A return steered to look like a failure, or one merely missing a section, must never be written
# through: the reuse gate would then serve it on every later run since its recorded hashes still
# match. A section that says its heading or its document is absent still counts as present.
has "a return missing a required section stops the door before anything is written" \
  "$refs/mechanics.md" \
  "The session checks what comes back before it writes" \
  "## Journey Path" "## Stories" "## Testing Decisions" "## Observable criteria" \
  "stops the door in one line naming what is missing" \
  "No Digest is written, the Ticket is left as the" \
  "door found it, and the next run forks the reader again"
# A `## Sources` section is a value the door alone computes, never a quote, so a `## Sources`
# section a stranger's text steered the reader into returning must never reach the write: the
# reuse gate would then have two pairs of hashes to choose from.
has "a Sources section in the reader's return is dropped before the write, and the run says so" \
  "$refs/mechanics.md" \
  'A `## Sources` section in the text the reader returned is' \
  "dropped before the write" \
  "the run says so in one line, so the written Digest carries exactly one \`## Sources\`" \
  "section, the door's own"
has "the session never falls back to reading the Spec and journey itself on a reader failure" \
  "$refs/mechanics.md" \
  "The session never reads the Spec or the" \
  "journey itself on a reader failure"
# The Digest the fork's text becomes is written into the developer's checkout, so the fork comes
# after the stops that refuse the run: a Ticket refused at the door leaves `git status` as it was.
after "the door reaches the reader only after the stops that refuse the run" "$refs/ticket.md" \
  "the run forks the reader" \
  'A Ticket that is `resolved` stops the run' \
  'A Ticket whose `Blocked by` names one not `resolved`' \
  "an issue assigned to someone else stops the run"
has "the door says a refused run leaves the main checkout as it found it" "$refs/ticket.md" \
  "The first write comes after those stops"
# The Playbook's door is where a run meets the fork, so it names the two branches that never reach
# it rather than saying the run opens neither document on every branch.
para_has "the Playbook's door names both no-reader branches and forks no other agent" "$refs/ticket.md" \
  "The first write comes after those stops" \
  'the Agent tool withheld or no `do-reader` listed' \
  "the door still hashes both documents" \
  "the session reads both itself" \
  "never forks another agent in the reader's place"
expect "the Digest reference the door links exists" test -f "$refs/digest.md"
has "SKILL.md lists the Digest reference under Links, so the door can read it" \
  "$repo/skills/do/SKILL.md" "[digest.md](references/digest.md)"
# The reader writes nothing; the session writes the Digest from the reader's text and the door's
# hashes, so the index line naming the writer must never fall back to the reader's old contract.
lacks "the index line no longer names the door's reader as the writer" \
  "$repo/skills/do/SKILL.md" "the door's reader writes"

# One brief, in the reference the fork is pointed at. A second enumeration in the mechanics drifts
# from it, and the fork is briefed from whichever copy the run happened to read.
has "the shared mechanics point at the brief instead of re-listing it" "$refs/mechanics.md" \
  "never a second one here"
lacks "the shared mechanics carry no second copy of the brief" "$refs/mechanics.md" \
  "its title and its criteria" \
  "the path the Digest is written to"
has "the brief carries the What to build line and the format the fork writes" "$refs/digest.md" \
  'its `What to build` line' \
  "the absolute path of this file"

# The reader is briefed over two whole documents whose text a stranger may have written, so it
# writes nothing and its brief hands it nothing to write with: no path, and no hash to record.
has "the brief leaves the reader nothing to write" "$refs/digest.md" \
  "The brief names no path to write and no hash to compute" \
  "it writes nothing"
lacks "the brief carries no Digest path and no one write" "$refs/digest.md" \
  "the path the Digest is written to" \
  "it writes one file"
has "the reader returns the Digest's text without its Sources, and the line the run restates" \
  "$refs/digest.md" 'the Digest'"'"'s text, every section but `## Sources`' "the one line the run restates"
# A reading across the window cannot tell who wrote a file, so another run's write in the scratch
# stopped this one although runs on two features share it; with no write tool there is nothing left
# for such a reading to catch.
has "nothing reads the tree or the scratch across the reader's window" "$refs/mechanics.md" \
  "Nothing reads the tree or the scratch across the reader's window"
lacks "the door takes no reading across the fork and stops on no other path" "$refs/mechanics.md" \
  'The door reads `git status --short` in the main checkout' \
  "git status --short --ignored -- .scratch/" \
  "the only one that may differ" \
  "Any other path stops the run in one line naming it"
# The reader is a second door into `do`, and only its description and the contract's row close it.
has "the invocation contract's row names the reader do ships and its one caller" \
  "$repo/.agents/invocation.md" "| \`do-reader\` | \`do\`, user-invoked |" \
  "skills/do/agents/do-reader.md" "\`do\`'s door is its only caller"
lacks "the invocation row no longer says the reader ships no definition" "$repo/.agents/invocation.md" \
  "It ships no definition of its own"
# The README's install table is column-aligned, so the pin allows any padding in the skill's cell.
expect "the README names the reader do ships among the agents the install links" \
  grep -qE "^\| \`do\` +\| \`do-reader\`," "$repo/README.md"
# The choice-taker is one more door into `do`, closed the same way as the reader's: its own row, read
# alone so a string the reader's row carries cannot stand in for it, and its name in the install row.
out="$(grep -E '^\| `choice-taker` +\|' "$repo/.agents/invocation.md")"
check "the invocation contract's row names the choice-taker do ships, its one door, its tools and the Ruling it returns" 0 $? \
  '`do`, user-invoked' \
  "\`Agent(subagent_type: choice-taker)\` from \`do\`'s ticket Playbook at its shape step, behaviours step or build step only" \
  "with the two sides" '`Read, Glob, Grep`' "writes nothing" "Ruling"
expect "the README names the choice-taker do ships among the agents the install links, after the reader" \
  grep -qE "^\| \`do\` +\| \`do-reader\`,[^|]*\`choice-taker\`" "$repo/README.md"

# The reader reads a stranger's text, so what bounds it is the tool list the harness enforces and
# never its brief: an agent `do` ships, forked by `do` alone, holding reading and search alone.
reader_md="$repo/skills/do/agents/do-reader.md"
has "the reader carries its frontmatter" "$reader_md" "name: do-reader" "model: sonnet"
expect "the reader's tools are exactly reading and search" \
  test "$(sed -n 's/^tools: //p' "$reader_md" 2>/dev/null)" = "Read, Glob, Grep"
lacks "the reader has no write tool, no edit tool and no shell" "$reader_md" "Write" "Edit" "Bash"
has "the reader names do's door as its one caller" "$reader_md" \
  "Forked only by the do skill's door" "Never on your own initiative"
has "the door forks the reader by name" "$refs/mechanics.md" "subagent_type: do-reader"
# The choice-taker rules a design fork the run meets at its shape, behaviours or build step, so like the reader it
# is an agent `do` ships, forked by `do` alone, bounded by a tool list that reads and never writes.
chooser_md="$repo/skills/do/agents/choice-taker.md"
front() { sed -n "s/^$1: //p" "$chooser_md" 2>/dev/null; } # $1 a frontmatter key: its value
has "the choice-taker carries its frontmatter" "$chooser_md" "name: choice-taker"
expect "the choice-taker runs on fable at high effort" \
  sh -c '[ "$1" = fable ] && [ "$2" = high ]' _ "$(front model)" "$(front effort)"
expect "the choice-taker's tools are exactly reading and search" test "$(front tools)" = "Read, Glob, Grep"
lacks "the choice-taker has no write tool, no edit tool and no shell" "$chooser_md" "Write" "Edit" "Bash"
has "the choice-taker names the ticket Playbook's shape, behaviours or build step as its one caller" "$chooser_md" \
  "Forked only by the do skill's ticket Playbook at its shape step, behaviours step or build step"
expect "the choice-taker's description ends on never on your own initiative" \
  sh -c 'case "$1" in *"Never on your own initiative." | *"Never on your own initiative.\"") ;; *) exit 1 ;; esac' \
  _ "$(front description)"
# A principle the choice-taker names as a norm is opened from the skills checkout it runs from, the
# way sketch's rivals step opens exhaust-the-design-space and boundary-discipline, never from
# `.agents/principles/` at the repository root the brief hands it: that folder exists only in this
# skills repo and never in a project `do` runs on.
has "the choice-taker resolves a principle norm from the skills checkout, not the repository root" \
  "$chooser_md" '$(readlink -f ~/.claude/skills/do)/../../.agents/principles/'
# A Design fork the run meets at its shape, behaviours or build step is ruled inside the run: the run names the
# fork and both its sides in one line and forks the choice-taker by name with them, where it once
# stopped naming `discuss`. The rule lives once in the Forks section, and each step that can meet a
# fork sends it there, so a pin on the file as a whole would pass on a rule stated in the wrong place.
span_has() { # $1 label, $2 file, $3 the span's opening line, $4 the next span's opening, $5.. fixed strings the span must carry, newlines flattened
  local label="$1" file="$2" open="$3" close="$4"
  shift 4
  local ok=1 body line
  body="$(awk -v a="$open" -v b="$close" 'index($0, a) == 1 { s = 1 } s && index($0, b) == 1 { exit } s' "$file" 2>/dev/null |
    tr '\n' ' ' | tr -s ' ')"
  [ -n "$body" ] || ok=0
  for line in "$@"; do [ "$ok" = 1 ] && grep -qF -- "$line" <<<"$body" || ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else
    echo "FAIL  $label ($file)"
    fails=$((fails + 1))
  fi
}
span_has "a Design fork is named with both sides in one line and ruled by the choice-taker forked by name" \
  "$refs/mechanics.md" "### Forks" "### Delegates" \
  "Design fork" "says in one line" "both sides" "subagent_type: choice-taker"
# A session whose Agent tool lists no choice-taker must not fall back to a general-purpose fork,
# which would read the Spec, on a remote tracker a stranger's text, while holding write tools
# (docs/adr/0032). The rule must say the choice-taker is never swapped for another agent, the same
# guarantee the reader's section already states for itself.
span_has "the Forks section states the choice-taker is never replaced by another agent" \
  "$refs/mechanics.md" "### Forks" "### Delegates" \
  "never replaced by another agent"
# The reader's section already states the same guarantee for the two branches where no agent can be
# forked: the Agent tool withheld from the session, or the Agent tool listing no agent by that name.
# The Forks section must state the same two branches for the choice-taker, stopping at its step the
# way every design fork stopped before ADR 0036 introduced the choice-taker, and naming
# `scripts/link-skills.sh` as the run that links the agent before the next `/do`, or a machine that
# has not re-linked `choice-taker` has no rule against forking a different agent in its place, one
# that could hold the write tools ADR 0032 denies it.
span_has "the Forks section states the two no-choice-taker branches, stops at its step naming discuss and cites link-skills.sh" \
  "$refs/mechanics.md" "### Forks" "### Delegates" \
  "the Agent tool is withheld from the session" \
  'the Agent tool lists no `choice-taker`' \
  "stops at its step" \
  'naming `discuss`' \
  "never forks another agent in the choice-taker's place" \
  "scripts/link-skills.sh"
# The Forks section briefs the choice-taker on where a principle norm is opened from, the skills
# checkout it runs from, the way sketch's rivals step opens exhaust-the-design-space and
# boundary-discipline, never `.agents/principles/` at the repository root the brief hands it.
span_has "the Forks section states a principle norm is opened from the skills checkout, not the repository root" \
  "$refs/mechanics.md" "### Forks" "### Delegates" \
  '$(readlink -f ~/.claude/skills/do)/../../.agents/principles/'
# The Forks section is where the rule lives, and three steps can meet a Design fork and send it
# there: the shape step, the behaviours step and the build step. A rule naming only two of the three
# leaves the third step's fork with no rule to follow, so the section, the choice-taker's own
# description and the invocation contract's row must each name all three, not just "shape or build".
span_has "the Forks section names the shape, behaviours and build steps as the three that send a Design fork to it" \
  "$refs/mechanics.md" "### Forks" "### Delegates" \
  "shape" "behaviours step" "build"
has "the choice-taker names the shape, behaviours and build steps as its callers" "$chooser_md" \
  "shape" "behaviours step" "build"
out="$(grep -E '^\| `choice-taker` +\|' "$repo/.agents/invocation.md")"
check "the invocation contract's row names the shape, behaviours and build steps as the choice-taker's callers" 0 $? \
  "shape" "behaviours step" "build"
expect "the Forks section no longer stops the run on every design fork" \
  sh -c '! printf %s "$1" | grep -qF "the Spec is incomplete: the run stops at its step"' _ "$(flat "$refs/mechanics.md")"
span_has "the shape step sends a Design fork it meets to the forks rule" "$refs/ticket.md" \
  "**3. Shape.**" "**4. Behaviours.**" "Design fork" "the forks in [mechanics.md](mechanics.md)"
span_has "the build step sends a Design fork it meets to the forks rule" "$refs/ticket.md" \
  "**5. Build loop.**" "**6. E2E flows.**" "Design fork" "the forks in [mechanics.md](mechanics.md)"
expect "the behaviours step no longer says a design fork found there stops the run" \
  sh -c '! printf %s "$1" | grep -qF "A design fork found here stops the run"' _ "$(flat "$refs/ticket.md")"
# A settled Ruling is the one edit a run makes to the Spec: a single line in its Implementation
# Decisions, marked as the choice-taker's, carrying the side, the norm and both sides of the fork, so a
# later reader sees what was ruled and on what ground. The two formats that forbid a ticket-side edit
# of the Spec each name that line as their one exception, or a run obeying them could never write it.
span_has "a settled Ruling appends one line to the Spec's Implementation Decisions in the choice-taker's shape" \
  "$refs/mechanics.md" "### Forks" "### Delegates" \
  "settled" "Implementation Decisions" \
  "- Ruled by the choice-taker on Ticket <the Ticket> at the <step> step: <the side taken>." \
  "Norm: <the principle, the ADR by title, the CONTEXT.md term or the Spec decision, or" \
  "no norm: the side easiest to undo" \
  "Fork: <side A> or <side B>."
# The append happens only on a local Spec file: a Spec that is an issue on a remote tracker is text
# anyone who can comment on it can steer, and a mid-run write with no developer yes would feed a
# stranger's edit straight into the Digest. The Forks section must confine the append to the local
# file and say the run writes nothing to the tracker on a remote Spec, keeping the Ruling in the run
# itself instead.
span_has "a settled Ruling is appended only when the Spec is a local file, and writes nothing to a remote tracker" \
  "$refs/mechanics.md" "### Forks" "### Delegates" \
  "only when the Spec is a local file" \
  "an issue on a remote tracker" \
  "writes nothing to the tracker" \
  "keeps the Ruling in the run itself"
span_has "the spec format's Implementation Decisions admits the line a choice-taker's Ruling appends" \
  "$repo/.agents/formats/spec-format.md" "## Implementation Decisions" "## Testing Decisions" \
  "choice-taker" "Ruling"
span_has "the ticket format names the choice-taker's Ruling as the one edit a ticket makes to its spec" \
  "$repo/.agents/formats/ticket-format.md" "## Spec" "## Status" \
  "choice-taker" "Ruling"
# A Ruling touches a Ticket criterion only when that criterion is the side that lost: its text becomes
# the side that won and its tick stays as it was, and no other criterion changes. The two places that
# today confine `do`'s writes to the Status line, the ticks and the Evidence each name that one more
# write, or a run obeying them could never make the rewrite.
span_has "only a criterion on the losing side of a settled Ruling is rewritten to the side that won, its tick kept" \
  "$refs/mechanics.md" "### Forks" "### Delegates" \
  "criterion" "losing side" "the side that won" "its tick" "every other criterion" "untouched"
span_has "the ticket format's list of do's writes names a criterion's text when a Ruling rewrote it" \
  "$repo/.agents/formats/ticket-format.md" "# Ticket format" "## Header" \
  "the ticks" '`## Evidence`' "a criterion's text" "Ruling"
span_has "the Ticket file section admits a criterion's text rewritten by a Ruling during the build" \
  "$refs/mechanics.md" "## The Ticket file" "## The reader" \
  "a criterion's text" "Ruling"
# A settled Ruling changed the Spec the Digest was cut from, so the run carries on rather than
# stopping: it names the Spec as changed, forks the reader again over both documents (a reader over
# the Spec alone would cut a Digest the journey no longer backs), rebuilds the behaviours list from
# the new Digest and resumes at its first behaviour, all in the same session and before any commit.
# The second-run rule is the one that re-forks on a moved hash, so it names this occasion beside the
# resume and the `/do` typed again, or a Ruling's re-fork would follow no rule at all.
span_has "a settled Ruling names the Spec as changed, re-forks the reader over the Spec and the journey and continues at the first behaviour without a commit" \
  "$refs/mechanics.md" "### Forks" "### Delegates" \
  "the Spec as changed" "forks the reader again" "the Spec and the journey" \
  "never over the Spec alone" "behaviours list" "Digest that comes back" \
  "the first behaviour" "without a commit" "same session"
para_has "the second-run rule covers the re-fork a Ruling triggers mid-run beside a resume and a /do typed again" \
  "$refs/mechanics.md" "A Digest already sits beside the Ticket" \
  "on a resume" "typed again on the same Ticket" "Ruling"
# Touching a risk class is not what stops a run: a Spec about security would stop on every fork. A
# fork whose two sides both keep the guarantee whole is ruled on like any other, and only an Extreme
# fork, one side weakening a guarantee in a risk class or landing what cannot be undone, still stops
# the run where it met it, handing the fork to `discuss` with the claim and the worktree kept.
span_has "a Design fork touching a risk class with both sides keeping the guarantee whole is ruled on and never stops the run" \
  "$refs/mechanics.md" "### Forks" "### Delegates" \
  "risk class" "guarantee whole" "never stops"
span_has "an Extreme fork, a side weakening a risk-class guarantee or not undoable once landed, has the choice-taker return extreme and stops the run naming discuss, Ticket claimed, worktree in place" \
  "$refs/mechanics.md" "### Forks" "### Delegates" \
  "Extreme fork" "security, privacy, data loss, auth, billing, migration, idempotency, race" \
  "cannot be undone once landed" '`extreme`' "stops at its step" \
  'one message naming `discuss`' 'the Ticket left `claimed`' "the worktree in place"
# A session whose Agent tool does not list `do-reader` has no agent by that name to fork, so the
# only fallback left open must never be a general-purpose fork holding write tools over the same
# brief: the session does the reading and the write itself, stated before the fork is even called.
para_has "an Agent tool that lists no do-reader has the session read and write, never fork another agent" \
  "$refs/mechanics.md" "No reader can be forked on two branches" \
  'the Agent tool lists no `do-reader`' \
  "never forks another agent in the reader's place"
after "the lists-no-do-reader fallback is stated before the door forks the reader by name" \
  "$refs/mechanics.md" "subagent_type: do-reader" \
  'the Agent tool lists no `do-reader`'
# The withheld tool and the unlinked reader are the same branch to the run, so one paragraph carries
# both: the line names which one holds, `do-reader` by name and the installer that links it when a
# machine never linked it, and the Digest the session writes keeps the door's hashes and the absent
# record a first run keeps. The withheld branch cites the Delegates rule without a fork that writes,
# since on this branch nothing is forked at all.
para_has "one paragraph carries both no-reader branches, the line naming do-reader when unlisted" \
  "$refs/mechanics.md" "No reader can be forked on two branches" \
  "the Agent tool is withheld from the session" \
  'the Agent tool lists no `do-reader`' \
  "the session reads both documents itself" \
  '`do-reader` not listed' \
  '`scripts/link-skills.sh` links before the next `/do`' \
  "the case the Delegates rule below covers, and as there the session does that work itself" \
  'its `## Sources` lines from the door'"'"'s own hashes' \
  'recorded `absent` and named in one line' \
  "neither stops nor asks for the tool" \
  "never forks another agent in the reader's place"
lacks "the withheld branch no longer sits in a paragraph of its own" "$refs/mechanics.md" \
  "When the Agent tool is withheld from the session there is no fork to dispatch."
# The door's hashing on those branches is said once, in the paragraph the window pin below reads, so
# the two can never drift apart.
lacks "the no-reader paragraph neither restates the hashing nor names a fork that writes" \
  "$refs/mechanics.md" \
  "hashed both documents as a first" \
  "where the fork writes nothing and"
# The `## Sources` lines are the record the reuse gate trusts, so they come from the door's own
# reading taken before the fork, never from the fork that read the stranger's text.
has "the door hashes both documents itself and records an absent one" "$refs/mechanics.md" \
  "hashes both itself before it forks" \
  'recording `absent` for a document not on disk'
after "the door hashes both documents before it forks the reader" "$refs/mechanics.md" \
  "subagent_type: do-reader" \
  "hashes both itself before it forks"
has "the Playbook's door hashes both documents before the fork" "$refs/ticket.md" \
  "hashes both itself before it forks"
# The hashes are the record the reuse gate trusts on every branch, forked or not, and a run that
# forks nothing never says the documents are being read in a window of their own.
para_has "the door hashes both documents on the no-reader branches and names the window only on a fork" \
  "$refs/mechanics.md" "Before anything is forked, the door resolves both paths" \
  "the same way when no reader can be forked" \
  "When it forks the reader, the door says in one line"
lacks "the window line is never said unconditionally" "$refs/mechanics.md" \
  "Then the door says in one line that both are being read"
has "the Sources hash is the door's, run in the main checkout before the fork" "$refs/digest.md" \
  'the hash from `git hash-object <path>` the door runs in the main checkout before it forks'

# The Digest quotes what the run builds from, and every quote is checkable at its line.
has "the Digest holds the Path, the numbered stories and the Testing Decisions" "$refs/digest.md" \
  "## Journey Path" "## Stories" "## Testing Decisions" "quoted, never summarised"
has "every quote carries its document, its heading and its line" "$refs/digest.md" \
  '`<document> · <heading> · L<line>`'

# The edges are a rule the developer can check, not a judgement only the fork saw.
has "the Digest's edges are the headings the two formats fix" "$refs/digest.md" \
  "never a line range only the reader saw" \
  '`## Path <n>: <title>`' \
  "journey-format.md" "spec-format.md"

# The Digest is keyed by the Ticket, and the run says where it is and what it says.
has "the Digest lives beside the Ticket, keyed by its slug, on an ignored path" "$refs/digest.md" \
  "## Where it lives" \
  'taking the Ticket'"'"'s file name with `.digest` before the extension' \
  'appends the `.scratch/` line before the write'
has "the run names the Digest's location and restates it in one line" "$refs/ticket.md" \
  "names the Digest's location and restates it in one line"

# The list is traceable to the quotes, which is what makes the Digest the spec of record.
has "every behaviour line traces to a quote and never to a paraphrase" "$refs/ticket.md" \
  "quoted Testing Decision" "a Journey step" "never to a paraphrase"

# A resume re-derives the list, so it must reach for the Digest and not for the Spec again.
has "the resume re-derives the list from the Digest, never from the Spec" "$refs/ticket.md" \
  "re-derived from the Ticket and its Digest"
# Only an Extreme fork still stops a run, so the Resume bullet that picks such a run up names that
# stop. The re-fork after it takes both documents: over the Spec alone the new Digest comes back with
# no Journey Path, and the resumed list is shorter than the first run's.
span_has "the Extreme fork resume re-forks the reader over the amended Spec and the journey both" \
  "$refs/ticket.md" "- A run that stopped on" "## Checklist" \
  "Extreme fork" '`discuss`' "amended Spec" "journey both, never over the Spec alone"
expect "the Resume bullet no longer speaks of a run stopped on a design fork" \
  sh -c '! printf %s "$1" | grep -qF "A run that stopped on a design fork"' _ "$(flat "$refs/ticket.md")"

# The script is rerunnable by a reviewer who has only the file, since the repo has no runner. The
# match is the header alone: the pattern is itself a line further down this script, so a whole-file
# grep stays green on a script whose header line was deleted.
expect "the test script carries its own invocation line in its header" \
  header_has "# Run: bash skills/do/tests/fixed-load.sh"

# The scratch contract's ignore rule has two halves: the append before the write, and one line at
# the close telling the developer a tracked file was changed. The door does the append.
has "the close says the run appended the .scratch/ line" "$refs/ticket.md" \
  'appended the `.scratch/` line to the project'"'"'s' \
  "the close says so in one line"

# The appended line is the one file the developer actually sees in `git status`, since the Digest
# itself lands on the ignored path, so the reply's list of what the run left has to name it.
has "Left uncommitted names the .gitignore line the run appended" "$refs/reply.md" \
  'the `.gitignore` line when the run appended it'

# The ground step reads the glossary and the ADRs the Ticket touches and never the code: which files
# the build edits is not knowable before the behaviours list, so any file read here may be paid for
# and never edited.
has "the ground step states the glossary words and reads the bodies of the ADRs it touches" \
  "$refs/ticket.md" "state the glossary words it will use" "the bodies of the ones the Ticket touches"
has "the ground step opens no source file" "$refs/ticket.md" "It opens no source file"
lacks "the ground step no longer reads the code the Ticket names" "$refs/ticket.md" \
  "the code the Ticket"
# The subsystem comes back as a map from `how`, whose own forks explore it, so the shape step can
# name the boundaries without the source in the session.
has "the ground step takes the subsystem as a map from how" "$refs/ticket.md" \
  'call the Skill tool with `how` over the subsystem the Ticket' "as the map" \
  "what calls what" "where the seams are"
has "the ground step names the skill it called and the subsystem in one line" "$refs/ticket.md" \
  "names in one line the skill it called"
has "the exploration stays in the window of the skill that made the map" "$refs/ticket.md" \
  "stays in that skill's window"
# With `how` not listed, a file read whole puts the run back on the load this step cuts, so the map
# comes from search output alone, is named as thinner, and the run goes on.
has "without how the map is built from search output alone and named as thinner" "$refs/ticket.md" \
  "from search output alone" "names, paths and one-line matches" "reads no file whole" \
  "names the map as thinner" "the run continues"
lacks "the fallback no longer explores with targeted reads" "$refs/ticket.md" \
  "explore with search and targeted reads"
fallback="$repo/skills/do/evals/absent-vendored-skill/graders/grounding-fallback-stated.md"
has "the absent-vendored-skill eval grades the map built from search output alone" "$fallback" \
  "search output alone" "thinner" "read no file whole"
lacks "the absent-vendored-skill eval no longer grades a read of the code the Ticket names" \
  "$fallback" "read the code the Ticket names"
# The source the ground step no longer reads is read by the loop, one file at a time, when the
# behaviour that edits it comes up: the session then holds only source the run changed.
has "the build loop reads each file at the moment it edits it and names it as it opens it" \
  "$refs/mechanics.md" "read at the moment the loop edits it" "named in the thread as the loop opens it" \
  "the only source the loop brings into the session is source the run changed"
# The map replaces the code read, so the discover batch takes its symbols from the map, and the
# reading still sharpens done before the grounded figure is taken for the close.
has "the discover batch covers every symbol the Ticket, the Digest and the map name" \
  "$refs/ticket.md" "every symbol the Ticket, its Digest and the map"
lacks "the discover batch no longer names a reading of the code" "$refs/ticket.md" \
  "its Digest and the reading"
after "done is restated as a predicate after the audit line and before the context reading" \
  "$refs/ticket.md" '<skill-dir>/scripts/context-usage.sh`, and keep its `current` figure' \
  "log the audit line" "Restate done as a predicate"

# The shape step takes the shape from `sketch`, forked with a brief filled from what the run already
# holds, so the rivals behind a shape never enter the session and nothing is grounded a second time.
has "the checklist's shape step names sketch" "$refs/ticket.md" \
  '3. Shape named; `sketch` forked when a boundary is crossed'
has "the shape step forks sketch through the Agent tool" "$refs/ticket.md" \
  'call the Agent tool with `subagent_type: sketch`'
lacks "the ticket Playbook's shape step no longer calls architect" "$refs/ticket.md" \
  'call the Skill tool with `architect`' "architect sketch"
has "the brief hands sketch what the run holds, so nothing is grounded a second time" \
  "$refs/ticket.md" "so nothing is grounded a second time" "the Digest's location" \
  "the repository root" "where the Sketch goes"
has "the run names in one line what it handed sketch" "$refs/ticket.md" \
  "names in one line what it handed over"
has "a session that lists no sketch states the shape in the thread and says so" "$refs/ticket.md" \
  'a session whose Agent tool lists no `sketch`' "stated in the thread, the step says so in one line"
# The Sketch is a file the build is held to, so the run names where it is and what it says, and a
# shape that keeps failing the build is caught as a pattern rather than absorbed one case at a time.
has "the run names the Sketch's location and the shape in one line" "$refs/ticket.md" \
  "names the Sketch's location and the shape in one line"
has "the build is held to the Sketch, and every test still goes through a test author" \
  "$refs/ticket.md" "The build is held to the Sketch" "every test still goes through a test author"
has "a second deviation of the same shape stops the run as a wrong Sketch, naming discuss" \
  "$refs/ticket.md" "stops the run as a wrong Sketch" "the message naming \`discuss\`"
lacks "the contract is the Sketch file, never a lowercase sketch in the thread" "$refs/ticket.md" \
  "as a wrong sketch" "implements the sketch under the loop" "A symbol the sketch adds"
# A shape in hand from the Ticket, its Digest or a prototype, and a session that lists no `sketch`,
# file no Sketch, so a done condition that always wants its location leaves step 3 undone on them.
has "step 3 is done with the Sketch's location only when a Sketch was filed, or the skip" \
  "$refs/ticket.md" \
  "when the shape is in the thread, with the Sketch's location when a Sketch was filed, or the skip."
has "with no Sketch filed, the build and its deviations are held to the shape in hand" \
  "$refs/ticket.md" "The build is held to the Sketch, or to the shape in hand when no Sketch was filed" \
  "A deviation from that contract during the build"
# The step never names a shape twice. A resume runs the shape step again without a write, and the
# Sketch the first run filed is the shape it finds, so the fork is the table's last line.
has "a Sketch already beside the Ticket is a shape in hand, so a resume forks no second sketch" \
  "$refs/ticket.md" "a Sketch already beside the Ticket, which is what a resume finds"
has "no boundary crossed reads the skip and goes on to the behaviours list" "$refs/ticket.md" \
  '`skip: no boundary crossed`, and the run goes on to the behaviours list'
after "the skip and a shape in hand are read before the fork" "$refs/ticket.md" \
  'call the Agent tool with `subagent_type: sketch`' \
  '`skip: no boundary crossed`' "a Sketch already beside the Ticket"
# The withheld path of the new fork, in the wording the shared mechanics fix. The eval that grades it
# cannot run on this machine, so this is the path's only executable coverage.
has "with the Agent tool withheld, sketch writes nothing and the session does that work itself" \
  "$refs/ticket.md" "runs in a session with the Agent tool withheld" \
  '`sketch` writes nothing and says so, and the session does that work itself'
has "the shared mechanics still fix the wording the withheld row cites" "$refs/mechanics.md" \
  "When the Agent tool is withheld from it, it writes nothing" \
  "and says so, and the session does that work itself."
has "the session writes the Sketch in the shared format and says so in one line" "$refs/ticket.md" \
  "[sketch-format.md](../../../.agents/formats/sketch-format.md)" "writes the Sketch itself"
expect "the format the withheld row links resolves" test -f "$repo/.agents/formats/sketch-format.md"
after "the withheld row is read before the row for a session that lists no sketch" \
  "$refs/ticket.md" 'a session whose Agent tool lists no `sketch`' \
  "runs in a session with the Agent tool withheld"
grader="$repo/skills/do/evals/withheld-agent-tool/graders/no-sketch-fork-session-writes-sketch.md"
has "the withheld-agent-tool eval grades the session writing the Sketch itself" "$grader" \
  "type: llm" "01-archive-a-note.sketch.md" "no Agent tool call"
# The sketch agent returns the Sketch as text and the session files it, so the containment check,
# the ignore probe and the write are read in step 3 alone: the close step names `.gitignore` too.
shape_step="$(mktemp)"
awk '/^\*\*3\. Shape\.\*\*/ { on = 1 } /^\*\*4\. Behaviours\.\*\*/ { on = 0 } on' \
  "$refs/ticket.md" > "$shape_step" 2>/dev/null
lacks "what comes back from the sketch agent is no longer the Sketch's location" "$refs/ticket.md" \
  "What comes back is the Sketch's location"
has "the shape step checks with readlink -m that the destination stays under the root's .scratch" \
  "$shape_step" "readlink -m" 'case "$dest" in "<root>/.scratch/"*)'
has "the shape step probes the scratch ignore and appends the .scratch/ line to .gitignore when owed" \
  "$shape_step" "git check-ignore -v .scratch/" ".scratch/" ">> .gitignore"
has "the shape step writes the Sketch whole from the text the agent returns" "$shape_step" \
  "whole" "the text the agent return"
after "the containment check runs before the ignore probe appends anything" "$shape_step" \
  "git check-ignore -v .scratch/" "readlink -m"
after "the containment check and the ignore probe come before the Sketch is written" "$shape_step" \
  "the text the agent return" "readlink -m" "git check-ignore -v .scratch/"
# A destination outside the root's `.scratch` is never written and never handed to a fork: the
# check's `refused` answer ends the run before anything lands, and the stop line names what a
# developer needs to find the run again. Anchored on the answer the check prints, so the code block
# that echoes it cannot stand in for the prose that says what it does.
para_has "a refused destination writes nothing, forks no sketch, and stops naming the path, the worktree and its branch" \
  "$shape_step" '`refused`' \
  "writes nothing" 'forks no `sketch`' "stops" "in one line" "the refused path" \
  "the worktree and its branch"
# A refusal, an error or a return in a shape the Sketch format does not fix is no Sketch, and filing
# it would hold the build to it: the step reads the return against the format, writes nothing, and
# lands where a session that lists no `sketch` lands. Read from the containment check on, so the
# format link the withheld row carries cannot stand in for the one the return is checked against.
sketch_return="$(mktemp)"
awk '/readlink -m/ { on = 1 } on' "$shape_step" > "$sketch_return" 2>/dev/null
para_has "a return that is not a usable Sketch files none, and the shape is stated in the thread" \
  "$sketch_return" "[sketch-format.md](../../../.agents/formats/sketch-format.md)" \
  "writes no Sketch" \
  "the types, the signatures and the module boundaries" "stated in the thread" \
  "says so in one line" "the run continues"

# The estimator runs against a scaffolded skill and project whose files have known sizes, so every
# term it prints is a number this script can state: 4000 bytes is 1000 tokens.
estimator="$repo/skills/do/scripts/estimate-load.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp" "$shape_step" "$sketch_return"' EXIT
skill="$tmp/skills/do"
mkdir -p "$skill/scripts" "$skill/references" "$tmp/.agents/formats" "$tmp/docs/adr" "$tmp/t"
cp "$estimator" "$skill/scripts/" 2>/dev/null
mk() { head -c "$2" /dev/zero | tr '\0' a >"$1"; }
for f in "$skill/SKILL.md" "$skill/references/ticket.md" "$skill/references/mechanics.md" \
  "$skill/references/reply.md" "$skill/references/digest.md" "$tmp/.agents/formats/ticket-format.md"; do
  mk "$f" 4000
done
mk "$tmp/docs/adr/0001-x.md" 10
mk "$tmp/CONTEXT.md" 3990
est() { # runs the scaffolded estimator from the fixture's root; sets out, err and code
  out="$(cd "$tmp" && bash "$skill/scripts/estimate-load.sh" "$@" 2>"$tmp/t/err")"
  code=$?
  err="$(cat "$tmp/t/err")"
}
is() { [ "$1" = "$2" ]; }
out_has() { printf '%s\n' "$out" | grep -qxF -- "$1"; }
err_has() { printf '%s\n' "$err" | grep -qF -- "$1"; }

est
expect "with no argument the estimator exits zero" is "$code" 0
expect "with no argument it prints the fixed load by term, in order, then the total" is "$out" \
  "$(printf '%s\n' baseline=32000 reference_chain=5000 door=5000 ground=7500 shape=1000 total=50500)"
expect "the estimator carries its own invocation line in its header" \
  sh -c 'sed -n "1,12p" "$1" | grep -qF "estimate-load.sh <the Ticket'"'"'s path>"' _ "$estimator"

ticket() { # $1 path, $2 criteria: a Ticket in the format, padded to 4000 bytes
  {
    printf '# 01: A slice\n\n**What to build:** A slice.\n\n**Blocked by:** None\n\n'
    printf '**Status:** ready-for-agent\n\n'
    for _ in $(seq "$2"); do printf -- '- [ ] A criterion.\n'; done
    printf '\n## Evidence\n'
  } >"$1"
  local size
  size="$(wc -c <"$1")"
  head -c $((4000 - size - 1)) /dev/zero | tr '\0' a >>"$1"
  echo >>"$1"
}
fixed="$(printf '%s\n' baseline=32000 reference_chain=5000 door=5000 ground=7500 shape=1000 total=50500)"
ticket "$tmp/t/01-small.md" 2
est t/01-small.md
expect "given a Ticket the estimator exits zero" is "$code" 0
expect "given a Ticket it adds the criteria, the per-criterion term, the peak and the band" is "$out" \
  "$fixed"$'\n'"$(printf '%s\n' criteria=2 per_criterion=18000 peak=86500 band=small)"
ticket "$tmp/t/02-medium.md" 6
est t/02-medium.md
expect "a medium Ticket reads its band and exits zero" \
  sh -c '[ "$1" = 0 ] && printf "%s\n" "$2" | grep -qx "peak=158500" && printf "%s\n" "$2" | grep -qx "band=medium"' \
  _ "$code" "$out"
ticket "$tmp/t/03-large.md" 10
est t/03-large.md
expect "a large Ticket reads its band and still exits zero, since the estimate gates nothing" \
  sh -c '[ "$1" = 0 ] && printf "%s\n" "$2" | grep -qx "peak=230500" && printf "%s\n" "$2" | grep -qx "band=large"' \
  _ "$code" "$out"
# The Digest beside the Ticket is the one the door reads, so its size replaces the allowance.
ticket "$tmp/t/04-digested.md" 2
mk "$tmp/t/04-digested.digest.md" 4000
est t/04-digested.md
expect "a Digest beside the Ticket is counted in place of the allowance" \
  sh -c 'printf "%s\n" "$1" | grep -qx "door=3500" && printf "%s\n" "$1" | grep -qx "peak=85000"' _ "$out"
# The bands are the ones the measured Context: line is written in, so the two readings compare.
band_line='if [ "$peak" -lt 150000 ]; then band=small; elif [ "$peak" -le 200000 ]; then band=medium; else band=large; fi'
has "the estimator's band line is a verbatim copy of context-usage.sh's" "$estimator" "$band_line"
has "context-usage.sh still carries the band line the estimator copies" \
  "$repo/skills/do/scripts/context-usage.sh" "$band_line"

# A reading it cannot take names the term it could not read, prints no figure and exits non-zero.
refused() { # $1 the exit code, $2 the term the message must name
  [ "$code" = "$1" ] && [ -z "$out" ] && err_has "cannot read $2:"
}
printf '# Notes\n\n- [ ] Not a criterion of any Ticket.\n' >"$tmp/t/notes.md"
est t/notes.md
expect "a path that is not a Ticket names the criteria it could not read and exits 3" refused 3 criteria
est t/none.md
expect "a Ticket that is not on disk names the criteria and exits 3" refused 3 criteria
mv "$skill/references/mechanics.md" "$tmp/t/mechanics.md"
est
expect "a missing file of the reference chain names reference_chain and exits 3" \
  refused 3 reference_chain
mv "$tmp/t/mechanics.md" "$skill/references/mechanics.md"
mv "$skill/references/digest.md" "$tmp/t/digest.md"
est
expect "a missing Digest brief names the door and exits 3" refused 3 door
mv "$tmp/t/digest.md" "$skill/references/digest.md"
est t/01-small.md t/02-medium.md
expect "two arguments are a usage error and exit 2" \
  sh -c '[ "$1" = 2 ] && [ -z "$2" ] && printf "%s\n" "$3" | grep -qF "usage: estimate-load.sh"' \
  _ "$code" "$out" "$err"

# A project with several contexts keeps its glossary through CONTEXT-MAP.md, and the ground step reads
# the map and the one context it names that the plan touches. Which one is not knowable without the
# Ticket, so the largest named is counted, beside the map itself.
mv "$tmp/CONTEXT.md" "$tmp/t/CONTEXT.md"
mkdir -p "$tmp/ctx/a" "$tmp/ctx/b"
mk "$tmp/ctx/a/CONTEXT.md" 8000
mk "$tmp/ctx/b/CONTEXT.md" 4000
printf '# Context map\n\n## Contexts\n\n- [A](./ctx/a/CONTEXT.md): one\n- [B](./ctx/b/CONTEXT.md): two\n' \
  >"$tmp/CONTEXT-MAP.md"
map_size="$(wc -c <"$tmp/CONTEXT-MAP.md")"
head -c $((1990 - map_size - 1)) /dev/zero | tr '\0' a >>"$tmp/CONTEXT-MAP.md"
echo >>"$tmp/CONTEXT-MAP.md"
est
expect "with CONTEXT-MAP.md the ground term counts the map and the largest context it names" \
  sh -c '[ "$1" = 0 ] && printf "%s\n" "$2" | grep -qx "ground=9000"' _ "$code" "$out"
mv "$tmp/ctx/a/CONTEXT.md" "$tmp/t/ctx-a.md"
est
expect "a context the map names that is not on disk names ground and exits 3" refused 3 ground
mv "$tmp/t/ctx-a.md" "$tmp/ctx/a/CONTEXT.md"
printf '# Context map\n' >"$tmp/CONTEXT-MAP.md"
est
expect "a map that names no context names ground and exits 3" refused 3 ground
rm -r "$tmp/CONTEXT-MAP.md" "$tmp/ctx"
mv "$tmp/t/CONTEXT.md" "$tmp/CONTEXT.md"

# The estimate gates nothing: no skill, no vendored skill and no contract names it, so a Ticket it
# calls small still runs whatever it turns out to cost.
unread() { ! grep -rlF --exclude=estimate-load.sh --exclude=fixed-load.sh -- estimate-load.sh \
  "$repo/skills" "$repo/vendor" "$repo/.agents"; }
expect "no skill or contract reads the estimator" unread
# The measured line stays the ground truth that corrects the next estimate, so the run keeps writing it.
has "the close still writes the Context: line first under the evidence" "$refs/ticket.md" \
  '`Context:` line first'
has "the shared mechanics still write the Context: line with resolved" "$refs/mechanics.md" \
  'line the format defines as the first line under `## Evidence`'
has "the Ticket format still defines the measured Context: line" \
  "$repo/.agents/formats/ticket-format.md" '`Context: grounded <tokens>, peak'

# No em-dash in the prose this feature writes, per CLAUDE.md.
lacks "no em-dash in the Digest reference" "$refs/digest.md" "$emdash"
lacks "no em-dash in the estimator" "$estimator" "$emdash"

if [ "$fails" = 0 ]; then echo "PASS"; else
  echo "$fails failing"
  exit 1
fi
