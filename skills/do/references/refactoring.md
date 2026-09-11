# Playbook: refactoring

A behaviour-preserving reshape of code that already works: a refactor, a rename, an extract, an
inline, a dedupe, a module moved. It runs outside the chain, so there is no Ticket and no Spec, and
the request in words is the whole input. What makes it a Playbook and not an edit is the pin: the
behaviour contract is made checkable before any structure moves, so "refactor" is a claim a reader
can verify instead of a promise. The commits read subtraction, reshape, cleanup, in that order, so
one revert undoes one slice.

The parts it shares with the `ticket` Playbook are in [mechanics.md](mechanics.md), linked from the
steps that use them: the worktree, the protected branch, the build loop with its test authors, the
gate, the review, the verification and the close. The reply is written by [reply.md](reply.md).

`<skill-dir>` below is the folder that holds this file's `references/`: `${CLAUDE_SKILL_DIR}` in
Claude Code, the `do` folder under the harness's skills directory elsewhere.

## Steps

Copied verbatim into the run before any task-specific item; each step is ticked with its done line
or stays visible as `skip: <reason>`:

```
refactoring:
1. door: the reshape judged, the target files and every caller named, the discover batch audited, the branch checked
2. worktree: created from HEAD and entered; tree clean
3. pin: the suite and the typecheck green and quoted; the harness where coverage is missing; the target-interface test red-first
4. structure: the missing structure named, the target shape stated as if built today
5. subtract: dead weight deleted, the pin still green, one commit
6. reshape: small steps with the pin green, every caller migrated, the old API deleted, one or more commits
7. prove: the harness's run on the new code quoted, the equivalence script for a large reshape
8. exit test: reader load lower with the reason, or the one question before the revert
9. cleanup: the speculative cleanup reverted, the harness deleted and its gap named, one commit
10. gate: the full unit suite, the typecheck, the lint and the format in the worktree
11. integration: the branch rebased onto the developer's branch, the gate again when it replayed
12. review: do-code-review on the branch's diff, landed when Green
13. verification: the affected flows from the main checkout
14. close: the worktree and its branch removed
15. reply: by the reply reference
```

### 1. Door

Before any edit, in this order. The refusal ends the run in one message: the first line, the reason,
and the door the request goes to with the command to type, nothing written.

1. **A behaviour change.** The request asks for something a caller or a user observes to change: a
   wrong value made right, a missing case added, a message reworded, a default or a threshold moved,
   a new capability. A reshape leaves behaviour where it was, so a request that moves it has nothing
   for the pin to hold. It goes to `/do` with the bug in words for a defect, and to
   `/discuss <the request>` for a feature, or `/spec` when the conversation already holds the
   discussion. A reshape whose request also asks for a behaviour change is taken as the reshape
   alone, and the behaviour change is named in the reply as step 9 names one found on the way.
2. **The target files and every caller.** Named from the request's words and found by search; when
   the words do not pin a file, the run searches by the likely names and reads the candidates. Every
   caller of every name the reshape moves or deletes is inventoried now (`rg -n -w <name>` over the
   project, strings and prose included), because step 6 migrates all of them in one wave, per
   [migrate-callers-then-delete-legacy-apis](../../../.agents/principles/migrate-callers-then-delete-legacy-apis.md).
   A choice between two homes the request fits equally is a preference call and one of the two
   questions this Playbook raises of its own; everything else is a fact a search settles.
3. **The discover batch.** The names the reshape will create (the extracted module, the new type,
   the registry) are checked before the first of them exists, the way the Discovery rule fixes: one
   `discover` batch for two or more names, one `rg -n -w` for a single one. A name that comes back
   FOUND is reused rather than created, and the audit line goes in the thread,
   `Discovery: n FOUND · n DUPLICATE · n NOT_FOUND`.
4. **The branch.** The protected branch in [mechanics.md](mechanics.md). This is a warning and not a
   refusal: the run builds to the gate and the review refuses the landing, as step 12 says.

