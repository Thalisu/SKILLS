# Playbook: refactoring

A behaviour-preserving reshape of code that already works: a refactor, a rename, an extract, an
inline, a dedupe, a module moved. It runs outside the chain, with no Ticket and no Spec, and the
request in words is the whole input. The pin makes the behaviour contract checkable before any
structure moves, and the commits read subtraction, reshape, cleanup, in that order, so one revert
undoes one slice.

A case no step names is judged by which of these three errors it risks:

- a behaviour change that lands as a refactor: every check stays green because none of them covered
  what moved, or because something outside the repository still uses the old name;
- a pin bent to fit the reshape: a test that writes the present down, an assertion edited, a red
  made green by touching the check instead of the step that caused it;
- movement passed off as improvement: code shifted sideways with the reader's load where it was, or
  a shim, a speculative cleanup or the run's own scaffold left behind in the tree.

The shared parts are in [mechanics.md](mechanics.md), linked from the steps that use them: the
worktree, the protected branch, the gate, the integration, the review, the verification and the
close, with the loop and its test authors in [build-loop.md](build-loop.md) and every stop of the
integration in [conflict-loop.md](conflict-loop.md). The reply is written by [reply.md](reply.md):
five parts, and every line a step records for the Run report reaches a file under `--auto` alone.

`<skill-dir>`, in the commands those references give, is the folder that holds this file's
`references/`: `${CLAUDE_SKILL_DIR}` in Claude Code, the `do` folder under the harness's skills
directory elsewhere.

## Questions and stops

The run asks and stops only where a step says so. This section is an index: the step named
carries the rule in full.

The run asks the developer in these places and no other:

| Step | The question |
|---|---|
| 1 | which of two homes, when the request fits both equally |
| 2 | on a resume, whether the uncommitted changes in the worktree are discarded |
| 3 | whether a harness that cannot stay inside its bound runs |
| 8 | whether the branch is reverted, when the exit test failed |
| 13 | whether a full suite or a remote run runs |

The questions of steps 1 and 8 are the two this Playbook raises of its own; the other three are
yeses the shared references reserve to the developer. Under `--auto` the `choice-taker` rules the
questions of steps 1, 3 and 13 (the two homes, the harness outside its bound, the full suite or
remote run), and the questions of steps 2 and 8 (the discard and the revert) are still asked of the
developer, with the `choice-taker`'s return shown above each.
Read [refactoring-auto.md](refactoring-auto.md) when the run carries `--auto` and reaches one of
these questions.

The run stops, in one message or as blocked, in these places:

