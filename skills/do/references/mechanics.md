# Shared mechanics

One file for the parts the Playbooks that build in a worktree share, read by `ticket`, `bug-fix`
and `refactoring`, so a fix to a mechanic is made once. It carries the worktree, the protected
branch, the Ticket file, the reader, the build loop with its test authors, the gate, the review,
the verification and the close. A Playbook links the section it needs and never copies it.

## The worktree

Every build runs in a git worktree the run creates itself from the current HEAD, never through a
tool that branches from the remote default branch.

1. Prove the run starts in the main checkout before anything is created:
   `git rev-parse --show-toplevel` and the first entry of the worktree list, the derivation
   [worktrees.md](../../../.agents/worktrees.md) carries, are the same path. Two paths mean the
   session sits in a linked worktree, which the harness's worktree tool is the likely reason for,
   and the run builds nothing from there: it leaves the isolation the way that file says, or moves
   to the main checkout with a bare `cd` when nothing isolated it, and starts this step over.
   Then, there, read the branch and `git status --short`. The dirty files are the developer's work
   in progress: nothing in the run edits, stages or reverts them, and the worktree starts from
   HEAD without them.
2. Create it from the main checkout: `git worktree add .claude/worktrees/do-<slug> -b do/<slug>`,
   where `<slug>` is the Ticket's slug, or the request's outside the chain. `.claude/worktrees/`
   is the harness's worktrees folder: the run's worktrees sit beside the harness's own, one
   exclude line covers them all, and a resume knows where to look.
3. Keep the main checkout's status as the developer left it: when
   `git check-ignore -q .claude/worktrees` fails, append `.claude/worktrees/` to
   `.git/info/exclude`. Never to the project's `.gitignore`: the ignore file is the project's,
   the exclude list is this clone's.
4. Enter it with `cd <path>`, in a shell call of its own, per
   [worktrees.md](../../../.agents/worktrees.md): the harness keeps the working directory across
   calls, so every command from here runs in the worktree, and git reaches the main checkout with
   `git -C <its path>` when a step needs it. Never the harness's worktree tool: it isolates the
   session, and an isolated session refuses git against the main checkout, which the Ticket, the
   landing, the flows and the worktree's removal all need. The skill file denies that tool, so the
   run meets it as a refusal rather than as a rule to remember.
5. Done when one call in the worktree prints the main checkout's top level, the branch and an empty
   status, on one line:
   `git -C <main checkout> rev-parse --show-toplevel && git branch --show-current && git status --short`.
   The first of the three is the probe, and it is the backstop for step 1: a session that was
   already isolated when the run started refuses this call, for the redirect or for the shape, and
   that refusal is the state and not the command. The run has by then created a worktree from the
   isolated tree and not from the developer's HEAD, so it leaves the isolation the way
   [worktrees.md](../../../.agents/worktrees.md) says, removes the worktree and the branch it made
   there, and starts this section over from step 1. Catching that state at step 1 costs nothing;
   catching it here costs one worktree; catching it at the landing costs the build.

The worktree stays until the run's work has landed and its affected flows are green. The run
removes it and its branch itself, from the main checkout; a run that stops as blocked leaves both
in place and names them in the reply. One writer at a time in the worktree, per
[separate-before-serializing-shared-state](../../../.agents/principles/separate-before-serializing-shared-state.md):
the session, or the test author it dispatched while that author runs.

## The protected branch

The rule is the one `test-triage` uses: `main` or `master` is protected when `develop`,
`development`, `staging` or `release*` exists locally or on a remote; `production` or `prod` is
protected when any of those or `main` or `master` exists; a default branch that is the only
branch is the working branch. Nothing lands on a protected branch. A Playbook checks the
developer's branch against it before the work starts and records the warning for the Reply's Run
section, per [reply.md](reply.md). The warning guards nothing: the review refuses the landing on a
protected branch whatever the run wrote, so a warning the developer never read cannot let the work
land where the rule forbids it.

## The Ticket file

The Ticket belongs to the main checkout, whether git tracks it, ignores it or has never seen it.
It is read and edited there, by its path in the main checkout, in the format of
[ticket-format.md](../../../.agents/formats/ticket-format.md), and only there: the worktree
branch never touches it and the run never commits it. A worktree created from HEAD has no copy
of an untracked Ticket, and a claim written in the main checkout beside an edit of the same file
on the branch makes the landing fast-forward fail, so one rule covers the three states.

- The claim is the `**Status:**` line set to `claimed`, written before the worktree exists. On a
  remote tracker the claim is the issue assigned to the developer, the way the tracker file
  describes, made after the developer's yes.
- During the build the file is read and never written: the criteria and the `What to build` line
  are where the behaviours come from. The one exception is a criterion's text a Ruling rewrote as
  the losing side, the forks below. A Ticket that is an issue is never written during the build,
  that exception included: the rewrite rides the close's yes.
- The status walk and who writes each word are the format's. The run writes `claimed` at the
  start and `resolved` at the close, and nothing in between. With `resolved` it writes the
  `Context:` line the format defines as the first line under `## Evidence`, from two readings of
  `bash <skill-dir>/scripts/context-usage.sh`: the `current` figure read at the end of the ground
  step, written as `grounded`, and the `peak` and `band` read at the close, after the last edit. A
  reading that exits non-zero writes `Context: not measured` with the script's reason.

## The reader

The Ticket's Spec and its journey are read by a fork, never by the session, except on the two
branches below where no reader can be forked. They are two whole documents the run needs a slice
of, which is the exploration the Delegates rule below forks for. The session opens neither
document, and it opens neither afterwards to check the fork: what comes back is quoted with the
location of every quote, so the check is a quote read against its line.

Before anything is forked, the door resolves both paths from the Ticket, the way the second run
below does, and the door hashes both itself before it forks: `git hash-object <path>` in the main
checkout for each, recording `absent` for a document not on disk. It resolves and hashes them
the same way when no reader can be forked, on the two branches below. Those two values are the
Digest's `## Sources` lines, so the record the reuse gate trusts is the run's own reading and never
the fork's. When it forks the reader, the door says in one line that both are being read in a
window of their own.