Then the first message, before any edit, in this order:

- `Playbook: refactoring`, as plain text on the first line.
- The reshape confirmed back in one line, with the target files named.
- Done as a predicate: the pin green before and after, the target shape reached, every caller
  migrated and the old API gone, and the gate green in the worktree after the last edit.
- The loop line: `Loop: policy` when `.claude/agents/unit-test-author.md` exists in the project,
  `Loop: fallback` otherwise. Under `fallback` the pin's third half and the build loop of
  [mechanics.md](mechanics.md) read [tdd-fallback.md](tdd-fallback.md), and the run writes that test
  itself with no test author dispatched; under `policy` that file is never read.
- The protected-branch warning when it applies: the branch, the rule, and the line saying landing
  will be refused on it.
- The checklist above, verbatim.

There is no claim line and no Ticket: outside the chain the branch and its commits are the whole
state. The run proceeds without a yes, per
[never-block-on-the-human](../../../.agents/principles/never-block-on-the-human.md). Done when the
four checks ran, the target files and the audit line are in the thread, and the first message is
sent.

### 2. Worktree

The worktree in [mechanics.md](mechanics.md), created from the current HEAD on `do/<slug>`, where
`<slug>` is the request's slug, excluded locally, entered with a bare `cd`. The step probes before it
creates: a `do/<slug>` worktree or branch that already exists is an earlier run of this request,
and the Resume of [bug-fix.md](bug-fix.md) takes the step over, the way it reads that state there,
so an existing worktree is entered, a gone one is recreated on the existing branch, and a Review of
the branch that counts lands through the fix call on it, never a second review. The run continues
at the first step its branch does not evidence: a branch carrying its cleanup commit, the one a
`not landed: target moved` return leaves, resumes at step 10. Done when its status prints nothing
and the branch name is in the thread.

### 3. Pin

Before any structure moves, and in two halves, per
[ADR 0014](../../../docs/adr/0014-the-refactoring-pin-never-goes-through-the-test-author.md).
Neither half is a characterisation test: the Testing Policy's test author takes `bugfix` and
`new feature` as its only origins, never derives an expectation from the implementation and needs a
red run first, while a characterisation test is the implementation's present behaviour written down
and born green. So no test that asserts the present enters the tree.

**The old behaviour** is pinned by the existing suite and the typecheck, run in the worktree before
the first edit, the command line shown before it runs and the relevant output line quoted. The
commands come from the project's facts, the way the gate in [mechanics.md](mechanics.md) reads them.
Red here is not this Playbook's to fix: the suite was red before the reshape, so the run stops in one
message naming `test-triage` with the command `/test-triage <test file>`, and nothing is written.

Where the reshaped behaviour has no coverage, the run writes an equivalence harness itself, since a
gap the suite does not cover is a gap the pin does not hold. It is a script outside the test tree, in
the worktree, that drives the real artifact over the inputs the reshape touches and prints what comes
back. It is not a test and never enters the test tree. It runs on the old code now and its output is
quoted; step 7 runs it again on the new code, and step 9 deletes it and names the gap it covered as
debt in the reply. A reshape whose behaviour the suite already covers reads
`skip: the suite covers the reshaped behaviour`.

The harness executes the project's real code in the developer's shell, and no test rule bounds it,
so this step does: in-process code only, no network call, no database, no read or write on the
filesystem outside the worktree, and no credential read from the environment, with every input the
harness drives written into the script itself. Inside that bound it runs unasked, as often as steps
3, 5, 6 and 7 call for it. A behaviour that cannot be driven inside it, a mailer, a payments client,
a migration runner, one that reads a credential to do its work, is not driven anyway: the run shows
the harness's command line first and waits for the same yes [mechanics.md](mechanics.md) requires
before a remote run, since the cost of touching the real system is the developer's to weigh. A no
leaves the half reading `skip: the behaviour cannot be driven inside the harness's bound`, and the
gap the harness would have covered is named as debt in the reply the same way step 9 names one.

