# Shared mechanics

One file for the parts the Playbooks that build in a worktree share, read by `ticket`, `bug-fix`
and `refactoring`, so a fix to a mechanic is made once. It carries the worktree, the protected
branch, the Ticket file, the reader, the delegates, the gate, the integration, the review, the
verification and the close. A Playbook links the section it needs and never copies it.
A part a step reads on its own is a file beside this one, so a step that reaches for it carries
none of the rest: [build-loop.md](build-loop.md) carries the loop and its test authors,
[forks.md](forks.md) the forks, and [conflict-loop.md](conflict-loop.md) the conflict loop every
stop of the integration runs. [integrate.md](integrate.md) builds in no worktree and reads that
last file alone.

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

- The claim is the `**Status:**` line set to `claimed`, written after the grounding the run builds
  from is in hand and before the worktree exists, except on the `cause unknown, diagnosis first`
  branch of the `ticket` Playbook's Plan step, where the worktree already exists, cut for the
  diagnosis before the Planner is even forked, so it exists before the claim too. The grounding is
  the part of a run that refuses, so a claim written ahead of it leaves every refusal with a status
  the developer resets by hand before the rerun, and on that one branch a worktree and its branch
  besides, which the refusal names rather than leaving for the door's worktree-exists rule to catch
  unnamed. On a remote tracker the claim is the issue assigned to the developer, the way the
  tracker file describes, made after the developer's yes.
- During the build the file is read and never written: the criteria and the `What to build` line
  are where the behaviours come from. The one exception is a criterion's text a Ruling rewrote as
  the losing side, the forks of [forks.md](forks.md). A Ticket that is an issue is never written
  during the build,
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

The door also reads this Ticket's own `Ruled by the choice-taker on Ticket <this Ticket>` lines the
Spec's Implementation Decisions already carries, when it carries any, straight off the Spec text it
just hashed, and records them, their `Fork:`, side-taken and `Norm:` text, for the session: the
Digest carries no Implementation Decisions section, so this is the one place those lines reach the
behaviours step and the reply's `Rulings` section.

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
section, the door's own. A Digest already at that path is replaced whole and never edited, with one
exception the forks of [forks.md](forks.md) carry: the `## Sources` lines a `settled` Ruling that rewrote no Ticket
criterion moves in place, the rest of the file left as it stands.
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
Spec, the forks of [forks.md](forks.md). Before it dispatches anything the door
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

## Delegates

In a `bug-fix` or a `refactoring` run the session writes the production code and commits; in a
`ticket` run the Builder does, per
[ADR 0047](../../../docs/adr/0047-the-ticket-run-forks-a-planner-then-a-builder-and-the-session-stops-writing-code.md).
A delegate is forked by exception, per
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

- Red: the failing block is already in the gate's output, so the work goes back to the build loop
  of [build-loop.md](build-loop.md) as one more
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
continue and the skip of [conflict-loop.md](conflict-loop.md) with the same prefix. The setting is
the developer's own and may be on: then a resolution recorded at one stop is replayed into the next
stop of the same shape, the class would be read from what the cache put back instead of from what
git left, and the run's own resolutions would land in a cache that outlives it.

The step walks the states below, and the state it reached is recorded for the Reply's Run section
as its integration line, per [reply.md](reply.md).

**A rebase that replays no commit.** Before the rebase runs, the step checks whether the
developer's branch is already merged into the run's own: `git merge-base --is-ancestor
refs/heads/<the developer's branch> HEAD`, the ref qualified so a same-named tag can never shadow
it. Where it exits 0, the developer's branch did not move under the run, or
the developer rebased or merged it into `do/<slug>` by hand between two runs, resolving any
conflict along the way, and running the rebase now would only replay a commit git may not drop as
empty, or hand the developer the same hunk their own merge just settled.

