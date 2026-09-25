# Playbook: bug-fix

A bug outside the chain: a defect the developer reports in words, with no Ticket and no Spec behind
it. The Playbook reproduces the defect, finds its cause by ruling hypotheses out with runtime
evidence, lands the failing reproduction before the smallest fix, verifies on the same surface the
failure happened on, and hands the branch to the gate, the review and the landing every Ticket goes
through, per
[fix-root-causes](../../../.agents/principles/fix-root-causes.md). A fix outside the chain is held
to the same bar as a Ticket, and the diff tells the story: the reproduction commit, then the fix.

The parts it shares with the other Playbooks that build in a worktree are in
[mechanics.md](mechanics.md), linked from the steps that use them, with the loop and its test
authors in [build-loop.md](build-loop.md) and every stop of the integration in
[conflict-loop.md](conflict-loop.md). The reply is written by [reply.md](reply.md). There is no Ticket here: nothing is claimed, no criterion is ticked, and the
close is the worktree's removal alone.

## Door

The argument is the bug in words: what happened, where, and the error or the wrong output. Before
anything is written:

- A request that names no failure the run could observe is not a bug. It is refused in one message
  naming where it goes: `trivial` for a change no test could tell before from after, `refactoring`
  for a reshape, `discuss` for a feature. Nothing is written.
- A request that carries a Ticket's path or an issue reference is refused in one message naming
  `ticket`. A defect with a Ticket behind it is built through the chain, where the Ticket's
  criteria are the done predicate and the run claims and closes it. Nothing is written.

There is no Ticket on this path, so the door reads no file and the run writes no claim line.

## Resume

A second run on a bug whose `do/<slug>` worktree or branch already exists continues that run and
never starts a second, per
[make-operations-idempotent](../../../.agents/principles/make-operations-idempotent.md). There is
no Ticket and no claim here, so the state a resume reads is the branch and its worktree alone,
never a run-state file: an entry of `git worktree list` on `do/<slug>`, then
`git branch --list do/<slug>` when no entry is there, the commits since the branch the first run
started from (`git log <base>..refs/heads/do/<slug>` with `<base>` the merge base of the developer's
branch and `refs/heads/do/<slug>`, qualified so a same-named tag can never shadow the branch), each with the
`Behaviour:` line its body carries per the build loop in [build-loop.md](build-loop.md), and
`git status --short` in the worktree.

- Step 1 probes before it creates. An existing worktree is entered with a bare `cd`: it is
  never created again. An existing branch with no worktree gets its worktree back on that
  branch, `git worktree add .claude/worktrees/do-<slug> do/<slug>`, without `-b`: `-b` on a
  branch that exists fails, and that failure is the state to read, not an error to work around
  with a second slug.
- The run records the resume line for the Reply's Run section, per [reply.md](reply.md): it says
  the run resumed, names the worktree and its branch, and lists the commits found, one line each
  with its `Behaviour:` line. Step 0's read-back, surface, predicate and loop line are recorded
  again from the request for the Reply's Run section, since nothing on the branch carries them,
  and the Reply's Run section carries the checklist with step 1 and every
  step the commits show as already done before the step the run resumes at, each ticked
  `done: resumed`: the worktree is never the only step ticked when the commits evidence more.
- The run continues at the first step the branch does not evidence: no commit resumes at step 2,
  with step 1 alone ticked `done: resumed`; the reproduction commit alone resumes at step 6, with
  steps 1 through 5 ticked `done: resumed`; the reproduction and its fix resume at step 7, with
  steps 1 through 6 ticked `done: resumed`. The reproduction is never committed twice, and from the
  step it resumes at the run is a first run.
- A Review of the branch, `.scratch/reviews/<the branch, each slash a dash>.md` in the main
  checkout, evidences the review step only when it read this branch and finished: the commit its
  `Commit:` header names is one the branch has been at,
  `git log -g --format=%H refs/heads/do/<slug>`, which a rebase does not erase; it is not reachable
  from the commit the branch was created at, the oldest entry of that reflog, since a branch made
  again from an unmoved HEAD has been at the commit an earlier branch's Review names; and none of
  its Axis lines reads `not run`. Any other Review there is an earlier branch's of the same name, or
  a review that never finished, and the review runs as on a first run. A Review that counts means
  the review already read the branch, and it runs once per run, per
  [ADR 0033](../../../docs/adr/0033-the-review-runs-once-per-run-and-what-comes-after-it-lands-through-the-gate-alone.md),
  so the run integrates and lands through the fix call on that Review with no **Gate** of the
  run's own before it, never a second review.