**The new shape** is pinned when the refactor extracts or moves something: one test on the target
interface, written by the test authors in [mechanics.md](mechanics.md) and dispatched with the
complete input, the behaviour to prove, the target the request names, origin `new feature`, and an
unresolved import of the target interface as the expected red. The step waits for
`RED_AS_EXPECTED`; step 6 turns it green. Its expectation comes from the target shape's contract and
never from the code being moved. Under `Loop: fallback` the run writes that test itself by
[tdd-fallback.md](tdd-fallback.md) and dispatches nobody. A reshape that moves nothing across a
boundary, an inline or a dedupe inside one module, has no target interface and the half reads
`skip: nothing extracted or moved`.

When the request does not settle the target interface, step 4's sketch settles it first and this half
follows the sketch. The two halves above still come before any structure moves.

Neither the test file nor the harness is committed here. Both ride in the subtraction commit of step
5, the test still red, so that the target interface is pinned in history before the reshape moves
anything onto it and the harness is tracked before step 9 deletes it. Where step 5 reads its skip,
both ride in the first reshape commit instead.

Done when the suite's and the typecheck's output lines are quoted, the harness's run on the old code
is quoted or the half reads its skip, and the target-interface test is red for its declared reason or
the half reads its skip.

### 4. Structure

Name the structure the code is missing, then state the target shape as if built today, per
[foundational-thinking](../../../.agents/principles/foundational-thinking.md) and
[model-the-domain](../../../.agents/principles/model-the-domain.md). The naming is what keeps the
reshape from being movement: a state machine over scattered booleans, a registry over spread-out
branching, a typed model over repeated shape assumptions, a reducer over a chain of mutations. The
structure is the rule the code enforces, held in one place, so the reshape deletes branches instead
of adding indirection.

The target shape is stated as the code would look if this behaviour were built today with what the
project knows now, not as the shortest edit from the code that is there, per
[redesign-from-first-principles](../../../.agents/principles/redesign-from-first-principles.md). It
names the types, the module boundaries and the interface the callers will use.

When the reshape crosses a boundary, a new module, an exported function or type other code will
call, or a changed signature, call the Skill tool with `architect`, stop at the sketch, and reshape
against it. The sketch is the contract, and it is also what settles step 3's target interface when
the request did not. A deviation during the reshape is surfaced in the reply, and a second deviation
of the same shape stops the run as a wrong sketch, the deviations listed, the worktree and its branch
named. When `architect` is not listed, the shape is stated in the thread and the step says so. When
no boundary is crossed the step reads `skip: no boundary crossed` and the missing structure is still
named.

Done when the structure and the target shape are in the thread, with the sketch or its skip.

### 5. Subtract

The first commit of the three deletes, per
[subtract-before-you-add](../../../.agents/principles/subtract-before-you-add.md) and
[laziness-protocol](../../../.agents/principles/laziness-protocol.md): the dead weight the reshape
makes obsolete goes before the new shape arrives, so the reshape moves less code and the diff shows
what was actually removed. Dead weight is the code with no caller after the target shape is known,
the branch the new structure absorbs, the option nobody passes, the layer with one caller, the
comment that describes code that is gone.

No production code is added here. The pin runs again after the deletion, the suite and the
typecheck with their output lines quoted, and the harness where step 3 wrote one. The pin still
green is the condition to commit; red means something was load-bearing, and the deletion is undone
and taken smaller. Green here means the old behaviour half of the pin: step 3's target-interface
test is red by design until step 6 reaches it.

Step 3's target-interface test rides in the subtraction commit, still red there for the reason step 3
declared. That is what puts it in history before the reshape, which is the first commit that moves
structure, so a reader walking the branch sees the target interface asserted before anything was
moved onto it. Its red run is quoted in the commit body beside the pin's green lines. The harness
rides in the same commit, and that is what tracks it: an untracked harness is nothing for step 9 to
delete, and the cleanup commit it promises would have nothing staged.