Before it ticks anything, the run reads the ledger's location, fixed the same way it is fixed
before a rebase starts and never a line a resumed run has to be handed back, and, where that file
exists, reads it directly the way the review already does: the reviewer opens the file, and here
the run does too. Where no such file exists, or every entry on it already carries an applied line
or was judged `drop`, the ancestor check stands on its own and the run skips the rebase: it ticks
the step as a no-op, reruns nothing, asks nothing, and the review is called with the fixed point
this ancestry already gives, the tip of the developer's branch. Where the ledger carries an entry
judged `reapply` with no applied line, a run cut short between two reapply commits and resumed
once the rebase it left behind had already finished, the ancestor check alone does not excuse a
ledger entry judged `reapply` with no applied line: the run brings that entry back the same way
**The reapplies brought back** of [conflict-loop.md](conflict-loop.md) does, one commit or `none`
recorded into the ledger the same
way that state records it, then runs the whole **Gate** once before the review is called, or hands
the tree to the fix call on a run the review already read with no **Gate** of its own, never
ticking the step as a no-op over an entry still owed a commit.

**A rebase that replayed commits.** The run ticks the step with the target and the count, the
branch it rebased onto and how many of its own commits git replayed. The gate that was green before
the replay is stale, since the run's commits now sit on code the branch had not seen: the gate's
command lines run a second time, each command line and its output line quoted in the Reply's
Evidence, and a green gate calls the review on the rebased diff. The replay moves the branch's base, so the fixed
point the review is called with is the commit it rebased onto, never the commit the worktree was
created from: that one is behind the developer's own commits now, and a review given it would read
their work as part of the diff under review.

**A red gate after a rebase that replayed commits.** The run stops as blocked, the way a red gate
after the review's fix run does and never back to the build loop of
[build-loop.md](build-loop.md): the replay brought in code the
developer's branch carries, and a run that loops on it edits their work. The reply carries the
failing check named, the command that undoes the rebase, `git reset --hard <the commit recorded
before it started>`, the worktree and its branch left in place and named, the Ticket left
`claimed`, nothing landed and nothing pushed.

**A rebase that stopped.** Every stop runs the conflict loop of
[conflict-loop.md](conflict-loop.md), from the class the script reads through the states git
refuses, and never a copy of it here. The loop ends the step in one of the two states it names: the
rebase carried to its end, or the run stopped as blocked with the rebase left open.

The fixed point the review is called with is read once the step is done, whichever state it
reached: `git merge-base refs/heads/<the developer's branch> HEAD` in the worktree, the ref
qualified for the same reason the rebase above is. After a replay it is the
commit the rebase landed on. After a no-op it is the commit the worktree was created from when
nothing moved, and the tip of the developer's branch when they rebased or merged it into
`do/<slug>` by hand, which the ancestor check above already read before the no-op ticked.

Done when the step is ticked as a no-op, or ticked with the target and the count and the tree
handed over with no **Gate** of the run's own, or the run stopped as blocked with its reason, its
undo command and its worktree named,
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
the review holds its fixes to the checks the run held its own work to. A run whose integration
wrote a **Loss ledger** sends one more argument after the Gate, the Loss ledger's location, the
absolute path in the main checkout the integration above fixed before the rebase started, so the
review reads what a `contested` hunk set aside:

```
Loss ledger: <the absolute path>
```

The path alone goes over, never the ledger's text: the orchestrator relays the line and the
technical reviewer opens the file. A run whose integration wrote no ledger has no ledger to name
and sends no such argument, and the reviewer's own `none` is the orchestrator's to write. A run
that holds a Ruling, the forks of [forks.md](forks.md), sends the held Rulings as one block of
text, so the review
holds the build to the Ruling and to a rewritten criterion the Ticket issue does not carry yet:

```
Held Rulings, not on the tracker:
- Ruled by the choice-taker on Ticket <the Ticket> at the <step> step: <the side taken>. Norm: <the norm>. Fork: <side A> or <side B>.
  Criterion: <the text the Ticket issue still carries>
  Now reads: <the side that won>
```

One item per held Ruling, its two indented lines only when it rewrote a criterion. The block ends
at the end of the call, since every line after its first is a Ruling, so it is the last argument
always, after the ledger and after every other argument the call carries, and a single-line
argument never sits behind it. A run sends four arguments, five when its integration wrote a
ledger, and one more, the block, when it holds a Ruling: five without a ledger, six with one. The
fix call below never carries the block: the Review it fixes was already held to the rewritten text.
Never `--no-fix`, and `fix` only on the path below: the default run is the one every Playbook
wants, per
[ADR 0015](../../../docs/adr/0015-the-default-review-run-fixes-and-lands-and-the-fixer-corrects-for-every-caller.md).
The run waits on the call. While the review runs, its Fixers, one at a time, are the only writer in
the worktree, and the run touches nothing.