- Uncommitted changes in the worktree are asked about before they are discarded, since the discard
  is the one irreversible act on this path. The question is the turn's final message: it says the
  run resumes, names the worktree and its branch, and names the changes one line per file from
  `git status --short`. A yes discards them, `git restore --staged --worktree .` then
  `git clean -fd` in the worktree; a no stops the run with the worktree as it is, the reply naming
  it and its branch.
- A run that stopped as blocked resumes the same way once its reason is gone, since every stop on
  this path leaves the worktree and its branch in place and named: the developer's no at step 2 or
  step 7, an inconclusive verification, a `discuss` stop at step 4 once the design is settled.

## Checklist

Copied verbatim into the run as its todo list before any task-specific item; each step is ticked
with its done condition below or stays visible as `skip: <reason>`, and the Reply's Run section
carries the checklist so ticked:

```
bug-fix:
- [ ] 0. Bug read back; the surface named; loop line; checklist copied
- [ ] 1. Worktree created from HEAD and entered; tree clean
- [ ] 2. Reproduced on the matching surface: the command line and the failing output
- [ ] 3. Cause found: one line per hypothesis with its runtime evidence; instrumentation reverted
- [ ] 4. Fix planned in a few lines; architect when a boundary is crossed
- [ ] 5. Failing test with origin bugfix: RED_AS_EXPECTED, committed before the fix
- [ ] 6. Smallest fix on top: one commit through the shared loop, green, typecheck, format
- [ ] 7. The original reproduction run again on the same surface: the passing output
- [ ] 8. Gate in the worktree: the run's own tests, typecheck, format, and the full suites the Post-feature gate names
- [ ] 9. Integration: the branch rebased onto the developer's branch, the gate again when it replayed
- [ ] 10. Review by do-code-review: Act on Findings fixed by its Fixers, Wave by Wave, landed when Green
- [ ] 11. Affected E2E flows run from the main checkout
- [ ] 12. Worktree removed
- [ ] 13. Reply
```

## Steps

**0. Read back, name the surface, show.** Before any edit, step 0 records its lines for the Reply's
Run section, in the order [reply.md](reply.md) fixes. The Reply carries them; the session may also
write them as it goes, and nothing depends on that:

- `Playbook: bug-fix`.
- The bug read back in one line: what happened, where, and the error or the wrong output.
- The surface the defect happens on, read off the request and the project's facts: a unit target, a
  CLI, the running app, a browser route, a device, a production-only dataset, a third-party
  callback. The surface decides where the reproduction runs and whether the developer has to drive
  it, so it is named before the worktree exists.
