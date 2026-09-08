# The `ticket` Playbook

The last step of the chain. It takes one Ticket, in the format of
[ticket-format.md](../../../.agents/formats/ticket-format.md), and nothing else: never a Spec,
never a session summary. The parts it shares with the other Playbooks that build in a worktree
are in [mechanics.md](mechanics.md), linked from the steps that use them, and the reply is
written by [reply.md](reply.md). The checklist below is copied verbatim into the run before any
task-specific item, the research brief's twelve steps with the review and landing step reading as
the review's; each step carries its done condition below.

## Door

The argument is a Ticket's path, or an issue reference resolved through the tracker file,
`docs/agents/issue-tracker.md`. Before anything is written:

- The Ticket is read: the file, or the issue's body and comments through the tracker's CLI as
  the file describes. Its Spec is read where the format says it is (the spec file in the folder
  above the `issues/` folder, or the issue the parent section names), with the journey the Spec's
  `Journey:` line names when it names one. Every Ticket the `Blocked by` line names is read.
- A Ticket that is `resolved` stops the run in one line. Nothing is written.
- A Ticket whose `Blocked by` names one not `resolved` is refused before the claim, in one
  message naming the blocker and its status. Nothing is written; the developer builds the blocker
  first, or sets its status by hand when it was done outside the chain.
- A `claimed` Ticket whose `do/<slug>` worktree exists is resumed, as the Resume section says:
  never a second worktree, and the claim stands.
- A `claimed` Ticket whose worktree is gone starts over: the first message says so in one line,
  and the claim stands, since the claim is idempotent.
- On a remote tracker, an issue assigned to someone else stops the run in one line with their
  name.

## Resume

A `claimed` Ticket whose `do/<slug>` worktree exists, an entry of `git worktree list` on that
branch, is picked up where the last run stopped and never restarted. The state a resume reads is
the branch and its worktree, never a run-state file: the commits since the developer's branch,
`git log <base>..do/<slug>` with `<base>` their merge base, each with the `Behaviour:` line its
body carries per the build loop in [mechanics.md](mechanics.md), and the working tree,
`git status --short` in the worktree. The Ticket is not written: the claim stands.

- The first message says the run resumes, names the worktree and its branch, and lists the
  commits found, one line each with its `Behaviour:` line. The claim line is not written again.
  The checklist follows, with steps 0 and 1 reading `done: resumed`.
- The worktree is entered, never created: a second worktree is never made.
- The grounding, the shape and the behaviours list run again without a write. The list is
  re-derived from the Ticket and its Spec as step 4 says, never from the commits; then every line
  whose behaviour a commit body carries is ticked with that commit's sha beside it, and a commit
  whose `Behaviour:` line matches no line of the list is kept and named in the thread.
- The loop continues at the first behaviour without a commit, and from there the run is a first
  run: the flows, the gate, the review, the close, the reply.
- Uncommitted changes in the worktree are named in the first message, one line per file from
  `git status --short`, and the run asks before discarding them, since the discard is the one
  irreversible act on this path. A yes discards them, `git restore --staged --worktree .` then
  `git clean -fd` in the worktree, and the first behaviour without a commit restarts red-first; a
  no stops the run with the worktree as it is, the reply naming it and its branch.
- A run that stopped on a design fork (the forks in [mechanics.md](mechanics.md)) resumes the
  same way once `discuss` amended the Spec: the list is re-derived from the amended Spec, and the
  loop continues at the first behaviour without a commit.

## Checklist

```
Do:
- [ ] 0. Input resolved and confirmed; policy or fallback detected; ticket claimed
- [ ] 1. Worktree created from HEAD and entered; tree clean
- [ ] 2. Grounded: done stated as a predicate; discover batch run and audited
- [ ] 3. Shape named; architect sketch when a boundary is crossed
- [ ] 4. Behaviours listed from the plan, critical paths first
- [ ] 5. Build loop: one behaviour, one dispatch, one green commit, repeat
- [ ] 6. E2E flows authored or extended (native and mixed surfaces)
- [ ] 7. Gate in the worktree: full unit suite, typecheck, format
- [ ] 8. Review by do-code-review: Act on Findings fixed by its Fixer, landed when Green
- [ ] 9. Affected E2E flows run from the main checkout
- [ ] 10. Ticket closed with evidence; worktree removed
- [ ] 11. Reply
```