No reader can be forked on two branches: the Agent tool is withheld from the session, or
the Agent tool lists no `do-reader`, as it does on a machine that never linked the reader `do`
ships. On either branch the door has already run its stops, nothing is forked, and the session
reads both documents itself and writes the Digest at the same path and in the same format, its
`## Sources` lines from the door's own hashes, a document not on disk recorded `absent` and named
in one line as below. It says in one line which branch holds: the Agent tool withheld, or
`do-reader` not listed, the reader this machine has not linked, which one run of the skills
repository's `scripts/link-skills.sh` links before the next `/do`. With the tool withheld this is
the case the Delegates rule below covers, and as there the session does that work itself. On
either branch the run neither stops nor asks for the tool or the agent, since the developer cannot
hand one over mid-run and the slice is what the run needs, not the window it was read in. It never
forks another agent in the reader's place: a fork under any other name could still hold the write
tools `do-reader`'s own definition denies it.

The door calls the Agent tool with `subagent_type: do-reader`, the agent `do` ships in
[do-reader.md](../agents/do-reader.md), on the model its definition names, since it quotes rather
than designs, with the brief [digest.md](digest.md) fixes and nothing else, that file's
own list and never a second one here: a copy of the list in this file drifts from the brief the
fork is actually handed. It writes nothing and returns the Digest's text, every section but
`## Sources`, and the one line the run restates in the thread. No other part of either document
reaches the session.

The session checks what comes back before it writes: a return must carry every section the Digest
format fixes other than `## Sources`, `## Journey Path`, `## Stories`, `## Testing Decisions` and
`## Observable criteria`, a section that says its heading or its document is absent counting as
present. A return missing one, whether a refusal, an error or a shape the format does not fix,
stops the door in one line naming what is missing. No Digest is written, the Ticket is left as the
door found it, and the next run forks the reader again. The session never reads the Spec or the
journey itself on a reader failure: that fallback belongs only to the two branches that never reach
the fork at all, the Agent tool withheld and no `do-reader` listed, and never to a return the fork
actually made.

The session writes the Digest itself, whole, at the path [digest.md](digest.md) fixes beside the
Ticket in the main checkout's scratch: its `## Sources` lines from the door's own hashes first,
then the text the reader returned. A `## Sources` section in the text the reader returned is
dropped before the write, since a stranger's text can steer the reader into returning one of its
own, and the run says so in one line, so the written Digest carries exactly one `## Sources`
section, the door's own. A Digest already at that path is replaced whole and never edited.
The run shows the Digest's location and the one line in the thread, and the steps that build on
the slice open that file and read its quotes there. The line is a restatement for the thread: a list
written from it would be the paraphrase the Digest exists to keep out of the record.

A Ticket whose Spec or journey is not on disk still builds. The door records the document as
`absent` among its hashes and the reader quotes nothing under its section, and the run
continues from the Ticket alone, saying so in one line naming the document that is absent. Only the
Ticket's criteria and its `What to build` line feed the behaviours list then, and the line of the
list that would have traced to a quote in that document traces to the criterion instead.

Nothing reads the tree or the scratch across the reader's window. Such a reading cannot tell who
wrote a file, and runs on two features share the scratch, so another run's write in that window
would stop this one, while the reader holds no tool that writes and leaves nothing for it to catch.
Another run writing in the scratch while the reader reads shows nothing, and the run goes on.

A Spec or a journey that changes while the reader reads it shows nothing in this run either.
Since the door hashed it before the fork, the Digest records the hash it had then, the next run's
comparison finds it moved, and that run re-forks the reader and names the document, as the
second run below says.

### A second run

A Digest already sits beside the Ticket whenever a run reaches this point a second time, on a
resume, on a `/do` typed again on the same Ticket, or inside the run once a Ruling amended the
Spec, the forks below. Before it dispatches anything the door
resolves both paths from the Ticket itself and never from the Digest: the Spec is the spec file in
the folder above the Ticket's `issues/` folder, and the journey is the one that Spec's `Journey:`
line names. Then it recomputes the hash of each document at the path it resolved, with the same
`git hash-object` it ran before the fork, and compares the pair with the pair the Digest's `## Sources`
records.

- Both match: the run reuses it, forks no second reader, and says in one line that it reused it.
- Either differs: the run re-forks the reader over both documents, replacing the Digest at the same
  path, and names which of the two changed, in one line.

Both hashes are compared before the run decides, never one and then the other: a comparison that
stopped at the first match would serve an amended Spec, or an amended journey, from the slice the
first run cut. A document recorded `absent` and still not on disk is a match, since nothing about
it moved; a document that appeared where the record says `absent`, one that is gone where the
record carries a hash, and a `## Sources` line the Digest does not carry are each not a match: the
run re-forks.

A `## Sources` path that is not the path the door resolved is not a match either. Both the path and
the hash on that line come out of the file the comparison is there to vouch for, so a Digest naming
a document this Ticket does not reach for is a Digest cut from somewhere else, or one steered by a
document a stranger wrote, and the run re-forks over the resolved paths rather than serving it.

A re-forked reader whose return is not a usable Digest stops the door as a first fork's does, in one
line naming what is missing, since the session writes only from a return it checked.
The Digest already at that path stays where it was, untouched. No run serves it while a recorded
hash or path differs from what the door resolves and hashes there.
A document restored to the exact bytes its record hashes is a match again, served like any other.

A Digest a run left behind when the reading of the tree and the scratch stopped it, the reading
[ADR 0032](../../../docs/adr/0032-a-fork-that-reads-a-strangers-text-holds-no-write-tool.md)
removed, is judged by its record alone, since the gate never asks who wrote the file, so it
is served like any other while both of its hashes match, whether it sits beside the Ticket the
stopped run was on or beside a sibling Ticket the stop's own line named. A developer who does not
trust one deletes it by hand before running that Ticket again, and that run forks the reader as a
first run does.

## The build loop

One behaviour at a time, from the list the Playbook wrote, in its order. Each behaviour is one
verifiable unit that ends in one green commit, per
[sequence-verifiable-units](../../../.agents/principles/sequence-verifiable-units.md).
Each file is read at the moment the loop edits it, never ahead of the behaviour that edits it, and
named on that behaviour's build line for the Reply's Run section, per [reply.md](reply.md), so that
the only source the loop brings into the session is source the run changed.

1. Dispatch the unit test author (the test authors, below) with the complete dispatch input: the
   behaviour to prove, the target, the origin (`new feature`, or `bugfix` when the line
   reproduces a defect), the expected red, and placement when it matters. One dispatch in flight
   at a time, never a batch of tests ahead of the code. While the author runs it is the only
   writer in the tree, and it is never asked to commit.