- step 1, on a request that asks for a behaviour change;
- step 3, on a suite or a typecheck that was red before the first edit;
- step 4, on a second deviation of the same shape from the sketch;
- step 4 or step 6, on an Extreme fork or on a Design fork no `choice-taker` ruled, per
  [Forks](#forks);
- steps 10 to 14, on the stops [mechanics.md](mechanics.md) names for the gate, the integration,
  the review, the verification and the close.

Everything else the run settles itself and carries on, in the same turn:

| What the run meets | What it does | Step |
|---|---|---|
| the pin red under a deletion or a reshape step | undoes it and takes it smaller | 5, 6 |
| the harness's output differing from its run on the old code | undoes the last step until the two agree | 6, 7 |
| an empirical fork or a Design fork | settles it by [Forks](#forks) | 4, 6 |
| a behaviour change found on the way | leaves it out and names it in the reply with its command | 1, 6, 9 |
| a red gate | takes one more step of the reshape, then the whole gate again | 10 |
| `not landed: target moved` | integrates again and lands through the fix call | 12 |
| a red flow | fixes it in the worktree and hands the branch to the fix call | 13 |

## Steps

Copied verbatim into the run as its todo list before any task-specific item; each step is ticked
with its done line or stays visible as `skip: <reason>`, and the Run report's Run section carries the
checklist so ticked:

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
10. gate: the run's own tests, the typecheck, the lint and the format in the worktree, and the full suites gate-suites.sh prints with no argument
11. integration: the branch rebased onto the developer's branch, the gate again when it replayed
12. review: do-code-review on the branch's diff, landed when Green
13. verification: the affected flows from the main checkout
14. close: the worktree and its branch removed
15. reply: by the reply reference
```

### 1. Door

Four checks, before any edit and in this order.

1. **A behaviour change.** The request asks for something a caller or a user observes to change: a
   wrong value made right, a missing case added, a message reworded, a default or a threshold moved,
   a new capability. The run refuses it. The refusal ends the run in one message: the first
   line, the reason, and the door the request goes to with the command to type, nothing written.
   The door is `/do` with the bug in words for a defect, and `/discuss <the request>` for a feature,
   or `/spec` when the conversation already holds the discussion. The refusal carries no `Yours:`
   line, per [reply.md](reply.md).

   A reshape whose request also asks for a behaviour change is not refused. It is taken as the
   reshape alone, and the behaviour change is named in the reply as step 9 names one found on the
   way.

   <examples>
   <example>
   `extract the price rounding out of checkout into its own module`: a reshape. Every caller gets
   the totals it got before, and the pin holds the run to that.
   </example>
   <example>
   `inline the wrapper around the HTTP client, it has one caller`: a reshape. Nothing crosses a
   boundary, so the pin's target-interface test reads its skip.
   </example>
   <example>
   `dedupe the two date parsers and make the merged one accept week dates`: taken as the dedupe
   alone. Accepting a new format is a behaviour change, named in the reply with
   `/discuss <the behaviour change>`.
   </example>
   <example>
   `simplify the name validation so empty names stop being rejected`: refused. A caller observes a
   different result, whatever the request calls it, so it goes to `/do` with the bug in words or to
   `/discuss`.
   </example>
   </examples>

2. **The target files and every caller.** The target files are named from the request's words and
   found by search; when the words do not pin a file, the run searches by the likely names and reads
   the candidates. Every caller of every name the reshape moves or deletes is inventoried now
   (`rg -n -w <name>` over the project, strings and prose included), for step 6 to migrate in one
   wave. A choice between two homes the request fits equally is asked of the developer; everything
   else is settled by a search. Under
   `--auto` the `choice-taker` rules that choice, and the run takes the home the Ruling names.
   Read [refactoring-auto.md](refactoring-auto.md) when the run carries `--auto` and meets it.
3. **The discover batch.** The names the reshape will create (the extracted module, the new type,
   the registry) are checked before the first of them exists, the way the Discovery rule fixes: one
   `discover` batch for two or more names, one `rg -n -w` for a single one. A name that comes back
   FOUND is reused rather than created, and the audit line,
   `Discovery: n FOUND · n DUPLICATE · n NOT_FOUND`, is recorded for the Run report's Run section, which
   carries it after the checklist per [reply.md](reply.md).
4. **The branch.** The protected branch in [mechanics.md](mechanics.md), as a warning and not a
   refusal: the run builds to the gate, and the review refuses the landing at step 12.

Then, still before any edit, the run records these lines for the Run report's Run section, in the order
[reply.md](reply.md) fixes. The Run report carries them under `--auto`:

- `Playbook: refactoring`, as plain text on the first line, which also opens the message.
- The reshape confirmed back in one line, with the target files named, the same files the Run
  section carries again on their own line before the audit line.
- Done as a predicate: the pin green before and after, the target shape reached, every caller
  migrated and the old API gone, and the gate green in the worktree after the last edit.
- The loop line: `Loop: policy` when `.claude/agents/unit-test-author.md` exists in the project,
  `Loop: fallback` otherwise. Under `fallback` the pin's target-interface test and the build loop of
  [build-loop.md](build-loop.md) read [tdd-fallback.md](tdd-fallback.md), and the run writes that
  test itself with no test author dispatched; under `policy` that file is never read.
- The protected-branch warning when it applies: the branch, the rule, and the line saying landing
  will be refused on it.
- The checklist above, verbatim, copied as the run's todo list. The Run report's Run section carries it
  after the lines above, each step the run reached ticked `done:` or reading `skip: <reason>`.

There is no claim line and no Ticket: the branch and its commits are the whole state. The run
proceeds without a yes.

Done when the four checks ran, and the read-back, the predicate, the loop line, the warning when it
applies, the target files and the audit line are recorded for the Run report's Run section.

### 2. Worktree

The worktree in [mechanics.md](mechanics.md), created from the current HEAD on `do/<slug>`, where
`<slug>` is the request's slug, excluded locally, entered with a bare `cd`.

The step probes before it creates, `git worktree list` and `git branch --list do/<slug>`. An entry
in either is an earlier run of this request, and the resume below takes the step over.

#### Resume

A second run on a request whose `do/<slug>` worktree or branch already exists continues that run
and never starts a second. The state a resume reads is the branch and its worktree alone, never a
run-state file: the entry of `git worktree list` on `do/<slug>`, then `git branch --list do/<slug>`
when no entry is there, the commits since the branch the first run started from
(`git log <base>..refs/heads/do/<slug>`, with `<base>` the merge base of the developer's branch and
`refs/heads/do/<slug>`, qualified so a same-named tag can never shadow the branch), read by their
titles, and `git status --short` in the worktree.

- An existing worktree is entered with a bare `cd`, never created again. An existing branch with no
  worktree gets its worktree back on that branch, `git worktree add .claude/worktrees/do-<slug>
  do/<slug>`, without `-b`.
- Step 1 ran before this step on the resume as on a first run, so its lines are recorded again from
  the request. The run records the resume line for the Run report's Run section, per
  [reply.md](reply.md): it says the run resumed, names the worktree and its branch, and lists the
  commits found, one line each with its title.
- The run continues at the first step the branch does not evidence, every step before it ticked
  `done: resumed`:
  - no commit: step 3, the pin taken from the start;
  - a subtraction commit, `refactor(<scope>): subtract <what went>`, reshape commits
    `refactor(<scope>): <the step>` after it, or reshape commits alone where step 5 read its skip:
    step 6, from the last reshape commit, step 5 ticked `done: resumed` when the subtraction commit
    is there and its skip otherwise. Before the next edit the run restates step 4's target
    shape, from the Sketch at `.scratch/sketches/<the branch, each slash a dash>.md` when step 4
    filed one, with no `sketch` forked again, and runs the pin on the branch's tip; the harness's
    run on the old code, which the Run report quotes, is taken again from a worktree at the fixed
    point, the way step 7's equivalence script takes the old artifact. Step 6's done condition is
    checked first, so a reshape that already reached its target shape goes on to step 7;
  - the cleanup commit, `chore(<scope>): clean up after the reshape`: step 10, since step 9 runs
    only once the exit test passed or the developer said no to the revert.
- A Review of the branch, `.scratch/reviews/<the branch, each slash a dash>.md` in the main
  checkout, evidences the review step only when it read this branch and finished: the commit its
  `Commit:` header names is one the branch has been at, `git log -g --format=%H
  refs/heads/do/<slug>`; it is not reachable from the commit the
  branch was created at, the oldest entry of that reflog; and none of its Axis lines reads
  `not run`. On any other Review there, the review runs as on a first run.
- Uncommitted changes in the worktree are asked about before they are discarded. The question is
  the turn's final message: it says the run resumes, names the worktree and its branch, and names the changes one line per file from
  `git status --short`. A yes discards them, `git restore --staged --worktree .` then
  `git clean -fd` in the worktree; a no stops the run with the worktree as it is, the blocker's
  line naming it and its branch, and hands the changes over as work the run did not make:
  `Yours: destroy: discard the uncommitted changes in <worktree>, or commit or move them yourself, then type the request again`.
  Under `--auto` that question is still asked of the developer, in
  the same words, with the `choice-taker`'s return shown above it and nothing discarded on that
  return. Read [refactoring-auto.md](refactoring-auto.md) when the run carries `--auto` and meets
  uncommitted changes.
- A run that stopped as blocked resumes the same way once its reason is gone.

The run continues at the first step its branch does not evidence, and a Review that counts decides
the jump, not the cleanup commit: a branch carrying one resumes at step 11 whether or not step 9
left a cleanup commit. It integrates again and lands through the fix call on that Review, with no
**Gate** of the run's own and never a second review.

Done when its status prints nothing and the worktree line, its path and its branch, is recorded for
the Run report's Run section, or the resume line is.

### 3. Pin

The pin is what the reshape is held against, and it is in place before any structure moves. It has
two halves:

| Half | Part | Applies when | Its state until step 6 reaches the target shape |
|---|---|---|---|
| the old behaviour | the suite and the typecheck | always | green |
| the old behaviour | the equivalence harness | the reshaped behaviour has no coverage | its output equal to its run on the old code |
| the new shape | the target-interface test | the refactor extracts or moves something | red, for its declared reason |

No characterisation test enters the tree: no test asserts the code's present behaviour.

#### The suite and the typecheck

Run in the worktree before the first edit, the command line and the relevant output line quoted in
the Run report's Evidence. The commands come from the project's facts, the way the gate in
[mechanics.md](mechanics.md) reads them.

Red here stops the run in one message naming `test-triage` with the command `/test-triage <test file>`, and nothing is
written. The worktree and its branch stay, named, for the resume:
`Yours: direction: make <test file> green with /test-triage <test file>, then type the request again to resume in <worktree>, or leave do/<slug> in its worktree`.

#### The harness

Where the reshaped behaviour has no coverage, the run writes an equivalence harness itself. A reshape whose behaviour the suite
already covers reads `skip: the suite covers the reshaped behaviour`.

The harness is a script outside the test tree, in the worktree, that drives the real artifact over
the inputs the reshape touches and prints what comes back. It is not a test and never enters the
test tree. Its life runs through four steps:

1. Here, it runs on the old code and its output is quoted in the Run report's Evidence.
2. Steps 5 and 6 run it after every change, beside the suite and the typecheck.
3. Step 7 runs it on the new code, its output quoted beside the first run.
4. Step 9 deletes it and names the gap it covered as debt in the reply.

Inside this bound the harness runs unasked, as often as steps 3, 5, 6 and 7 call for it:

- in-process code only;
- no network call and no database;
- no read or write on the filesystem outside the worktree;
- no credential read from the environment;
- every input the harness drives written into the script itself.

A behaviour that cannot be driven inside that bound (a mailer, a payments client, a migration
runner, anything that reads a credential to do its work) is not driven anyway. The run shows the
harness's command line first and waits for the same yes [mechanics.md](mechanics.md) requires
before a remote run. A no
leaves this part reading `skip: the behaviour cannot be driven inside the harness's bound`, and the
gap the harness would have covered is named as debt in the reply the same way step 9 names one.
Under `--auto` the `choice-taker` rules that yes.
Read [refactoring-auto.md](refactoring-auto.md) when the run carries `--auto` and reaches it.

#### The target-interface test

When the refactor extracts or moves something, the new shape is pinned by one test on the target
interface, written by the test authors in [build-loop.md](build-loop.md) and dispatched with the
complete input:

- the behaviour to prove;
- the target interface's callers as who relies on it;
- the target the request names;
- origin `new feature`;
- an unresolved import of the target interface as the expected red.

The step waits for `RED_AS_EXPECTED`; step 6 turns the test green. Its expectation comes from the
target shape's contract and never from the code being moved. Under `Loop: fallback` the run writes
that test itself by [tdd-fallback.md](tdd-fallback.md) and dispatches nobody.

When the request does not settle the target interface, step 4's sketch settles it first and the
test follows the sketch. The suite, the typecheck and the harness still come before any structure
moves.

A reshape that moves nothing across a boundary, an inline or a dedupe inside one module, has no
target interface, and this part reads `skip: nothing extracted or moved`.

#### What "the pin green" means from here on

Steps 5 and 6 run the pin after every change: the suite and the typecheck, with their output lines
quoted, and the harness where this step wrote one. The pin is green when the suite and the
typecheck are green and the harness prints what it printed on the old code.

The target-interface test is the one red those steps tolerate, since it fails by design, for the
reason this step declared, until step 6 reaches it. The single-file command from the project's
facts, run on that test's file, is what separates it from a real red, and a suite whose only
failing file is that one counts as green. A red anywhere else, or a second failing file, is a real
red.

#### What this step commits

Nothing. Neither the test file nor the harness is committed here. Both ride in the subtraction
commit of step 5, the test still red. Where step 5 reads its skip, both ride in the first reshape
commit instead.

Done when the suite's and the typecheck's output lines are quoted, the harness's run on the old code
is quoted or that part reads its skip, and the target-interface test is red for its declared reason
or that part reads its skip.

### 4. Structure

Name the structure the code is missing, then state the target shape as if built today, per
[foundational-thinking](../../../.agents/principles/foundational-thinking.md) and
[model-the-domain](../../../.agents/principles/model-the-domain.md): a state machine over
scattered booleans, a registry over spread-out branching, a typed model over repeated shape
assumptions, a reducer over a chain of mutations. The structure is the rule the code enforces, held
in one place, so the reshape deletes branches instead of adding indirection.

The target shape is stated as the code would look if this behaviour were built today with what the
project knows now, not as the shortest edit from the code that is there, per
[redesign-from-first-principles](../../../.agents/principles/redesign-from-first-principles.md). It
names the types, the module boundaries and the interface the callers will use.

The reshape crosses a boundary when it adds a new module, an exported function or type other code
will call, or a changed signature. Then the `sketch` agent draws the shape in a window of its own:

- Call the Agent tool with `subagent_type: sketch` and the brief its definition names, filled from
  what the run already holds:
  - what to shape: the reshape as step 1 read it back, with the structure and the target shape
    stated above;
  - the map: the target files and the caller inventory step 1 took;
  - the Digest: `none`;
  - the repository root: the main checkout's absolute path;
  - where the Sketch goes: `.scratch/sketches/<the branch, each slash a dash>.md` under that
    root, as an absolute path, keyed by the branch;
  - the chain's `.agents/` folder: the absolute path `readlink -f <skill-dir>/../../.agents`
    prints.
- The agent writes nothing. It returns the Sketch's text and the shape in one line, and the session
  files that text at the destination, whole and with nothing added, appending the `.scratch/`
  ignore line first when [scratch.md](../../../.agents/scratch.md) owes it. The run records for
  the Run report's Run section what it handed over, in one line, and the Sketch's location with the
  shape it settled, per [reply.md](reply.md).
- Reshape against the Sketch. The sketch is the contract, and it is also what settles step 3's
  target interface when the request did not.
- When `sketch` writes nothing (the Agent tool withheld, no `sketch` among the agents the session
  lists, or a return that is not a usable Sketch), the session shapes the work itself: it states
  the types, the signatures and the module boundaries, and records the shaped-by line with that
  reason. With the Agent tool withheld it also files that
  shape at the same destination, in the
  [Sketch format](../../../.agents/formats/sketch-format.md).
- A deviation from the sketch during the reshape is recorded for the Run report. A second deviation of
  the same shape stops the run as a wrong sketch, the deviations listed, the worktree and its
  branch named:
  `Yours: direction: keep the Sketch's shape or take the deviation's, by editing the Sketch at <its location>, then type the request again to resume in <worktree>`.

Read [refactoring-design-fork.md](refactoring-design-fork.md) when the step meets two target
shapes the request and the code cannot settle, before the shape is recorded.

When no boundary is crossed the step reads `skip: no boundary crossed`, and the missing structure
is still named.

Done when the structure and the target shape, with the sketch or its skip, are recorded for the
Run report's Run section as its structure line, per [reply.md](reply.md), beside the hand-over and
Sketch lines or the shaped-by line where the reshape crossed a boundary.

### 5. Subtract

The first commit of the three deletes, per
[subtract-before-you-add](../../../.agents/principles/subtract-before-you-add.md) and
[laziness-protocol](../../../.agents/principles/laziness-protocol.md): the dead weight the reshape
makes obsolete goes before the new shape arrives. Dead weight is the code with no caller after the target shape is known,
the branch the new structure absorbs, the option nobody passes, the layer with one caller, the
comment that describes code that is gone.

No production code is added here, and the subtraction is the smallest change that reaches the
target: a deletion the target shape does not need goes to the reply's pending debt, never to this
commit.

The pin runs again after the deletion, as step 3 defines it, and the pin still green is the
condition to commit. On red, the deletion is undone and taken smaller.

One commit, staged by path, titled `refactor(<scope>): subtract <what went>`. It carries:

- the deletion;
- step 3's target-interface test, still red there for the reason step 3 declared;
- the harness;
- in its body, the pin's command lines, with the test's red run quoted beside the pin's green
  lines.

Nothing to delete reads `skip: nothing the target shape makes obsolete` and the run goes to step 6
with two commits instead of three.

Done when the subtraction is committed with the pin green, or the step reads its skip.

### 6. Reshape

The second slice, in small steps with the pin green after each one, per
[sequence-verifiable-units](../../../.agents/principles/sequence-verifiable-units.md). A step is as
much of the target shape as can stand on its own: the structure introduced, one group of callers
moved onto it, the old path narrowed. After each step the pin runs again, as step 3 defines it. The
target-interface test turns green in the step that reaches it.

#### Callers and the old API

Every caller of the old API is migrated and the old API deleted in the same wave, per
[migrate-callers-then-delete-legacy-apis](../../../.agents/principles/migrate-callers-then-delete-legacy-apis.md).
The inventory is the one step 1 took. No compatibility shim survives the wave: not a re-export, not
an alias, not a wrapper kept "until the callers move". A caller in another repository the run cannot
reach gets no shim either: it is named in the reply as pending debt with the consumer named.

#### Renames

Every rename is spot-checked in strings and prose, not only in code: log lines, error messages,
fixtures, documentation, comments and test names. `rg -n -w <the old name>` over the project proves
the rename landed, and its empty output is quoted.

The sweep stops at every name the project does not own at run time:

- an environment key or a configuration key a deployment sets;
- a deploy or a CI variable;
- a wire field a client sends or reads;
- a value already persisted in a database, a queue or a cache;
- an export another repository imports.

Renaming one of those is a behaviour change, taken back through the door of step 1: the reshape
keeps the old name, and the reply names the rename with the command that takes it, `/do` with the effect in words for a
defect and `/discuss <the rename>` otherwise.

#### Three reds, each with one answer

- **The pin goes red under a step.** The step is undone and taken smaller, never
  patched forward, and never made green by touching the pin. The one red tolerated is the
  target-interface test, told apart from a real red the way step 3 says.
- **A test goes red under a pure reshape.** It is named in the reply as asserting the
  implementation, and never edited here.
- **The harness disagrees after a step.** The step is undone until it agrees, and what disagreed is
  stated in one line.

Read [refactoring-design-fork.md](refactoring-design-fork.md) when a step meets two shapes step
4's target shape cannot settle.

The steps land as one commit or several, each titled `refactor(<scope>): <the step>` and staged by
path, the body carrying the pin's command lines.

Done when the target shape is reached, the target-interface test is green, `rg -n -w` finds no
caller of the old API and no old name, and the pin is green.

### 7. Prove

Behaviour unchanged, shown on the real artifact and not argued from the diff, per
[prove-it-works](../../../.agents/principles/prove-it-works.md).

- The harness from step 3 runs again on the new code, with the same inputs, and its output is quoted
  beside the run on the old code in the Run report. Where step 3 read its skip, this step reads the
  same skip.
- A large reshape, one that moves behaviour across a module boundary or touches more callers than a
  reader will check by eye, gets an equivalence script: it drives both the old and the new artifact
  over the same inputs, the old one from a worktree at the fixed point or from the harness's recorded
  run, and prints the first difference or nothing. Its output is quoted. A small reshape reads
  `skip: the harness covers the reshaped behaviour`.

Output that differs sends the run back to step 6 with the difference named: the last step is undone
and taken smaller until the two agree. A difference the run decides is correct is split out by
step 9.

Done when the harness's run on the new code is quoted, or the step reads its skip, and the
equivalence script's output is quoted or reads its skip.

### 8. Exit test

One question, answered in one line with the reason: is the reader's load lower than it was, per
[minimize-reader-load](../../../.agents/principles/minimize-reader-load.md)? The two axes are the
layers between a question and its answer, and the state a reader has to hold to follow the code. The
line names which of the two dropped and where: "the caller reads one call instead of walking three
branches", "the status now has one home, so nothing has to be kept in sync". A reshape that only
moved code sideways passes neither axis and fails the test, however much cleaner it looks.

A failure stops the run before the cleanup: the run states why the test failed and asks one
question, whether to revert, which deletes the branch with every commit on it:

- **Yes, revert.** A yes removes the worktree and its branch from the main checkout, with nothing
  landed, and the reply says what was tried and what it cost the reader.
- **No, keep it.** A no continues to the cleanup, the gate, the review and the landing, and the reply
  carries the failed exit test as pending debt.

Under `--auto` the revert question is still asked of the developer, in the same place and the same
words, with the `choice-taker`'s return shown above it as it came back, and the branch is never
reverted on that return. Read [refactoring-auto.md](refactoring-auto.md) when the run carries
`--auto` and the exit test failed.

Step 3's yes for a harness that cannot stay inside its bound and step 13's question before a full
suite or a remote run are the yeses [mechanics.md](mechanics.md) reserves to the developer. Both
are asked whenever the run reaches them, and under `--auto` the `choice-taker` rules both.

Done when the answer and its reason are recorded for the Run report's Run section, with the developer's
answer when the test failed.

### 9. Cleanup

The third and last slice, once the exit test passed or the developer said no.

- A speculative cleanup is reverted before the commit: a rename nobody asked for, a helper extracted
  for a second caller that does not exist, a comment explaining the reshape to a reviewer, a
  formatting sweep over untouched lines, per
  [laziness-protocol](../../../.agents/principles/laziness-protocol.md).
- The harness is deleted, and the gap it covered is named as debt in the reply: which behaviour it
  drove, and that no test in the tree covers it now.
- The equivalence script from step 7 goes the same way.

One commit, staged by path, titled `chore(<scope>): clean up after the reshape`, its body naming the
harness that went and the gap it leaves. Nothing to clean up reads `skip: nothing speculative and no
harness` and the run goes to the gate with two commits.

**A behaviour change the cleanup reveals** (a branch that was wrong before the reshape, a case the
old code silently swallowed) is split out, never smuggled into the reshape. The structural change ships
first against the pin, unchanged, and the reply names the behaviour change with the command that
takes it: `/do` with the bug in words for a defect, and `/discuss <the behaviour change>` for a
feature. The run does not fix it here, per
[fix-root-causes](../../../.agents/principles/fix-root-causes.md).

Done when the cleanup is committed or reads its skip, and a behaviour change found here is recorded
for the Run report's Run section with its command.

### 10. Gate

The gate in [mechanics.md](mechanics.md), in the worktree, after the last edit:

- the unit tests the run added and the ones covering the code it touched;
- the typecheck, the lint and the format check;
- the full suites `scripts/gate-suites.sh` prints with no argument.

The `command=` line is recorded for the Run report's Run section and each relevant output line quoted in
its Evidence.

A red gate is one more step of the reshape, taken as step 6 takes one, and then the whole gate
again; never a skipped test, a weakened assertion or a pin edited to fit.

Done when the suite and the typecheck are green in output produced after the last edit.

### 11. Integration

The integration in [mechanics.md](mechanics.md), with the branch the run started on as the target:
the branch it built on rebased onto that branch, every conflicted hunk classed by
`conflict-class.sh`, per [conflict-loop.md](conflict-loop.md), before anything is resolved, and the gate's command lines run again when the rebase replayed
commits. Every contested hunk takes the **Target** side, and its **Incoming** side goes to the Loss
ledger keyed by the run's branch, `.scratch/ledgers/<branch>.md` in the main checkout. The no-op is
ticked on `integration.sh check`'s `verdict=noop`, and never on an ancestor check of the run's own.

Done when the step reads the no-op, or the target and the count with the tree handed over with no
**Gate** of the run's own, or the run stopped as blocked with the worktree and its branch named.

### 12. Review

The review in [mechanics.md](mechanics.md), called once, with:

- as its spec source, the branch alone;
- as the fixed point, the `fixed_point=` line of
  `integration.sh settle <the worktree> <that branch> <the ledger>`, read after the integration on
  its `verdict=settled`;
- as the landing target, the branch the run started on.

The review writes the Review, fixes its `Act on` Findings through its Fixers, one per Finding, the
Fixers of one Wave at once and each in a worktree of its own, and lands the branch by fast-forward
when the Review is Green. The run fixes no Finding and lands nothing itself.

The return is recorded for the Run report's Run section, one line per part, as the shared section says,
and routed on the `route=` line of `review-route.sh`, with the request that started the run as
`rerun=`. Read [not-landed.md](not-landed.md) when the `route=` line reads anything but
`route=verify`. The five returns are the ones the `ticket` Playbook gets:

- **Landed.** `route=verify`, and the run goes to the verification.
- **Not landed: target moved.** On `route=fix` the run integrates again in the same run, its Loss
  ledger keyed by the branch, judged and reapplied with no **Gate** of the run's own after the last
  reapply, and lands through the fix call on the Review it already has, from the printed lines, as
  the review in [mechanics.md](mechanics.md) says, never a second review, with no fixed count. On
  `route=resume`, right after an integration that ticked as a no-op, the run takes step 2's resume
  in the same run: the Review it already has counts, so it integrates again and lands through the
  fix call on that Review.
- **Not landed**, on `route=blocked`. The run stops as blocked with the `reason=` line quoted, the
  worktree and its branch left in place and named in the reply, nothing half fixed, and the reply's
  `Yours: direction:` line carrying the choice, as the review in [mechanics.md](mechanics.md) says.
- **`do-code-review` not listed.** The step reads `skip: do-code-review not listed`, nothing lands,
  and the reply's Next step is `scripts/next-step.sh`'s stdout on `outcome=unlanded`, piped with
  `worktree=` and `run_branch=`.
- **A protected branch.** The review refuses the landing, whatever the run wrote, and the run
  stops as blocked with the landing handed over under `direction`, as the review in
  [mechanics.md](mechanics.md) says: `route=blocked` with `direction=protected`, the reply's
  `Yours: direction:` line the printed `yours=` line, and the two printed `by_hand=` lines the
  commands that land the reviewed branch by hand from a branch that takes commits, which the run
  types neither of.

Done when the return is recorded for the Run report's Run section with its landing line reading
`landed at <commit>`, or the run stopped as blocked with the review's reason quoted, or the step
reads its skip with the worktree and its branch named.

### 13. Verification

The verification in [mechanics.md](mechanics.md), from the main checkout after the landing:

- the affected flows run with the command line printed first;
- the one question is asked before a full suite or a remote run, and under `--auto` the
  `choice-taker` rules it. Read [refactoring-auto.md](refactoring-auto.md) when the run carries
  `--auto` and reaches it;
- a red flow is taken as one more step of the reshape, handed with no **Gate** of the run's own to
  the fix call on the same Review, which lands it again with no second review.

A reshape whose diff changed no screen, route or message has no affected flow, and the step reads
`skip: no affected flow` with that reason.

Done when every affected flow is green or recorded as not run on the developer's no, or the step
reads `skip: nothing landed`.

### 14. Close

The close in [mechanics.md](mechanics.md). Outside the chain there is no Ticket, so the close is the
worktree's removal alone: leave it with a bare `cd` to the main checkout, then `git worktree remove
<path>` and `git branch -d do/<slug>` from there. A delete that refuses stops the run with the worktree and its branch named.

Done when `git worktree list` no longer shows the run's worktree, or the step reads
`skip: nothing landed`.

### 15. Reply

Written by [reply.md](reply.md), its five parts: the `Plan:` line reads the reshape back in a few
words, and For whom names the reader whose load dropped. Pending debt carries, on every run, each
of these that the run met:

- the equivalence gap: the behaviour the harness drove and that no test in the tree covers now;
- a caller in another repository the wave could not reach;
- a test that went red under a pure reshape and was named rather than edited;
- a failed exit test the developer chose to keep;
- a Design fork's Ruling. Read [refactoring-design-fork.md](refactoring-design-fork.md) when the
  run met a Design fork the `choice-taker` ruled, for the line that carries it.

Under `--auto` the Run report carries the rest, each where [reply.md](reply.md) puts it:

- In the Run section, the structure line: the structure the reshape gave the code, the one step 4
  named, and the target shape it reached, with the sketch or its skip.
- In the Run section, the answer lines: the exit test's answer with its reason, and the developer's
  answer when it failed.
- Under Commits, the commits in order, subtraction, reshape, cleanup, each with its short sha, so a
  reader sees that one revert undoes one slice.
- Under `Rulings`, `On the Spec: none`, and in the `On the run:` group each Design fork's Ruling
  and each Ruling made under `--auto` on the questions of steps 1, 3 and 13, or `none`.
- Under Evidence, the pin's before and after lines quoted, the suite, the typecheck and the
  harness's two runs.

The reply ends with the push command naming the developer's branch when the review landed, and with
the next command otherwise.

Done when the reply is sent with every section that applies.

## Forks

This Playbook reads no fork reference of the `ticket` Playbook and none of another Playbook. A
question the run meets is classified before it is asked, and its class decides who settles it:

| The question | Settled by | The run |
|---|---|---|
| Empirical fork: a fact a script can observe (which timing, which output, whether an API does the thing) | a throwaway probe script in the worktree, deleted before the commit | carries on |
| Design fork: two shapes step 4's target shape and the code cannot settle, each keeping every guarantee whole | the `choice-taker` | carries on |
| Extreme fork: a Design fork with a side that weakens a guarantee in a risk class (security, privacy, data loss, auth, billing, migration, idempotency, race), or that cannot be undone once landed | the developer, through `/discuss` | stops, blocked |