## Steps

**0. Resolve, claim, show.** The first message, before any edit, holds in this order:

- `Playbook: ticket`.
- The title confirmed back, `<NN>: <title>`.
- Done as a predicate: the acceptance criteria plus the gate (the full unit suite, the typecheck,
  the lint and the format green in the worktree after the last edit), each part checkable.
- The loop line: `Loop: policy` when `.claude/agents/unit-test-author.md` exists in the project,
  `Loop: fallback` otherwise. Under `fallback` the build loop of [mechanics.md](mechanics.md)
  reads [tdd-fallback.md](tdd-fallback.md) and the run writes every test itself, with no test
  author dispatched; under `policy` that file is never read.
- A defect line when a behaviour reproduces a bug, judged from the Ticket's words per criterion
  line (a line that says something fails, throws, is wrong or came back) and never from a field:
  `Defect: origin bugfix, cause stated` when the Ticket names the cause, `Defect: cause unknown,
  diagnosis first` when it does not.
- The protected-branch warning when it applies (the protected branch in
  [mechanics.md](mechanics.md)): the line names the branch and the rule and says landing will be
  refused on it.
- The claim line, `Claimed: <the Ticket's path or reference>`, once the claim is written as the
  Ticket file in [mechanics.md](mechanics.md) says. On a remote tracker the run waits for a yes
  before it; a no stops the run with nothing written.
- The checklist above, verbatim.

On a local Ticket the run proceeds without a yes, per
[never-block-on-the-human](../../../.agents/principles/never-block-on-the-human.md): the claim is
a reversible file write, and an interrupt costs the developer one turn. Done when the title, the
predicate, the loop line and the claim line are in the thread and the Ticket reads `claimed`.

**1. Worktree.** The worktree in [mechanics.md](mechanics.md): created from the current HEAD on
`do/<slug>`, where `<slug>` is the Ticket file's slug without its number, excluded locally,
entered. Done when its status prints nothing and the branch name is in the thread.

