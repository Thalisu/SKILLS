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
11. review: do-code-review on the branch's diff, landed when Green
12. verification: the affected flows from the main checkout
13. close: the worktree and its branch removed
14. reply: by the reply reference
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
   questions this Playbook may ask; everything else is a fact a search settles.
3. **The discover batch.** The names the reshape will create (the extracted module, the new type,
   the registry) are checked before the first of them exists, the way the Discovery rule fixes: one
   `discover` batch for two or more names, one `rg -n -w` for a single one. A name that comes back
   FOUND is reused rather than created, and the audit line goes in the thread,
   `Discovery: n FOUND · n DUPLICATE · n NOT_FOUND`.
4. **The branch.** The protected branch in [mechanics.md](mechanics.md). This is a warning and not a
   refusal: the run builds to the gate and the review refuses the landing, as step 11 says.

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
`<slug>` is the request's slug, excluded locally, entered with a bare `cd`. Done when its status
prints nothing and the branch name is in the thread.

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

Done when the suite's and the typecheck's output lines are quoted, the harness's run on the old code
is quoted or the half reads its skip, and the target-interface test is red for its declared reason or
the half reads its skip.