2. Read the verdict, and record on the behaviour's build line what was done with it:
   - `RED_AS_EXPECTED`: go on.
   - `REFUSED_INCOMPLETE_INPUT`: the behaviour line was too vague to become an assertion. Sharpen
     it and dispatch again.
   - `BLOCKED` on a missing seam: build the seam in production code first (pass the dependency
     in, return the result instead of mutating), then dispatch again. Never a mock around it.
   - `BLOCKED` naming a run command the project map lacks, a slot reading
     `none yet → /testing-policy`: the map does not change during the run, so a second dispatch
     would meet the same `BLOCKED`. The run writes this behaviour and every remaining one itself,
     under [tdd-fallback.md](tdd-fallback.md), naming the missing slot and `/testing-policy` as the
     command that would fill it, and dispatches the unit test author no more this run.
   - `GREEN` before any implementation: the behaviour already holds, or the test asserts nothing.
     Back to the author with that said.
3. Write the smallest production change that turns the test green, and run the single file with
   the single-file command from the project's facts. A mechanical red (an import path, a renamed
   symbol, a typo) is fixed by the run. Any change to an assertion, an expectation or expected
   data goes back to the test author with the reason stated as the contract ("the intended
   behaviour is X"), never as the result ("the test is catching it").
4. Refactor on green, with the suite re-run after each step. A test that goes red under a pure
   refactor was asserting the implementation and goes back to the author.
5. Typecheck, then format the touched files with the project's formatter, both from the project's
   facts; a command the project does not have reads `skip: <reason>`.
6. Commit the test, the implementation and any promotion changeset together, staged by path and
   never with `-A` or `.`. The title is a conventional commit, `type(scope): subject`, with
   `feat`, `fix`, `refactor`, `test`, `docs` or `chore`; the body carries the behaviour line,
   labelled `Behaviour: <line>` on a line of its own so that a resume reads it off the branch, and
   the single-file command that passes.
7. Next behaviour.

Done when every behaviour line has a commit beside it and its build line is recorded for the
Reply's Run section.

Under the fallback, when the loop line reads `Loop: fallback` (no unit test author
in the project and no global one that can be dispatched), the same loop runs by
[tdd-fallback.md](tdd-fallback.md), read only then: the run writes the failing test itself where
a cheap path exists, and otherwise the closest executable check with the reason stated, and no
test author is dispatched. Nothing else changes: red first, the smallest green, one commit.

### The test authors

The Testing Policy's authors write every new test. With the Agent tool, call the Agent tool with
`subagent_type: unit-test-author` for a unit test and `subagent_type: e2e-test-author` for a
flow. Without the Agent tool, call the Skill tool with `test-author` and the argument `unit` or
`e2e`, the project's inline entry point, and fill the dispatch input for yourself before writing.
The unit author returns `RED_AS_EXPECTED`, `GREEN`, `BLOCKED` or `REFUSED_INCOMPLETE_INPUT`; the
E2E author returns `GREEN`, `RED`, `BLOCKED` or `REFUSED_INCOMPLETE_INPUT`, and its `BLOCKED` on a
preflight is an infrastructure failure.

Under `Loop: global` the project has no Testing Policy, and the authors are the two `do` ships in
its `agents/` folder, each carrying the policy's agent core unchanged: call the Agent tool with
`subagent_type: global-unit-test-author` for a unit test and
`subagent_type: global-e2e-test-author` for a flow, with the same dispatch input and one more line,
`Project map: <the map's path>`, the file the ground step derived. Each author reads its commands
and its layout from that file, so no dispatch derives the map again, and the verdicts are the ones
above. The global authors have no inline entry point: with the Agent tool withheld the loop line
already reads `Loop: fallback`, the run writes every unit test itself by
[tdd-fallback.md](tdd-fallback.md) and authors the flow itself, and no author is dispatched.

### Forks

A question is classified before it is asked. An empirical fork (which timing, which output,
whether an API does the thing) is a fact a script can observe: it is settled by a throwaway probe
script in the worktree, deleted before the commit, and never reaches the developer, per
[never-block-on-the-human](../../../.agents/principles/never-block-on-the-human.md). A Design
fork (two shapes the Ticket, its Spec and the code cannot settle) met at the shape step, the
behaviours step or in the build loop is ruled on inside the run, per
[ADR 0036](../../../docs/adr/0036-a-design-fork-is-settled-in-the-run-by-a-read-only-choice-taker-and-only-an-extreme-fork-stops-it.md):
the run says in one line that it met a Design fork at that step and names both sides, then calls
the Agent tool with `subagent_type: choice-taker`, the agent `do` ships in
[choice-taker.md](../agents/choice-taker.md), with the brief its definition names: the Ticket, the
step, the two sides, the Spec, the Digest and the repository root. A Spec that is an issue is
handed with its comments, since the Rulings earlier closes posted sit there under
`## Implementation Decisions`, and a fork an earlier Ticket already ruled on is ruled the same way.
The brief hands no path to the
principles: the fork opens them from the skills checkout, at
`$(readlink -f ~/.claude/skills/do)/../../.agents/principles/`, since a project `do` runs on has no
`.agents/principles/` at its root. The fork holds reading and search alone, per
[ADR 0032](../../../docs/adr/0032-a-fork-that-reads-a-strangers-text-holds-no-write-tool.md),
and the session writes what it returns. The `choice-taker` is forked by name and never replaced by
another agent: a general-purpose fork would read the same Spec holding the write tools that ADR
withholds.

No choice-taker can be forked on two branches: the Agent tool is withheld from the session, or
the Agent tool lists no `choice-taker`, as it does on a machine that never linked the agent `do`
ships. On either branch the run rules nothing itself and never forks another agent in the
choice-taker's place: it stops at its step, the unruled stop below, the Ticket left `claimed` and
the worktree in place, so that the next `/do` on the Ticket resumes it. The message says which
branch holds: the Agent tool withheld, or `choice-taker` not listed, the agent this machine has not
linked, which one run of the skills repository's `scripts/link-skills.sh` links before the next
`/do`.

A return is a Ruling only when its first line reads `settled` or `extreme`, and a `settled` one only
when its `Side:` line names a side that is one of the two sides the session handed over, its `Fork:`
line names those same two sides and no other, and its `Losing criterion:` line is either `none` or
the text of the Ticket criterion that was one of those two sides. Any other return (a refusal, an
error, a shape the definition does not fix, a `settled` with no side, or a `settled` whose `Side:`,
`Fork:` or `Losing criterion:` names anything outside the two sides handed over) is no Ruling: a
steered `choice-taker` that hands back a side neither side of the fork never gets its `Side:` read
into the Spec or the Ticket. The check sits where the return crosses into
the session, per [boundary-discipline](../../../.agents/principles/boundary-discipline.md): the
session never reads a side into a return that fails it and never forks the `choice-taker` a second
time. The run stops at its step, the unruled stop below, with the return quoted whole, and nothing
is written to the Spec or the Ticket.

The unruled stop is a blocked run, written by the blocked shape of [reply.md](reply.md), like the
Extreme stop below and naming the same things, the reason in place of the guarantee: the Agent tool
withheld, `choice-taker` not listed, or the return quoted. Its last line is the `/discuss` command
the Extreme stop fixes, whole, with `on a Design fork no choice-taker ruled` in place of
`on an Extreme fork` and the reason in place of the clause after the semicolon:
`the Agent tool is withheld`, `choice-taker is not listed`, or
`the choice-taker returned no usable Ruling`. It writes no `<Ticket>.extreme.md` sidecar: nothing
about the fork says a human must rule on it, so the next `/do` on the Ticket meets the fork again
and forks the `choice-taker` once one can be forked, rather than stopping on a recorded command.

A `settled` Ruling is written by the session only when the Spec is a local file, as one line
appended to the Spec's Implementation Decisions, marked as the choice-taker's, per
[ADR 0037](../../../docs/adr/0037-a-choice-takers-ruling-amends-the-spec-and-a-ticket-criterion-only-when-it-is-the-losing-side.md),
so every Ticket of the feature reads the same Ruling rather than a second `choice-taker` ruling the
same fork the other way:

```
- Ruled by the choice-taker on Ticket <the Ticket> at the <step> step: <the side taken>. Norm: <the principle, the ADR by title, the CONTEXT.md term or the Spec decision, or "no norm: the side easiest to undo">. Fork: <side A> or <side B>.
```

When the Spec is an issue on a remote tracker, the session writes nothing to the tracker mid-run,
asks the developer nothing, and keeps the Ruling in the run itself, as a held Ruling: the Ruling's
line, in the shape above, recorded in the session and never in a file. Every write `do` makes to a tracker waits for the developer's
yes, the claim and the close alike, and an issue is text anyone who can comment on it can steer,
so a Ruling drawn from it is never posted back there unasked. The held Ruling reaches the review as
the review section below says, the close's one question as the close says, and the reply's
`Rulings` section and its Evidence, per [reply.md](reply.md). The run continues on the Digest it
already holds, with no reader forked again, since the Spec it was cut from did not change. When the
held Ruling carries a `Now reads:` pair, the behaviours list is re-derived with that pair's
`Now reads:` text in place of its `Criterion:` text, and the loop continues at the first behaviour
without a commit, the way the local path below re-derives its list once the Ruling lands. A run
that ends without the close's yes, a stop included, leaves the held Ruling in its reply alone, and a
resume that no longer holds it meets the fork again.

Only when a Ticket criterion is the losing side does the session also rewrite the Ticket: that
criterion's text is replaced by the side that won, its tick kept as it was, and every other
criterion is left untouched, so a Ruling never rewrites more of the Ticket than the fork reached
and the review holds the build to the rewritten criterion. A Ticket file is rewritten in the main
checkout, then and there. A Ticket that is an issue is not written mid-run: the session adds the
pair to the held Ruling, two lines under its line, `Criterion: <the text the issue still carries>`
and `Now reads: <the side that won>`, and the issue's body is edited only at the close's yes.

Once the Ruling is written to a local Spec,
the run carries on in the same session and never stops for it: it prints the one line naming the
Spec as changed, forks the reader again over the Spec and the journey both, never over the Spec
alone, whose Digest would come back with no Journey Path, and replaces the Digest the way a second
run does; then it re-derives the behaviours list from the Digest that comes back and continues at
the first behaviour without a commit.

A fork that touches a risk class with both sides keeping the guarantee whole is ruled on like any
other and never stops the run. An Extreme fork, one of whose sides weakens a guarantee in a risk
class (security, privacy, data loss, auth, billing, migration, idempotency, race) or cannot be
undone once landed, is one nothing in the run rules on. Two readings can find it, and either one
alone stops the run at its step. The session reads the two sides first: a side it reads as Extreme
stops the run there, and no `choice-taker` is forked for a fork already read as Extreme. Otherwise
the `choice-taker` is forked as above, and an `extreme` return stops the run the same way, its
`Fork:`, `Weaker side:`, `Guarantee:` and `Risk class:` lines being what the stop names, each
`/discuss` slot filled from the line named for it and never from the session's own wording. The
session never overrules either
reading: a fork it read as ordinary and the `choice-taker` returned `extreme` on stops, and so
does a fork it read as Extreme that a `choice-taker` might have settled.

The stop is a blocked run, written by the blocked shape of [reply.md](reply.md), and it names:

- the step it stopped at, the shape step, the behaviours step or the build step, with the
  behaviour in flight when it was the build step;
- both sides, as the run's Design fork line named them;
- the guarantee the weaker side would lose, with its risk class, or what could not be undone once
  landed;
- the Ticket, left `claimed`, and the worktree and its branch, both left in place;
- the commits made so far, one line each as the resume lists them, or `none`;
- the Rulings already written, one line per line the Spec's Implementation Decisions carries for
  this Ticket, in the shape reply.md's `Rulings` section fixes, whichever session wrote it, and
  each Ruling this run holds because its Spec is an issue, or `none`.

Nothing is written to the Spec, and the Ticket's criteria are left as they are: only a `settled`
Ruling writes either, and an Extreme fork has none. The stop does write one file beside the Ticket,
its `<Ticket>.extreme.md` sidecar, one line, the `/discuss` command below, so `resume-state.sh`
finds it on a later `/do` and reports it as its `extreme=` and `discuss=` lines instead of meeting
the fork again.

The reply's last line is the `/discuss` command the developer copies, whole, with nothing after it,
in this shape:

```
/discuss Ticket <the Ticket's path or reference>, Spec <the Spec's path or reference>: the do run stopped at the <step> step on an Extreme fork, <side A> or <side B>; <the weaker side> would give up <the guarantee> (<the risk class>). Which side does the Spec take?
```

A side that cannot be undone once landed reads `<the weaker side> cannot be undone once landed:
<what could not be undone>` in place of the clause after the semicolon. The message is one line,
every slot filled from the stop's own facts and none from the session's wording, so a rerun that
meets the same fork prints the same command.

A `/do` typed again on the Ticket with the Spec unchanged is a resume: both hashes match, the
Digest is reused, the list is re-derived from it, and the run meets the same fork at the same step
and stops with the same reply and the same `/discuss` command, since nothing the fork stands on
moved. Once `discuss` amended the Spec, the resume re-forks the reader, as the Resume of
[ticket.md](ticket.md) says.

### Delegates

The session writes the production code and commits. A delegate is forked by exception, per
[the ADR](../../../docs/adr/0009-the-session-writes-a-delegate-is-the-exception-and-no-playbook-depends-on-nesting-depth.md):
for bulk mechanical work with a closed scope, after a script was considered per
[build-the-lever](../../../.agents/principles/build-the-lever.md), or for exploration whose
output would flood the thread per
[guard-the-context-window](../../../.agents/principles/guard-the-context-window.md), and never
while a test author runs. It gets file pointers and the named shape instead of inlined context,
and may dispatch its own test author. When the Agent tool is withheld from it, it writes nothing
and says so, and the session does that work itself. The session reads the delegate's diff and
writes its own summary; the delegate's summary is never passed through.

## The gate

Run in the worktree after the last edit, never earlier, per
[prove-it-works](../../../.agents/principles/prove-it-works.md): the unit tests the run added and
the ones covering the code it touched, the typecheck, the lint and the format check. "Passed
earlier" is stale; a check that ran before the last edit runs again.

The full suites follow the project's **Post-feature gate** in Project facts and run once per
feature, never on every Ticket. The feature's last Ticket is the run's Ticket when every other
Ticket of its Spec already reads `resolved`, and any run with no Spec behind it. There, the gate
adds the full unit suite when the line reads `full unit suite` or `both`, and the full E2E suite
of `full E2E suite` or `both` runs in the verification from the main checkout, where a full suite
waits for the developer's yes; `none` adds nothing. Facts with no **Post-feature gate** line run
the full unit suite on every Ticket.

The commands come from the project's facts, the Testing Policy's Project facts in `CLAUDE.md`. A
command the facts do not carry comes from the repository's own scripts (`package.json` scripts, a
Makefile, a justfile, `pyproject`), never from memory of another repository, and a check with
nothing to run reads `skip: <reason>`. The rest run from one script, each check a key and the
command line it stands for, with one `--infra` pattern per known infra failure the facts name:
`bash <skill-dir>/scripts/gate.sh [--infra <pattern>]... <key>=<command>...`. It prints its
`command=` line first, which the developer reruns for the same answer. A green check is one
`<key>=green` line. A red one is `<key>=red exit=<n> log=<file>` with its failing block under it,
capped at the last twenty lines, and the full output in the file that line names, so the
session's window holds the lines to act on and never the whole output. The `command=` line is
recorded for the Reply's Run section as its gate line, and each check's line is quoted in its
Evidence. Every check runs whatever the one before it
returned, and the script exits 0 on `verdict=green`, 1 on `verdict=red` and 3 on `verdict=blocked`.