The Plan's `## Map` is never among the arguments, whatever else the call carries. It is the
subsystem as it stood before the diff, cut by the Planner of [plan.md](plan.md) while the branch
was still empty, and each reviewer builds its own map of the tree the diff left behind. A reviewer
handed the pre-diff one would read the work under review as code that was already there, and clear
a change it never looked at.

A return that reads
`the session is isolated in a worktree, so the door cannot run; nothing reviewed`
reviewed nothing and wrote nothing: the door of the review is a script, and the guard of an
isolated session refuses to run one. It is not a Finding and not a refusal of the diff. The run
leaves the isolation per [worktrees.md](../../../.agents/worktrees.md) and calls the review again,
once, with the same arguments as the first call: the four above, the Loss ledger when the
integration wrote one, and the held Rulings block, last of all, when the run holds one.

What the review does with the call, so that the run does not: it writes the Review, forks one
Fixer per `Act on` Finding, one at a time, each turning its Finding into one commit on the
reviewed branch under the project's Testing Policy, re-runs each Finding's check, the Diff tests
and the Gate, with a Gate fixer on a red one, and, when
the Review is Green, lands the reviewed branch on the developer's branch by fast-forward under the
landing rules of [ADR 0013](../../../docs/adr/0013-do-code-review-lands-a-green-review-by-fast-forward.md)
as [ADR 0027](../../../docs/adr/0027-the-rebase-runs-in-the-session-before-the-review-and-the-landing-retries-only-the-mechanical-class.md)
amends them: the fast-forward serialized with every other run landing on the repository, per
[ADR 0043](../../../docs/adr/0043-concurrent-landings-serialize-only-the-fast-forward.md); a
protected branch refused; a developer's branch that moved while the review ran retried once, by a
rebase whose every hunk the review's copy of the conflict class calls `mechanical`, resolved by the
union in base order, and the Gate run again before the fast-forward; any `contested` hunk aborted,
or the target moved again while that Gate ran, and returned as `not landed: target moved` with the
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
the verification.

On `not landed: target moved`, the developer's branch moved while the review ran, by the
developer's hand or by another run's landing, and the landing's own rebase met a hunk it does not
take or the branch moved again while its Gate ran. The run answers that return in the same run, per
[ADR 0034](../../../docs/adr/0034-a-contested-hunk-takes-the-target-side-and-what-it-sets-aside-is-reapplied-after-the-integration.md),
so the developer never types the request again only so that a human is present. It runs its
integration once more, in the worktree, onto the moved branch, as the integration above says: every
contested hunk takes the **Target** side and its **Incoming** side goes to the same Loss ledger,
the Loss ledger judged and the reapplies brought back, with no **Gate** of the run's own after the
last of them. Each reapply goes through `check-reapply.sh` with its `replace` and `with` exactly as
[conflict-loop.md](conflict-loop.md) says,
and on this integration that check is the only reading its `with` text gets, since no reviewer
reads a commit made after the review: a block the script refuses writes nothing, is recorded
`none`, and is listed in the reply among this integration's drops, marked as coming after the
review. The integration hands the branch straight to the fix call on the Review the run already
has, as the paragraph below says for what the run commits after the review, never a second review:
the fix call gates the same tree itself and refuses to land it red, and this retry has no fixed
count, so a **Gate** here would pay for the suite twice on every lap, per
[ADR 0049](../../../docs/adr/0049-one-tree-is-gated-once-and-do-skips-the-gate-the-landing-call-runs.md).
That call is made only on a Review whose Findings its Fixers all fixed, since the reapplies it
gates are commits no reviewer read: a Review still carrying a Finding left `not fixed` or `stale`
stops the run as blocked before the call, with the reply the red below carries, because a call on
it forks a Fixer again, and a Fixer's commit is what turns a red **Gate** over to the Gate fixer,
whose brief is the red block alone and whose fix would edit the replayed code nobody read and land
it. With nothing left for a Fixer, a red **Gate** on that tree comes back as
`not landed: gate red` with its failing check, never the Gate fixer, and it stops the run as
blocked the way a red **Gate** after the first integration's reapplied commits stops it: the
failing check named, the ledger's location, since the ledger holds what came back and what did
not, and `git reset --hard <the commit recorded before it started>`, which undoes the whole
integration. The worktree and its branch stay in place and are named, the Ticket stays `claimed`,
nothing lands and nothing is pushed. A blocked
state of that integration stops the run as it stops it before the review, with its own undo
command. The retry has no fixed count, per
[ADR 0044](../../../docs/adr/0044-the-re-integration-retries-while-the-target-tip-changes.md): it
repeats for as long as each return reads `not landed: target moved` and the integration before it
replayed commits, since every such return is another landing on the branch, and the runs landing
at once are finite. A `not landed: target moved` right after an integration that ticked as a no-op
is the one that ends the loop: the integration found the branch already holding the target, so no
other landing happened, the landing and the integration disagree about the target, and integrating
again would meet the same tip.