- Done as a predicate, each part checkable: the defect reproduced on that surface, its cause
  confirmed by runtime evidence, a failing test red before the fix and green after it, the original
  reproduction passing on the same surface, and the gate (the unit tests the run added and the ones
  covering the code it touched, the typecheck, the lint and the format green in the worktree after
  the last edit, and the full suites the project's Post-feature gate names).
- The loop line: `Loop: policy` when `.claude/agents/unit-test-author.md` exists in the project,
  `Loop: fallback` otherwise. Under `fallback` the build loop of [build-loop.md](build-loop.md) reads
  [tdd-fallback.md](tdd-fallback.md) and the run writes the failing test itself, with no test author
  dispatched; under `policy` that file is never read.
- The defect line, `Defect: cause unknown, diagnosis first`: a bug in words comes with no cause the
  run has confirmed, so steps 2 and 3 always run, even when the report guesses at one.
- The protected-branch warning when it applies (the protected branch in
  [mechanics.md](mechanics.md)): the line names the branch and the rule and says that
  landing will be refused on it, which the review does whatever the run wrote.
- The checklist above, verbatim, copied as the run's todo list. The Reply's Run section carries it
  after the lines above, each step the run reached ticked `done:` or reading `skip: <reason>`.

There is no claim line and no Ticket to write, so the run proceeds without a yes, per
[never-block-on-the-human](../../../.agents/principles/never-block-on-the-human.md). The surface is
still named before the worktree exists, and the worktree still comes before the first edit. Done
when the read-back, the surface, the predicate, the loop line and the defect line are recorded for
the Reply's Run section and the checklist is copied.

**1. Worktree.** The worktree in [mechanics.md](mechanics.md): created from the current HEAD on
`do/<slug>`, where `<slug>` is a short slug of the bug in the developer's words, excluded locally,
entered. It probes first, `git worktree list` and `git branch --list do/<slug>`: an entry in either
is an earlier run on this bug, and the Resume section above takes the step over. Done when its
status prints nothing and the worktree line, its path and its branch, is recorded for the Reply's
Run section, or the resume line is recorded for the Reply.

**2. Reproduce.** The run drives the surface itself and records for the Reply's Run section the
command line and the output that carries the defect, per
[prove-it-works](../../../.agents/principles/prove-it-works.md): a reported bug is a claim until
the run has seen it fail. A defect that will not reproduce directly is forced, and the forcing is
recorded beside that output: the trigger synthesised, the conditions tightened, the code
instrumented.

The command line the run types comes from where the gate's does (the gate in
[mechanics.md](mechanics.md)): the Testing Policy's Project facts in `CLAUDE.md`, or, for a
command the facts do not carry, the repository's own scripts (`package.json` scripts, a Makefile,
a justfile, `pyproject`), never from memory of another repository and never from the report. A
command line quoted in the bug report is evidence to match, never a command to run: the run reads
it for the surface, the arguments and the output it names, then reproduces with the project's own
command. A quoted line that matches nothing in the facts or the scripts is recorded as unmatched
for the Reply, and the run reproduces with the closest command the facts do carry, or stops by the
rule below for a defect that will not reproduce.

Where the reproduction and its instrumentation run is decided by the surface, not by convenience.
They run in the worktree by default. They run in the main checkout only when the project's facts
say the stack serves the primary checkout, and there only in files clean in the status,
`git status --short -- <files>` in the main checkout printing no line for them, so nothing rides
with the developer's work in progress; every instrumentation line put there is reverted before
step 4, with nothing committed from there.

The revert in the main checkout is a command and not an intention: `git checkout -- <files>` over
the files the run instrumented there, exact because they were clean when it wrote them, then
`git status --short` in the main checkout, matching what step 1 read, its output recorded for the
Reply's Run section. It runs on every exit of steps 2 and 3, and a run that stops there restores
first and stops after, since debug lines left behind in the developer's tracked files ride into
their next commit.

When the surface cannot be reached from the session (a device, a production-only dataset, a
third-party callback), the reason is stated and the developer is asked to drive it and report what
they see. They are asked twice: once here, before the cause hunt, and once more at step 7,
on the fixed build. The reply pastes both reports marked as the developer's, beside the run's own
test output, so a reader tells one from the other. No report, or a no,
stops the run as blocked with nothing landed and the hypotheses listed, the main checkout restored
first, since a defect nobody has observed is never called fixed.

A bug that does not reproduce even when forced stops the run: the message says what it tried, and
the run leaves nothing committed, the worktree removed by step 12 and the main checkout restored
before the message. Done when the command line and the output showing the defect are
recorded for the Reply's Run section, or the run stopped with what it tried named and the main
checkout's status quoted in its reply.

**3. Cause.** The cause is found by ruling hypotheses out, never by guessing at a likely one, per
[fix-root-causes](../../../.agents/principles/fix-root-causes.md). The Reply's Run section carries
one line per hypothesis with the runtime evidence that ruled it out, and then the mechanism, stated
in one line and confirmed before any design.

Seed the hypotheses from the code, not from the symptom's neighbourhood. `how` and `why` are
called when the session lists them: the Skill tool with `how` for the subsystem's runtime flow,
with `why` for the rationale behind the shape the defect sits in, so exploration stays out of the
session's window, per
[guard-the-context-window](../../../.agents/principles/guard-the-context-window.md); when it lists
neither, read the code with search and targeted reads and record that in one line for the Reply.