- Red: the failing block is already in the gate's output, so the work goes back to the build loop as one more
  unit without rerunning the command, then the whole gate again. The log is opened only when the
  block does not show the cause. Never a skipped test, a weakened assertion or a sleep.
- `verdict=blocked`: a check exited 126 or 127, a runner that cannot start, or printed a line
  matching a pattern for a service down or unreachable, an infrastructure failure and not the code's.
  The run stops as blocked and names the cause from its `cause=` line, and never works around it.
  Only the developer can waive it, and a waiver is recorded as debt in the reply, never as green.
- A tool timeout is "did not finish", neither red nor green: the command line is reported and the
  run stops.

Done when the unit tests the gate runs and the typecheck are green in output produced after the
last edit, every other check is green or reads `skip: <reason>`, and the `command=` line is recorded
for the Reply's Run section.

## The integration

Run in the worktree after a green gate and before the review is called, so that the diff the
reviewers read is the diff that lands. The run rebases the branch it built on onto the developer's
branch, the branch the run started on, and nothing is written to the developer's branch: the branch
that moves is the run's. A protected developer branch does not stop this step, since a rebase onto
a branch writes nothing to it and this step lands nothing. The landing stays the review's, and a
protected target is refused there as it is refused today. The run records the commit its branch is
on before the rebase starts: the command that undoes the rebase is not the same once the rebase has
finished, and the recorded commit is what the later one names. A run the review already read, a
resume whose `review=` line names a Review, walks this step the same way and then lands through
the fix call the review section names, never a second review, per
[ADR 0033](../../../docs/adr/0033-the-review-runs-once-per-run-and-what-comes-after-it-lands-through-the-gate-alone.md).

