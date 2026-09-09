# Playbook: bug-fix

A bug outside the chain: a defect the developer reports in words, with no Ticket and no Spec behind
it. The Playbook reproduces the defect, finds its cause by ruling hypotheses out with runtime
evidence, lands the failing reproduction before the smallest fix, verifies on the same surface the
failure happened on, and hands the branch to the gate, the review and the landing every Ticket goes
through, per
[fix-root-causes](../../../.agents/principles/fix-root-causes.md). A fix outside the chain is held
to the same bar as a Ticket, and the diff tells the story: the reproduction commit, then the fix.

The parts it shares with the other Playbooks that build in a worktree are in
[mechanics.md](mechanics.md), linked from the steps that use them, and the reply is written by
[reply.md](reply.md). There is no Ticket here: nothing is claimed, no criterion is ticked, and the
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

## Checklist

Copied verbatim into the run before any task-specific item; each step is ticked with its done
condition below or stays visible as `skip: <reason>`:

```
bug-fix:
- [ ] 0. Bug read back; the surface named; loop line; checklist shown
- [ ] 1. Worktree created from HEAD and entered; tree clean
- [ ] 2. Reproduced on the matching surface: the command line and the failing output
- [ ] 3. Cause found: one line per hypothesis with its runtime evidence; instrumentation reverted
- [ ] 4. Fix planned in a few lines; architect when a boundary is crossed
- [ ] 5. Failing test with origin bugfix: RED_AS_EXPECTED, committed before the fix
- [ ] 6. Smallest fix on top: one commit through the shared loop, green, typecheck, format
- [ ] 7. The original reproduction run again on the same surface: the passing output
- [ ] 8. Gate in the worktree: full unit suite, typecheck, format
- [ ] 9. Review by do-code-review: Act on Findings fixed by its Fixer, landed when Green
- [ ] 10. Affected E2E flows run from the main checkout
- [ ] 11. Worktree removed
- [ ] 12. Reply
```

## Steps

**0. Read back, name the surface, show.** The first message, before any edit, holds in this order:

- `Playbook: bug-fix`.
- The bug read back in one line: what happened, where, and the error or the wrong output.
- The surface the defect happens on, read off the request and the project's facts: a unit target, a
  CLI, the running app, a browser route, a device, a production-only dataset, a third-party
  callback. The surface decides where the reproduction runs and whether the developer has to drive
  it, so it is named before the worktree exists.
- Done as a predicate, each part checkable: the defect reproduced on that surface, its cause
  confirmed by runtime evidence, a failing test red before the fix and green after it, the original
  reproduction passing on the same surface, and the gate (the full unit suite, the typecheck, the
  lint and the format green in the worktree after the last edit).
- The loop line: `Loop: policy` when `.claude/agents/unit-test-author.md` exists in the project,
  `Loop: fallback` otherwise. Under `fallback` the build loop of [mechanics.md](mechanics.md) reads
  [tdd-fallback.md](tdd-fallback.md) and the run writes the failing test itself, with no test author
  dispatched; under `policy` that file is never read.
- The protected-branch warning when it applies (the protected branch in
  [mechanics.md](mechanics.md)): the line names the branch and the rule and says that
  landing will be refused on it, so the developer switches before the work and not after.
- The checklist above, verbatim.

There is no claim line and no Ticket to write, so the run proceeds without a yes, per
[never-block-on-the-human](../../../.agents/principles/never-block-on-the-human.md). Done when the
read-back, the surface, the predicate and the loop line are in the thread and the checklist is
shown.

**1. Worktree.** The worktree in [mechanics.md](mechanics.md): created from the current HEAD on
`do/<slug>`, where `<slug>` is a short slug of the bug in the developer's words, excluded locally,
entered. Done when its status prints nothing and the branch name is in the thread.

**2. Reproduce.** The run drives the surface itself and shows the command line and the output that
carries the defect, per
[prove-it-works](../../../.agents/principles/prove-it-works.md): a reported bug is a claim until
the run has seen it fail. A defect that will not reproduce directly is forced, and the forcing is
named in the thread: the trigger synthesised, the conditions tightened, the code instrumented.