The subtraction is the smallest change that reaches the target and nothing more: a deletion the
target shape does not need is a second improvement and belongs to the reply's pending debt, never to
this commit. One commit, staged by path, titled `refactor(<scope>): subtract <what went>`, its body
carrying the pin's command lines. Nothing to delete reads `skip: nothing the target shape makes
obsolete` and the run goes to step 6 with two commits instead of three.

Done when the subtraction is committed with the pin green, or the step reads its skip.

### 6. Reshape

The second slice, in small steps with the pin green after each one, per
[sequence-verifiable-units](../../../.agents/principles/sequence-verifiable-units.md). A step is as
much of the target shape as can stand on its own: the structure introduced, one group of callers
moved onto it, the old path narrowed. After each step the pin runs again, the suite and the typecheck
with their output lines quoted, and the harness where step 3 wrote one. The target-interface test
turns green in the step that reaches it, and that is the moment the new shape stops being a plan.

Every caller of the old API is migrated and the old API deleted in the same wave, per
[migrate-callers-then-delete-legacy-apis](../../../.agents/principles/migrate-callers-then-delete-legacy-apis.md).
The inventory is the one step 1 took. No compatibility shim survives the wave: not a re-export, not
an alias, not a wrapper kept "until the callers move", because the callers moved. A caller the run
cannot reach, in another repository, is not a shim's excuse; it is named in the reply as pending debt
with the consumer named.

Every rename is spot-checked in strings and prose, not only in code: log lines, error messages,
fixtures, documentation, comments and test names. A compiler and a typechecker do not read those, so
`rg -n -w <the old name>` over the project is what proves the rename landed, and its empty output is
quoted.

The sweep stops at every name the project does not own at run time: an environment key or a
configuration key a deployment sets, a deploy or a CI variable, a wire field a client sends or reads,
a value already persisted in a database, a queue or a cache, an export another repository imports.
Something outside the repository writes or reads those, and no instrument of the pin can see it,
since the suite, the typecheck and the harness all supply their own environment. All three stay
green while the deployment goes on setting the old name and the code now reads the new one, which is
how a renamed flag switches a check off with nothing to show for it. Renaming one of those is a
behaviour change, so it goes back through the door of step 1: the reshape keeps the old name, and
the reply names the rename with the command that takes it, `/do` with the effect in words for a
defect and `/discuss <the rename>` otherwise.

Three reds, each with one answer:

- **The pin goes red under a step.** The step did too much. It is undone and taken smaller, never
  patched forward, and never made green by touching the pin. The one red this step tolerates is
  step 3's target-interface test, still failing for the reason step 3 declared: until the step
  that reaches it, the reshape tolerates exactly one red and that is it. The single-file command
  from the project's facts, run on that test's file, is what separates it from a real red, and a
  suite whose only failing file is that one counts as green here. A red anywhere else, or a second
  failing file, is a real red and the step is undone.
- **A test goes red under a pure reshape.** It was asserting the implementation and not the
  behaviour. It is named in the reply and never edited here, since a test that describes behaviour
  survives a reshape by construction; editing it would erase the one signal that the reshape changed
  something.
- **The harness disagrees after a step.** Behaviour changed. The step is undone until it agrees, and
  what disagreed is stated in one line.

The steps land as one commit or several, each titled `refactor(<scope>): <the step>` and staged by
path, the body carrying the pin's command lines. Done when the target shape is reached, the
target-interface test is green, `rg -n -w` finds no caller of the old API and no old name, and the
pin is green.

### 7. Prove

Behaviour unchanged, shown on the real artifact and not argued from the diff, per
[prove-it-works](../../../.agents/principles/prove-it-works.md). "The suite is green" is the pin's
half, not the whole proof: the suite covers what it covered before, and the harness exists because
that was not everything.

- The harness from step 3 runs again on the new code, with the same inputs, and its output is quoted
  beside the run on the old code so a reader compares the two lines without leaving the reply. Where
  step 3 read its skip, this step reads the same skip.
- A large reshape, one that moves behaviour across a module boundary or touches more callers than a
  reader will check by eye, gets an equivalence script: it drives both the old and the new artifact
  over the same inputs, the old one from a worktree at the fixed point or from the harness's recorded
  run, and prints the first difference or nothing. Its output is quoted. A small reshape reads
  `skip: the harness covers the reshaped behaviour`.

Output that differs means behaviour changed, and the run goes back to step 6 with the difference
named: the last step is undone and taken smaller until the two agree. A difference the run decides is
correct is not a refactor at all, and it is split out by step 9.

Done when the harness's run on the new code is quoted, or the step reads its skip, and the
equivalence script's output is quoted or reads its skip.

### 8. Exit test

One question, answered in one line with the reason: is the reader's load lower than it was, per
[minimize-reader-load](../../../.agents/principles/minimize-reader-load.md)? The two axes are the
layers between a question and its answer, and the state a reader has to hold to follow the code. The
line names which of the two dropped and where: "the caller reads one call instead of walking three
branches", "the status now has one home, so nothing has to be kept in sync". A reshape that only
moved code sideways passes neither axis and fails the test, however much cleaner it looks.

A failure stops the run before the cleanup, because the answer is to revert and the revert deletes
the branch with every commit on it. That is irreversible, so the run states why the test failed and
asks one question, the second and last this Playbook raises of its own:

- **Yes, revert.** A yes removes the worktree and its branch from the main checkout, with nothing
  landed, and the reply says what was tried and what it cost the reader.
- **No, keep it.** A no continues to the cleanup, the gate, the review and the landing, and the reply
  carries the failed exit test as pending debt so the next reader knows the claim was not met.

A yes that [mechanics.md](mechanics.md) reserves to the developer is not one of the two and is never
waived here: step 3 carries one when the harness cannot stay inside its bound, and step 13 carries
the question before a full suite or a remote run. Both are asked whenever the run reaches them.

Done when the answer and its reason are in the thread, with the developer's answer when the test
failed.

### 9. Cleanup

The third and last slice, once the exit test passed or the developer said no.

- A speculative cleanup is reverted before the commit: a rename nobody asked for, a helper extracted
  for a second caller that does not exist, a comment explaining the reshape to a reviewer, a
  formatting sweep over untouched lines. The target shape earns its place; a guess does not, per
  [laziness-protocol](../../../.agents/principles/laziness-protocol.md).
- The harness deleted, since it was a scaffold and never a test, and the gap it covered named as debt
  in the reply: which behaviour it drove, and that no test in the tree covers it now. That is the
  honest cost of the pin's second half, and it is stated rather than carried silently. It has been
  tracked since the subtraction commit, so this is a staged deletion and the commit below carries it.
- The equivalence script from step 7 goes the same way.

One commit, staged by path, titled `chore(<scope>): clean up after the reshape`, its body naming the
harness that went and the gap it leaves. Nothing to clean up reads `skip: nothing speculative and no
harness` and the run goes to the gate with two commits.

**A behaviour change the cleanup reveals.** Deleting the scaffold sometimes exposes something that
was never behaviour-preserving: a branch that was wrong before the reshape, a case the old code
silently swallowed. It is split out, never smuggled into the reshape. The structural change ships
first against the pin, unchanged, and the reply names the behaviour change with the command that
takes it: `/do` with the bug in words for a defect, and `/discuss <the behaviour change>` for a
feature. The run does not fix it here, per
[fix-root-causes](../../../.agents/principles/fix-root-causes.md): a defect gets its own reproduction
and its own red-first fix, which this Playbook's pin is the wrong instrument for.

Done when the cleanup is committed or reads its skip, and a behaviour change found here is named in
the thread with its command.

### 10. Gate

The gate in [mechanics.md](mechanics.md), in the worktree, after the last edit: the full unit suite,
the typecheck, the lint and the format check, each command line shown and its relevant output line
quoted. A red gate is one more step of the reshape, taken as step 6 takes one, and then the whole
gate again; never a skipped test, a weakened assertion or a pin edited to fit. Done when the suite
and the typecheck are green in output produced after the last edit.

### 11. Integration

The integration in [mechanics.md](mechanics.md), with the branch the run started on as the target:
the branch it built on rebased onto that branch, every conflicted hunk classed by the door script
before anything is resolved, and the gate's command lines run again when the rebase replayed
commits. Done when the step reads the no-op, or the target and the count with the gate green after
it, or the run stopped as blocked with the worktree and its branch named.

### 12. Review

The review in [mechanics.md](mechanics.md), called once, with the branch alone as its spec source
since there is no Ticket outside the chain, the merge base of the branch and the branch the run
started on, `git merge-base refs/heads/<that branch> HEAD`, qualified so a same-named tag can never
shadow the branch, read after the integration as the fixed point, and
the branch the run started on as the landing target. The review writes the Review, fixes
its `Act on` Findings through its Fixers, one per Finding, and lands the branch by fast-forward
when the Review is Green. The run fixes no Finding and lands nothing itself.

The thread shows the return, one line per part, as the shared section says. The four returns are the
ones the `ticket` Playbook gets:

- **Landed.** The line reads `landed at <commit>` and the run goes to the verification.
- **Not landed**, for any reason the review gives. The run stops as blocked with the reason quoted,
  the worktree and its branch left in place and named in the reply, nothing half fixed.
- **`do-code-review` not listed.** The step reads `skip: do-code-review not listed`, nothing lands,
  and the reply names the worktree, its branch and the review as the developer's next step.
- **A protected branch.** The review refuses the landing, as the first message warned it would, and
  the reply adds the two commands that land the reviewed branch by hand from a branch that takes
  commits:

```
git switch <a branch that takes commits>
git merge --ff-only do/<slug>
```

Done when the landing line reads `landed at <commit>`, or the run stopped as blocked with the
review's reason quoted, or the step reads its skip with the worktree and its branch named.

### 13. Verification

The verification in [mechanics.md](mechanics.md), from the main checkout after the landing: the
affected flows with the command line printed first, the one question before a full suite or a remote
run, and a red flow taken as one more step of the reshape, gated and handed to the fix call on the
same Review, which lands it again with no second review. A reshape whose diff changed no screen,
route or message
has no affected flow, and the step reads `skip: no affected flow` with that reason. Done when every
affected flow is green or recorded as not run on the developer's no, or the step reads
`skip: nothing landed`.

### 14. Close

The close in [mechanics.md](mechanics.md). Outside the chain there is no Ticket, so the close is the
worktree's removal alone: leave it with a bare `cd` to the main checkout, then `git worktree remove
<path>` and `git branch -d do/<slug>` from there. A delete that refuses means something did not land,
and the run stops with the worktree and its branch named. Done when `git worktree list` no longer
shows the run's worktree, or the step reads `skip: nothing landed`.

### 15. Reply

Written by [reply.md](reply.md), with these lines before its sections, in this order:

- It names the structure the reshape gave the code, the one step 4 named, and the target shape it
  reached.
- The commits in order, subtraction, reshape, cleanup, each with its short sha, so a reader sees that
  one revert undoes one slice.
- The pin's before and after lines quoted, the suite, the typecheck and the harness's two runs. Those
  quoted lines are the harness's only record, since step 9 deleted it, so a line missing here is a
  proof nobody can reproduce.
- The equivalence gap as debt: the behaviour the harness drove and that no test in the tree covers
  now.

Then the reply reference's sections in their order. Under pending debt: that gap, a caller in another
repository the wave could not reach, a test that went red under a pure reshape and was named rather
than edited, and a failed exit test the developer chose to keep. The reply ends with the push command
naming the developer's branch when the review landed, and with the next command otherwise. Done when
the reply is sent with every section that applies.