Every command of this step that can meet a conflict runs with git's conflict-resolution reuse off,
the rebase itself as `git -c rerere.enabled=false -c rerere.autoupdate=false rebase refs/heads/<the
developer's branch>`, qualified so a tag sharing the branch's name can never shadow it, and the
continue and the skip below with the same prefix. The setting is the developer's
own and may be on: then a resolution recorded at one stop is replayed into the next stop of the same
shape, the class would be read from what the cache put back instead of from what git left, and the
run's own resolutions would land in a cache that outlives it.

The step walks the states below, and the state it reached is recorded for the Reply's Run section
as its integration line, per [reply.md](reply.md).

**A rebase that replays no commit.** Before the rebase runs, the step checks whether the
developer's branch is already merged into the run's own: `git merge-base --is-ancestor
refs/heads/<the developer's branch> HEAD`, the ref qualified so a same-named tag can never shadow
it. Where it exits 0, the developer's branch did not move under the run, or
the developer rebased or merged it into `do/<slug>` by hand between two runs, resolving any
conflict along the way, and running the rebase now would only replay a commit git may not drop as
empty, or hand the developer the same hunk their own merge just settled. The run skips the rebase:
it ticks the step as a no-op, reruns nothing, asks nothing, and the review is called with the fixed
point this ancestry already gives, the tip of the developer's branch.

**A rebase that replayed commits.** The run ticks the step with the target and the count, the
branch it rebased onto and how many of its own commits git replayed. The gate that was green before
the replay is stale, since the run's commits now sit on code the branch had not seen: the gate's
command lines run a second time, each command line and its output line quoted in the Reply's
Evidence, and a green gate calls the review on the rebased diff. The replay moves the branch's base, so the fixed
point the review is called with is the commit it rebased onto, never the commit the worktree was
created from: that one is behind the developer's own commits now, and a review given it would read
their work as part of the diff under review.