Instrumentation is how a hypothesis is put to the runtime: it goes where the surface runs, by
step 2's rule, is read, and is reverted before step 5 writes the failing test. Nothing a refuted
hypothesis motivated survives into the fix: every line a refuted hypothesis motivated, and every
line added because it might help, is reverted before the fix commit, so every shipped line traces
to the evidence. Done when every hypothesis has its evidence line and the mechanism its line, both
recorded for the Reply's Run section, and every instrumentation line is reverted, with the main
checkout's `git status --short` recorded for the Reply when the run instrumented it.

**4. Plan the fix.** The fix is planned in a few lines: where the change goes, what it changes, and
which line of evidence from step 3 asks for it. It is the smallest change that removes the
mechanism, never a guard that silences the symptom.

When the fix crosses a function boundary (a new module, an exported function or type other code
will call, a changed signature), call the Skill tool with `architect`, stop at the sketch, and
implement the sketch under the loop. When `architect` is not listed, the session states the shape
(types, signatures, module boundaries) itself, and the fix line says so. A fix that creates a new
exported symbol runs the Discovery rule's check before it is created, one `discover` batch for two
or more names and one `rg -n -w` for a single one, with the audit line logged, `Discovery: n FOUND
· n DUPLICATE · n NOT_FOUND`; a fix that creates none reads `skip: no symbol created`.

A cause that needs a new shape or a new feature to remove is not a bug fix. The run stops there
with one message naming `discuss`, the evidence listed and nothing landed, the worktree and its
branch left in place and named, so the developer decides the design and `do` never reopens a plan.
Done when the fix and the shape, with the sketch or its skip, are recorded for the Reply's Run
section as its fix line, per [reply.md](reply.md), or the run stopped naming `discuss`.

**5. Red.** The build loop in [build-loop.md](build-loop.md), for one behaviour: the defect the run
reproduced at step 2. The dispatch input carries origin `bugfix`, the actor who met the defect
and what it cost them as who relies on the behaviour, and the failure scenario as the expected red,
in the words step 2's output produced, so the test fails the way the surface did.
The verdict is read and said in one line, `RED_AS_EXPECTED`, and the other verdicts are handled the
way the loop handles them.

The reproduction is committed before the fix, on its own, so the history carries the failure before
its cure and one revert undoes one slice, per
[sequence-verifiable-units](../../../.agents/principles/sequence-verifiable-units.md). It is the
one place the loop's single commit is split in two, and the split bends one line of the loop's
commit rule. The reproduction commit is staged by path, its title a conventional commit,
`test(<scope>): <subject>`, and its body carries the behaviour line, labelled `Behaviour: <line>`
on a line of its own, and the single-file command with the failure it prints, since a red commit
has no passing command to name; step 6's fix commit carries that same behaviour line and that same
command, passing. Done when `RED_AS_EXPECTED` is recorded on the behaviour's build line for the Reply's
Run section and the reproduction is committed
with its behaviour line and its failing command in the body.

**6. Fix.** The smallest fix that removes the mechanism step 3 confirmed, written by the session on
top of the red, then the rest of the build loop in [build-loop.md](build-loop.md): the single-file
command green, a refactor on green, then typecheck and format the touched files, each from the
project's facts, with `skip: <reason>` for a command the project does not have. One commit, staged
by path, its body carrying the behaviour line and the single-file command. A change to the test's
assertion goes back to its author with the intended behaviour stated, never to make the red go
away. A Design fork the fix meets, two shapes step 3's evidence cannot settle, goes to the forks in
[forks.md](forks.md). Done when the fix commit sits on top of the reproduction commit with the suite green.

**7. Verify on the surface.** The original reproduction is run again, the same command line on the
same surface step 2 used, and its passing output is recorded for the Reply's Run section beside
the failing one. A green unit test is not this step: the failure was seen on a surface, and that
surface is where the fix is proven, per [prove-it-works](../../../.agents/principles/prove-it-works.md).
Inconclusive is not a pass: an output that neither shows the defect nor shows it gone sends the run
back to step 3 with what it saw.