Where the reproduction and its instrumentation run is decided by the surface, not by convenience.
They run in the worktree by default. They run in the main checkout only when the project's facts
say the stack serves the primary checkout, and there only in files clean in the status, so nothing
rides with the developer's work in progress; every instrumentation line put there is reverted
before step 4, with nothing committed from there.

When the surface cannot be reached from the session (a device, a production-only dataset, a
third-party callback), the reason is stated and the developer is asked to drive it and report what
they see. They are asked twice: once here, before the cause hunt, and once more at step 7,
on the fixed build. The reply pastes both reports marked as the developer's, beside the run's own
test output, so a reader tells one from the other. No report, or a no,
stops the run as blocked with nothing landed and the hypotheses listed, since a defect nobody has
observed is never called fixed.

A bug that does not reproduce even when forced stops the run: the message says what it tried, and
the run leaves nothing committed, the worktree removed by step 11. Done when the command line and
the output showing the defect are in the thread, or the run stopped with what it tried named.

**3. Cause.** The cause is found by ruling hypotheses out, never by guessing at a likely one, per
[fix-root-causes](../../../.agents/principles/fix-root-causes.md). The thread carries one line per
hypothesis with the runtime evidence that ruled it out, and then the mechanism, stated in one line
and confirmed before any design.

Seed the hypotheses from the code, not from the symptom's neighbourhood. `how` and `why` are
called when the session lists them: the Skill tool with `how` for the subsystem's runtime flow,
with `why` for the rationale behind the shape the defect sits in, so exploration stays out of the
thread, per
[guard-the-context-window](../../../.agents/principles/guard-the-context-window.md); when it lists
neither, read the code with search and targeted reads and say so in one line.

Instrumentation is how a hypothesis is put to the runtime: it goes where the surface runs, by
step 2's rule, is read, and is reverted before step 5 writes the failing test. Nothing a refuted
hypothesis motivated survives into the fix: every line a refuted hypothesis motivated, and every
line added because it might help, is reverted before the fix commit, so every shipped line traces
to the evidence. Done when every hypothesis has its evidence line, the mechanism is in the thread
and every instrumentation line is reverted.

**4. Plan the fix.** The fix is planned in a few lines: where the change goes, what it changes, and
which line of evidence from step 3 asks for it. It is the smallest change that removes the
mechanism, never a guard that silences the symptom.

When the fix crosses a function boundary (a new module, an exported function or type other code
will call, a changed signature), call the Skill tool with `architect`, stop at the sketch, and
implement the sketch under the loop. When `architect` is not listed, state the shape (types,
signatures, module boundaries) in the thread and say so. A fix that creates a new exported symbol
runs the Discovery rule's check before it is created, one `discover` batch for two or more names
and one `rg -n -w` for a single one, with the audit line logged, `Discovery: n FOUND · n DUPLICATE
· n NOT_FOUND`; a fix that creates none reads `skip: no symbol created`.

A cause that needs a new shape or a new feature to remove is not a bug fix. The run stops there
with one message naming `discuss`, the evidence listed and nothing landed, the worktree and its
branch left in place and named, so the developer decides the design and `do` never reopens a plan.
Done when the fix is in the thread in a few lines, or the run stopped naming `discuss`.

**5. Red.** Done when `RED_AS_EXPECTED` is in the thread and the reproduction is committed.

**6. Fix.** Done when the fix commit sits on top of the reproduction commit with the suite green.

**7. Verify on the surface.** Done when the original reproduction's passing output is in the thread.

**8. Gate.** The gate in [mechanics.md](mechanics.md), in the worktree, after the last edit. Done
when the suite and the typecheck are green in output produced after the last edit.

**9. Review and landing.** Done when the landing line in the thread reads `landed at <commit>`, or
the run stopped as blocked, or the step reads `skip: do-code-review not listed`.

**10. Verification.** Done when every affected flow is green or recorded as not run on the
developer's no, or the step reads `skip: nothing landed`.

**11. Close.** Done when `git worktree list` no longer shows the run's worktree, or the step reads
`skip: nothing landed` with the worktree and its branch named.

**12. Reply.** Written by [reply.md](reply.md). Done when the reply is sent with every section that
applies.