**A red gate after a rebase that replayed commits.** The run stops as blocked, the way a red gate
after the review's fix run does and never back to the build loop: the replay brought in code the
developer's branch carries, and a run that loops on it edits their work. The reply carries the
failing check named, the command that undoes the rebase, `git reset --hard <the commit recorded
before it started>`, the worktree and its branch left in place and named, the Ticket left
`claimed`, nothing landed and nothing pushed.

**A rebase that stopped.** At every stop of the rebase, before anything else, the run classes the
conflicted hunks: `bash <skill-dir>/scripts/conflict-class.sh`, whose verdict is the class, never
the session's own reading of the markers, per
[ADR 0028](../../../docs/adr/0028-the-conflict-class-is-a-scripts-verdict-never-the-sessions-reading.md).
The script runs before the run resolves, stages or writes anything at that stop. Its lines, one per
conflicted hunk, are quoted in the Reply's Evidence, and the counts, how many hunks it resolved
mechanically and how many it brought to the developer, go on the integration line of the Run
section.

Where every hunk of the stop is `mechanical`, the run resolves them itself and nothing is asked of
the developer. The conflicted files are the list git left, read NUL-delimited so that a path
carrying a space or a newline comes back as one entry and needs no unescaping:
`git diff --name-only --diff-filter=U -z`. A path is a name either side of the rebase chose, so it
never enters a command line as text: pasted in, a single quote in it closes whatever quotes it sits
in, and the `$(...)`, backtick, `;` or `|` after it runs as the run's own command. The two blocks
below run as they stand, with nothing pasted into them, and each path reaches git through a shell
variable, whose value is never evaluated again, or through `xargs -0`, which starts no shell. The
first stages every file the script printed `trusted`, one the developer resolved by hand and never
staged, from the script's own read-only list of them, so git no longer lists it unmerged and nothing
below rewrites it; then it takes the three stages of every file still conflicted out of the index
and writes their union:

```
bash <skill-dir>/scripts/conflict-class.sh --trusted -z | GIT_LITERAL_PATHSPECS=1 xargs -0 -r git add --
stages="$(mktemp -d)"
git diff --name-only --diff-filter=U -z | while IFS= read -r -d '' file; do
  git show ":1:$file" > "$stages/base" && git show ":2:$file" > "$stages/target" &&
    git show ":3:$file" > "$stages/incoming" &&
    git merge-file --union -p "$stages/target" "$stages/base" "$stages/incoming" > "$file"
done
rm -rf "$stages"
```

Stage 2 is the developer's branch and stage 3 the commit being replayed, so the union in that order
keeps both sides with the developer's branch above the replayed commit's, which is the base order
this step owes. Git writes the result and the session never edits a marker. Once every union is
read back, as the next state says, with the file-reading tool and never through a command line, the
second block marks the files resolved:

```
git diff --name-only --diff-filter=U -z | GIT_LITERAL_PATHSPECS=1 xargs -0 git add --
```

Then the continue with the same prefix,
`git -c rerere.enabled=false -c rerere.autoupdate=false rebase --continue`, carries the rebase to
the next commit, and every further stop is classed and resolved the same way. The reply names every
hunk it resolved with its file and location, and every `trusted` file as taken on trust, kept as the
developer wrote it: the run staged it and never read it for a key defined twice, since it is theirs.

**A union that defines the same key twice.** A hunk classed `mechanical` says the two sides only
added lines, never that the two additions mean the same thing. Where both sides added a definition
of one key at the same anchor of a file whose reader takes the last definition it meets (JSON, YAML,
TOML, an INI or a `.env` file), the union keeps both lines and the reader keeps one value: a `deny`
list the developer's branch just added and an empty one from the replayed commit both land, and
whatever reads the landed commit gets the empty one, a control of theirs undone with nothing asked.
So before it marks a file resolved the run reads the union it wrote, and a key defined twice in one
scope of that file is brought to the developer rather than resolved alone: the run stops as blocked
with the file and the key named, the rebase left open at that commit, `git rebase --abort` as the
undo, the worktree and its branch left in place and named and the Ticket left `claimed`. Which
definition stands is theirs to say.

**A stop carrying a contested hunk.** A hunk classed `contested` is the developer's to answer, and
never the run's. The two blocks above are the all-mechanical stop's alone, since the union above
takes every conflicted file and a path never enters a command line: here the script's first call
writes and stages every file whose hunks are all `mechanical` itself, by the same rule, and names
each on a `wrote` line, which the run reads for a key defined twice as the paragraph above says; the
counts are stated before the first question, and the rebase stays open at that commit while the
questions run. The questions come from the same script, which asks them and applies the answers,
takes the order, the class and the locations from `conflict-class.sh` and quotes both sides from the
index stages, so the session reads no marker here either:

```
bash <skill-dir>/scripts/contested.sh
```

What it prints and the code it exits with say what the run does next.

- `no human` (exit 4): nobody can answer in this session, `claude -p` among them, and the script
  says so before it forms a question. The run aborts the integration,
  `git -c rerere.enabled=false -c rerere.autoupdate=false rebase --abort`, which leaves the branch
  as it was, and stops as blocked with the conflicting files the script named, the worktree and its
  branch in place and named and the Ticket left `claimed`. No answer is guessed.
- A question (exit 1): which conflict of how many, the file and the hunk's location, the shape, the
  **Target** and the **Incoming** side quoted each under its own heading, a recommendation with the
  shape as its reason, the answers the shape offers and the undo. The run shows it as the script
  printed it, never reworded, and waits for the developer's one word. Then it passes every answer so
  far back in the order they were asked, each against the id its question carried,
  `bash <skill-dir>/scripts/contested.sh <id>:<answer> ...`, typing the developer's word only when
  it is one of the answers the question offered and `stop` in its place otherwise, since the word
  reaches the shell. The next contested hunk's question follows, or the files are written.
- `resolved` (exit 0): every file carrying a contested hunk was written once from its three index
  stages, `target` taking the Target side, `incoming` the Incoming side and `both` the two in base
  order by the mechanical rule, and staged. The run reads each file the script `wrote` for a key
  defined twice, as the paragraph above says, then continues with the same prefix, and the next
  stop is classed like any other.