Not landed, for any other reason the review gives (a Finding `not fixed` or `not verified`, an Axis
`not run`, a red gate after the fixes, a `not landed: target moved` right after an integration that
ticked as a no-op, a red gate after the
retry's rebase, a failed fast-forward, a protected branch), and the run stops as blocked: the review's reason quoted, the
worktree and its branch left in place and named in the reply, the Ticket left `claimed`, so that
nothing lands half fixed. On a `not landed: target moved` right after an integration that ticked as
a no-op the reply names the one command that
recovers it, the same run request typed again on the Ticket in `ticket`: its resume finds every
behaviour committed and runs the integration again, which resolves the hunks the review's landing
left to the **Target** side and writes their **Incoming** side to the ledger, and in `bug-fix` and `refactoring` it is the same run request typed
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
finished after the review. Such a branch is handed to `do-code-review` with
`fix` with the Review's location, then the developer's branch as the landing target, and with no
**Gate** of the run's own over it first, so a second one here would pay for the suite twice, per
[ADR 0049](../../../docs/adr/0049-one-tree-is-gated-once-and-do-skips-the-gate-the-landing-call-runs.md).
A run whose own gate ran before the review hands the fix call the `command=` line that gate
printed: the fix call gates the same tree itself, from that very line, and refuses to land it red.
A run that reaches this point having run no gate of its own, the resume on `verdict=land` of
[ticket.md](ticket.md) and the resume of [bug-fix.md](bug-fix.md), has no such line to hand, since
the session that printed it was another run's: it hands the fix call no `command=` line, and the
fix call runs the Gate itself from the Testing Policy's Project facts, as
[fix.md](../../do-code-review/references/fix.md) has it do with no line handed. What that Gate ran
is in the fix call's return, which the Reply's gate line carries instead, per [reply.md](reply.md).
No reviewer is forked: a Finding the first call
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
   more unit of the build loop of [build-loop.md](build-loop.md), with origin `bugfix` and the
   flow's failure as the expected red,
   and the branch handed to the fix call on the same Review with no **Gate** of the run's own, as
   the review section says for what the run commits after it: the fix call gates the same tree
   itself and lands it again with no second review. A fix call that returns not landed stops the
   run the way the first call does.
Done when every affected flow is green in output produced after the last landing, or recorded as
not run on the developer's no, with every command line quoted in the Reply's Evidence.

## The close

After the verification, in the main checkout's Ticket file and nowhere else, per the Ticket file
above: the run never commits it and the worktree branch never touches it.

1. Tick each criterion the evidence proves, and only those: a criterion whose flow the developer
   waived stays unticked. The evidence is the run's own output, produced after the last edit.
2. Append the evidence under `## Evidence`, the last heading of the format, added first when the
   Ticket was published without it. The first line is the `Context:` line, from the `current`
   figure the run kept when it grounded and a second reading of `scripts/context-usage.sh` now, for
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