**2. Ground.** Read `CONTEXT.md` (the root one, or the one `CONTEXT-MAP.md` names), the ADR
titles under `docs/adr/` and the bodies of the ones the Ticket touches, and the code the Ticket
names. When the session lists `how`, call the Skill tool with `how` over the subsystem the Ticket
reshapes, so the exploration stays out of the thread, per
[guard-the-context-window](../../../.agents/principles/guard-the-context-window.md); when it does
not, explore with search and targeted reads, and say so in one line. Then the discover batch:
call the Skill tool with `discover` once, with every symbol the Ticket, its Spec and the reading
name in one batch, in the form the Discovery rule fixes, before the first of them is created, and
log the audit line, `Discovery: n FOUND · n DUPLICATE · n NOT_FOUND`. When `discover` is not
listed, one `rg -n -w` per candidate stands in and the audit line says so. A symbol the sketch
adds later is checked before it is created the way the Discovery rule allows: one direct
`rg -n -w` for a single name, one more batch for two or more. Restate done as a predicate,
sharpened by what the reading showed. Then read the session's context once, `bash
<skill-dir>/scripts/context-usage.sh`, and keep its `current` figure: it is the `grounded` figure
of the `Context:` line the close writes per [mechanics.md](mechanics.md). Done when the predicate,
the audit line and the context reading are in the thread.

**3. Shape.** Name the data shape and its organising structure before any logic, per
[foundational-thinking](../../../.agents/principles/foundational-thinking.md) and
[model-the-domain](../../../.agents/principles/model-the-domain.md): the type or record each
glossary word maps to, and the structure that holds the rule (a union, a state machine, a
registry, a reducer) instead of scattered conditionals. Delete the dead weight the Ticket makes
obsolete before adding, per
[subtract-before-you-add](../../../.agents/principles/subtract-before-you-add.md) and
[laziness-protocol](../../../.agents/principles/laziness-protocol.md), as its own commit with the
suite green. When the work crosses a function boundary (a new module, an exported function or
type other code will call, a changed signature) and neither the Ticket, its Spec nor a
`Settled by prototype:` snippet carries a sketch, call the Skill tool with `architect`, stop at
the sketch, and implement the sketch under the loop, so every test still goes through a test
author. The sketch is the contract: a deviation during the build is surfaced in the reply, and a
second deviation of the same shape stops the run as a wrong sketch, the deviations listed, the
worktree and its branch named, the message naming `discuss`. When `architect` is not listed, the
shape (types, signatures, module boundaries) is stated in the thread and the step says so. When
no boundary is crossed the step reads `skip: no boundary crossed`. Done when the shape is in the
thread, or the skip.

**4. Behaviours.** Write the list from the Ticket's criteria and its `What to build` line, the
Spec's stories and Testing Decisions, and the journey's step table and failure branches when the
Spec points at one; never from the implementation. It holds the behaviours callers observe,
critical paths and the logic that can be wrong first, not one line per branch. Each line becomes
one dispatch, and a line that reproduces a defect is marked `bugfix`. A defect whose cause the
Ticket does not name is diagnosed before the list, as the `bug-fix` Playbook does: the defect
reproduced on the matching surface, the hypotheses ruled out with runtime evidence, the
instrumentation reverted, the mechanism confirmed, per
[fix-root-causes](../../../.agents/principles/fix-root-causes.md); when `bug-fix` is not
installed under Links, these four steps stand on their own. A design fork found here stops
the run (the forks in [mechanics.md](mechanics.md)). Show the list once; the loop starts on the
developer's silence. Done when the list is in the thread.

**5. Build loop.** The build loop in [mechanics.md](mechanics.md), one behaviour per dispatch,
under the loop the first message named. Each behaviour is one line in the thread as it lands: the
line, `RED_AS_EXPECTED`, green, the commit. Done when every line has a commit beside it.

**6. E2E flows.** The surface is the one the project's Testing Policy names on its section
marker. On a native or mixed surface, every user-observable change (a screen, a flow, a
navigation, a message, a state the product shows) gets its flow authored or extended after the
feature exists, by the E2E test author (the test authors in [mechanics.md](mechanics.md)) with
the complete input: the behaviour to prove, the journey or screen, the origin, the fixture state,
placement when it matters. The flow must return `GREEN`; `BLOCKED` on a preflight stops the run
as blocked. The flow is committed on its own or with the last behaviour. On a consumer surface
the flow lives in the consumer repository and is recorded as pending debt with the consumers
named. A purely internal change states why no flow is needed, never presumed. Done when each
user-observable change has a flow or a stated reason.

**7. Gate.** The gate in [mechanics.md](mechanics.md), in the worktree, after the last edit. Done
when the suite and the typecheck are green in output produced after the last edit.

**8. Review and landing.** The review in [mechanics.md](mechanics.md), with the Ticket's
location as the spec source, the commit the worktree was created from as the fixed point, and the
branch the run started on as the landing target. The thread shows the return, one line per part.
Done when the landing line in the thread reads `landed at <commit>`, or the run stopped as
blocked with the review's reason quoted and the worktree and its branch named, or the step reads
`skip: do-code-review not listed` with the worktree and its branch named.

**9. Verification.** The verification in [mechanics.md](mechanics.md): the affected flows from
the main checkout with the command line printed first, the one question before a full suite or
a remote run, and a red flow as one more unit of the loop, gated and handed to a second review
call with the landed commit as its fixed point, which lands it again. Done when every affected
flow is green or recorded as not run on the developer's no, or the step reads
`skip: nothing landed`.

**10. Close.** The close in [mechanics.md](mechanics.md): the Ticket file in the main checkout
ticked where the evidence proves it, the evidence appended under `## Evidence` with the
`Context:` line first, the status line set to `resolved`, the file left uncommitted; then the
worktree and its branch removed. Done when the Ticket reads `resolved` and `git worktree list`
no longer shows the run's worktree, or the step reads `skip: nothing landed` and the Ticket still
reads `claimed`.

**11. Reply.** Written by [reply.md](reply.md). What this Playbook puts in its sections: the
Ticket under the files left uncommitted, and, as the next step, the worktree, its branch, and the
review and the landing as what the developer runs next. Done when the reply is sent with every
section that applies.