- `blocked` (exit 3): the developer answered `stop`, or an answer that is none of the four. The run
  stops as blocked with the rebase left open at that commit, the conflicting files the script
  named, the command that undoes it, `git rebase --abort`, the worktree and its branch left in place
  and named, the Ticket left `claimed`, nothing landed and nothing pushed.

A developer who walks away without answering is left in that same state: the rebase open at the
conflicting commit, the files whose hunks are all `mechanical` written and staged, none of their
answers written, since the script writes no answer until the stop's last one, and the undo already
in the question. Once the rebase finishes, the step is ticked with the
totals across every stop, the mechanical and the contested hunks each verdict line counted and the
answers by word from each `resolved` line, and then the gate's command lines run again and the review
is called, as after any replay, or the fix call on a run the review already read.

**A replayed commit that is empty after the resolution.** The developer's branch already carries
that change, so the continue has nothing left to apply and git says so. The run skips it,
`git -c rerere.enabled=false -c rerere.autoupdate=false rebase --skip`, and the commit is named in
the reply. Nothing of the run's work is lost: the change is already on the branch it was going to
land on.

**Git refusing to continue for any other reason.** The run stops as blocked with the rebase left
open at that commit, the conflicting files named, and the command that undoes it,
`git rebase --abort`, since the rebase has not finished and the abort is still there to take. The
worktree and its branch stay in place and are named, the Ticket stays `claimed`, nothing lands and
nothing is pushed. The blocked states carry two different undo commands, and each names its
own: the abort while the rebase is open, the reset to the recorded commit once it has finished.

The fixed point the review is called with is read once the step is done, whichever state it
reached: `git merge-base refs/heads/<the developer's branch> HEAD` in the worktree, the ref
qualified for the same reason the rebase above is. After a replay it is the
commit the rebase landed on. After a no-op it is the commit the worktree was created from when
nothing moved, and the tip of the developer's branch when they rebased or merged it into
`do/<slug>` by hand, which the ancestor check above already read before the no-op ticked.

Done when the step is ticked as a no-op, or ticked with the target and the count and the gate green
after it, or the run stopped as blocked with its reason, its undo command and its worktree named,
and in each case the integration line is recorded for the Reply's Run section.

## The review

Run once per run, after the gate, and never by hand: the review fixes and lands, the run reads,
and whatever the run commits after it lands through the fix call below, never a second review, per
[ADR 0033](../../../docs/adr/0033-the-review-runs-once-per-run-and-what-comes-after-it-lands-through-the-gate-alone.md).
Call the Skill tool with `do-code-review` and four arguments: the spec source (the Ticket's
location in `ticket`, so the Review lands beside it; the branch alone in `bug-fix` and
`refactoring`), the fixed point of the branch under review (the merge base the integration reads
once it is done, which is the commit the integration rebased onto when it replayed), the
developer's branch as the landing target, and the Gate, the `command=` line the gate printed, so
the review holds its fixes to the checks the run held its own work to. A run that holds a Ruling,
the forks above, sends a fifth argument after the Gate, the held Rulings as one block of text, so
the review holds the build to the Ruling and to a rewritten criterion the Ticket issue does not
carry yet:

```
Held Rulings, not on the tracker:
- Ruled by the choice-taker on Ticket <the Ticket> at the <step> step: <the side taken>. Norm: <the norm>. Fork: <side A> or <side B>.
  Criterion: <the text the Ticket issue still carries>
  Now reads: <the side that won>
```

One item per held Ruling, its two indented lines only when it rewrote a criterion. A run that holds
none sends four arguments, and the fix call below never carries the block: the Review it fixes was
already held to the rewritten text.
Never `--no-fix`, and `fix` only on the path below: the default run is the one every Playbook
wants, per
[ADR 0015](../../../docs/adr/0015-the-default-review-run-fixes-and-lands-and-the-fixer-corrects-for-every-caller.md).
The run waits on the call. While the review runs, its Fixers, one at a time, are the only writer in
the worktree, and the run touches nothing.

A return that reads
`the session is isolated in a worktree, so the door cannot run; nothing reviewed`
reviewed nothing and wrote nothing: the door of the review is a script, and the guard of an
isolated session refuses to run one. It is not a Finding and not a refusal of the diff. The run
leaves the isolation per [worktrees.md](../../../.agents/worktrees.md) and calls the review again,
once, with the same arguments as the first call: the four above, and the fifth, the held Rulings
block, when the run holds one.

What the review does with the call, so that the run does not: it writes the Review, forks one
Fixer per `Act on` Finding, one at a time, each turning its Finding into one commit on the
reviewed branch under the project's Testing Policy, re-runs each Finding's check, the Diff tests
and the Gate, with a Gate fixer on a red one, and, when
the Review is Green, lands the reviewed branch on the developer's branch by fast-forward under the
landing rules of [ADR 0013](../../../docs/adr/0013-do-code-review-lands-a-green-review-by-fast-forward.md)
as [ADR 0027](../../../docs/adr/0027-the-rebase-runs-in-the-session-before-the-review-and-the-landing-retries-only-the-mechanical-class.md)
amends them: a protected branch refused; a developer's branch that moved while the review ran
retried once, by a rebase whose every hunk the review's copy of the conflict class calls
`mechanical`, resolved by the union in base order, and the Gate run again before the
fast-forward; any `contested` hunk aborted and returned as `not landed: target moved` with the
target and the conflicting files; a failed fast-forward left in place; nothing pushed. The review
asks nobody anything on those paths, since it is a fork with nobody to ask: a hunk a person must
judge comes back to this run in its return.

The run reads the outcome off the return and never opens the Review file: the return carries no
Review text, only the outcome, so the Review's Findings never reach the session's window. The
return is recorded for the Reply's Run section, one line per part, per [reply.md](reply.md):

- the Review's location, its `Review:` line;
- the `Act on:` line, how many Findings the review found and how many its Fixers fixed;
- the landing line, `landed at <commit>`, or `not landed` with the review's reason;
- every `Risk:` line, a `Consider` Finding carrying a risk class, flagged to the developer, since a
  risk class is never dismissed silently;
- every `Axis not run:` line, named to the developer with its reason.