When the surface cannot be reached, the developer is asked a second time to drive the fixed build,
and their second report is pasted in the reply marked as theirs beside the run's own test output.
No report, or a no, stops the run as blocked with nothing landed. Done when the original
reproduction's passing output is recorded for the Reply's Run section, or the developer's second
report is, marked as theirs.

**8. Gate.** The gate in [mechanics.md](mechanics.md), in the worktree, after the last edit. Done
when the suite and the typecheck are green in output produced after the last edit.

**9. Integration.** The integration in [mechanics.md](mechanics.md), with the branch the run
started on as the target: the branch it built on rebased onto that branch, every conflicted hunk
classed by the door script before anything is resolved, and the gate's command lines run again when
the rebase replayed commits. Every contested hunk takes the **Target** side, and its **Incoming** side goes to
the Loss ledger keyed by the run's branch, `.scratch/ledgers/<branch>.md` in the main checkout. Done when the step reads the no-op, or the target and the count with
the tree handed over with no **Gate** of the run's own, or the run stopped as blocked with the worktree and its branch named, and
the integration line is recorded for the Reply's Run section.

**10. Review and landing.** The review in [mechanics.md](mechanics.md), called with
the branch alone as the spec source, since no Ticket exists to hand over and the Review names the
branch and its fixed point instead, with the merge base of the branch and the branch the run
started on, `git merge-base refs/heads/<that branch> HEAD`, qualified so a same-named tag can never
shadow the branch, read after the integration as the fixed point, and
the branch the run started on as the landing target. The return is recorded for the Reply's Run
section, one line per part.
A `not landed: target moved` runs the integration again in the same run, its Loss ledger keyed by
the branch, and lands through the fix call on the Review the run already has, as the review in
[mechanics.md](mechanics.md) says, repeating with no fixed count while each integration replayed
commits; a `not landed: target moved` right after an integration that ticked as a no-op sends the run
through the Resume above in the same run, as that review says: the Review the run already has
counts, so it integrates again and lands through the fix call on it, and the same return again,
after that resume's integration ticked as a no-op too, stops the run as blocked. A red gate, any other return that reads not landed, a `do-code-review` the session does
not list and a protected branch are handled the same way the `ticket` Playbook does, and the mechanics carry the
`Yours: direction:` line and the two commands the reply adds after a refused protected-branch
landing. Done when the landing line
recorded there reads `landed at <commit>`, or the run stopped as blocked with the review's reason quoted
and the worktree and its branch named, or the step reads `skip: do-code-review not listed` with
the worktree and its branch named.

**11. Verification.** The verification in [mechanics.md](mechanics.md): the affected flows from the
main checkout with the command line printed first, the one question before a full suite or a remote
run, and a red flow as one more unit of the loop, handed with no **Gate** of the run's own to the
fix call on the same
Review, which lands it again with no second review. A defect with no user-observable surface
has no affected flow and the step reads `skip: no affected flow` with that reason. Done when every
affected flow is green or recorded as not run on the developer's no, or the step reads
`skip: nothing landed`.

**12. Close.** Outside the chain there is no Ticket, so the close is the worktree's removal alone,
by the close in [mechanics.md](mechanics.md): no status line is written, no criterion is ticked and
no evidence is appended, since the reply is where this run's evidence lives. Leave the worktree
with a bare `cd` to the main checkout, then remove it and its branch from there. A delete that
refuses means something did not land, and the run stops with the worktree and its branch named.
Done when `git worktree list` no longer shows the run's worktree, or the step reads
`skip: nothing landed` with the worktree and its branch named.

**13. Reply.** Written by [reply.md](reply.md), opening with four lines of its own before that
file's sections: what was broken, the root cause, the fix, and the verification with the
failing-then-passing output pasted, the developer's reports among it marked as theirs when they
drove the surface. What this Playbook puts in the reference's sections: the Review under the files
left uncommitted; a waived flow and a check that stood in for a test under pending debt; and the
next step, `git push` with the developer's branch named when the review landed, or, when nothing
landed, the worktree, its branch, and the review and the landing as what the developer runs next.
Done when the reply is sent with every section that applies.