The run makes no commit for a Finding and fixes none by hand: a Finding a Fixer left standing
is the review's reason for not landing, and the run stops on it. Landed, and the run goes on to
the verification. Not landed, for any reason the review gives (a Finding `not fixed` or
`not verified`, an Axis `not run`, a red gate after the fixes, `not landed: target moved`, a red
gate after the retry's rebase, a failed fast-forward, a protected branch), and the run stops as
blocked: the review's reason quoted, the
worktree and its branch left in place and named in the reply, the Ticket left `claimed`, so that
nothing lands half fixed. On `not landed: target moved` the reply names the one command that
recovers it, the same run request typed again on the Ticket in `ticket`: its resume finds every
behaviour committed and runs the integration with the developer present to answer the hunks the
review had nobody to ask about, and in `bug-fix` and `refactoring` it is the same run request typed
again, in the developer's same words, whose resume, the Resume of [bug-fix.md](bug-fix.md), finds
the Review the first run wrote and lands through the fix call on it. On a protected branch the reply adds the two commands that land the
reviewed branch by hand from a branch that takes commits, since the diff was reviewed and Green
and only the target was wrong:

```
git switch <a branch that takes commits>
git merge --ff-only do/<slug>
```

**What the run commits after the review.** The review read the branch once, and nothing the run
commits after it is read by a reviewer again: the fix of a red flow, or a rebase a resumed run
finished after the review. Such a branch is gated, then handed to `do-code-review` with
`fix` with the Review's location, then the developer's branch as the landing target and the
`command=` line the gate printed. No reviewer is forked: a Finding the first call
left `not fixed` or `stale` goes to a Fixer again, and a list with nothing left forks no Fixer,
and the call runs the Gate and the landing alone. Its return reads like the first one's, and a
return that reads not landed stops the run the way the first one does.

When the session does not list `do-code-review`, the step reads
`skip: do-code-review not listed`: nothing lands, the worktree and its branch stay in place and
are named in the reply, and the reply names the review and the landing as the developer's next
step.

## The verification

Run from the main checkout after the landing, per
[prove-it-works](../../../.agents/principles/prove-it-works.md): the work is on the developer's
branch now, and Project facts may say the E2E stack serves the primary checkout. The commands run
there, per [worktrees.md](../../../.agents/worktrees.md): git with `-C <the main checkout>`, the
flows through their script, which runs them from the main checkout whichever tree it is called
from, and any other command after a bare `cd` to it and a bare `cd` back to the worktree; the
worktree stays, since it is where a red flow is fixed.

1. The affected flows are the flow the E2E step authored or extended and every existing flow over
   a screen, a route or a message the diff changed. They run from one script, with the single-flow
   command from the project's facts and one `--infra` pattern per known infra failure they name:
   `bash <skill-dir>/scripts/flows.sh [--infra <pattern>]... <single-flow command> <flow>...`,
   its `command=` line printed first, so the verification is a line a reviewer reruns rather than
   the run's account of it. Each flow prints in the gate's shape, keyed by the flow: one
   `<flow>=green` line, or its red or blocked line with its capped block and the file holding its
   full output. A change the E2E step called internal, with no user-observable surface, has no
   affected flow: the step reads `skip: no affected flow` with that reason.
2. A full suite or a remote run waits for the developer's yes, the command line shown first.
   The script asks nothing: this is the only question asked on this path, and the session puts it,
   per [never-block-on-the-human](../../../.agents/principles/never-block-on-the-human.md), because
   its cost is the one thing only the developer can weigh.
   A no records each flow that needed it as not run, leaves the criterion it would have proven
   unticked, and records the waiver as debt in the reply; the close still happens.
3. An infrastructure failure, the script's `verdict=blocked` (a service down, a runner that cannot
   start, a device missing), stops the run as blocked with the cause named from its `cause=` line
   and is never worked around; only the developer can waive it, and the waiver is debt in the
   reply, never green.

4. A red flow is a defect in the landed work, not in the flow: it is fixed in the worktree as one
   more unit of the build loop, with origin `bugfix` and the flow's failure as the expected red,
   the gate run again, and the branch handed to the fix call on the same Review, as the review
   section says for what the run commits after it, which runs the Gate and lands it again with no
   second review. A fix call that returns not landed stops the run the way the first call does.
Done when every affected flow is green in output produced after the last landing, or recorded as
not run on the developer's no, with every command line quoted in the Reply's Evidence.

## The close

After the verification, in the main checkout's Ticket file and nowhere else, per the Ticket file
above: the run never commits it and the worktree branch never touches it.

1. Tick each criterion the evidence proves, and only those: a criterion whose flow the developer
   waived stays unticked. The evidence is the run's own output, produced after the last edit.
2. Append the evidence under `## Evidence`, the last heading of the format, added first when the
   Ticket was published without it. The first line is the `Context:` line, from the `current`
   figure kept at the ground step and a second reading of `scripts/context-usage.sh` now, for
   the `peak` and the `band`; a reading that fails writes `Context: not measured` with the
   script's reason. Then the landed commit, the Review's location, the command lines of the gate
   and the flows with their quoted output lines, and each waiver.
3. Set the `**Status:**` line to `resolved`. The file stays uncommitted, for the developer, and
   the reply lists it beside the Review under the files left uncommitted.
4. On a remote tracker the run asks first, per the tracker file, in one question that lists every
   write the yes makes, in the order it makes them, from the run's own record:
   - for each held Ruling that rewrote a criterion, the Ticket issue's body edited, that
     criterion's `Criterion:` text replaced by its `Now reads:` text, its tick kept, every other
     criterion untouched;
   - for each held Ruling, one comment on the Spec issue, a `## Implementation Decisions` heading
     and the Ruling's line under it, verbatim, so the next Ticket's reader finds it where a local
     Spec keeps it;
   - one comment on the Ticket issue, the evidence, with its held Rulings;
   - then the Ticket issue closed.

   On the developer's yes the run makes the writes in that order. A write the tracker refuses
   stops the rest: nothing after it is made, the Ticket issue stays open, and the reply names each
   write made and the one refused. A no makes none of them: the Ticket issue stays open with its
   old criterion text, and the evidence and the held Rulings are in the reply only. A run with no
   held Ruling asks the same question with the evidence comment and the close alone.
5. Remove the worktree and its branch: the run created them, so the run removes them. Leave the
   worktree first, with a bare `cd` to the main checkout, then, from there,
   `git worktree remove <path>` and `git branch -d do/<slug>`. The branch landed, so the delete is
   safe; a delete that refuses means something did not land, and the run stops there with the
   worktree and its branch named.

Outside the chain there is no Ticket: the close is the worktree's removal alone. A run that stops
as blocked closes nothing: the Ticket stays `claimed`, the worktree and its branch stay in place,
and the reply names them.
