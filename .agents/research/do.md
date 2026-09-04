# /do: research and design brief

Research only. Nothing under `skills/` was written for `/do` yet. This brief records what was read,
what each source gives the skill, where the sources contradict each other, and the decisions taken
in the research session of 2026-09-03. It is the input for authoring `skills/do/SKILL.md`, its docs
page and its evals. Two steps carry a `TBD` slot for skills this repo does not have yet, `code-review` and
`bug-fix`. Authoring either one later replaces its slot instead of reopening the design.

## What /do is

`/do` builds one decided unit of work. The unit is a ticket that `/tickets` produced, and
nothing else: the chain is strict
(`docs/adr/0003`). The run creates a git worktree from the branch the user is on and
builds behaviour by behaviour under the project's Testing Policy, one green commit per behaviour.
It then reviews and fixes, lands the worktree branch on the user's branch without touching the
network, runs the E2E gate from the main checkout, and closes the ticket with the evidence.

Two constraints define it. It never reopens the plan: no interview, no alternative approach, and a
design fork the repository cannot settle stops the run and sends the user back to `/discuss`. And it
never claims done without the Definition of Done evidence, produced after the last edit and quoted.

It ends one chain: `/discuss`, then `/spec`, then `/journey` when the spec's verdict requires it,
then `/tickets`, then `/do` once per ticket with
the context cleared between tickets. The second chain this brief once carried, `/discuss` then
`/do` in the same session for small work, was dropped on 2026-09-04: `/do` never runs before
`/tickets` (`docs/adr/0003`).

## Sources read

| Source | Where | What was read |
|---|---|---|
| mattpocock-skills 1.2.3 | the Claude Code plugin cache | `implement`, `implement-spec` (in-progress bucket), `tdd` with `tests.md` and `mocking.md`, `code-review`, `codebase-design` with `DEEPENING.md` and `DESIGN-IT-TWICE.md`, `to-tickets`, `to-spec`, `setup-matt-pocock-skills` with its tracker templates, `writing-for-agents` with `SKILL-MECHANICS.md`, `ask-matt`, `diagnosing-bugs`, and the docs page `docs/engineering/implement.md` |
| pstack | `github.com/cursor/plugins`, directory `pstack/`, commit `7314f723a487ec406b6369fe5865ba034cfed166`, the same commit the principles in `.agents/principles/` were adapted from | `skills/poteto-mode/SKILL.md` and its playbooks `feature`, `bug-fix`, `refactoring`, `opening-a-pr`, `multi-phase-plan`, `prototype`, `investigation`; `skills/tdd`, `architect`, `figure-it-out`, `blast-radius`, `show-me-your-work`, `no-comments`; `agents/poteto-agent.md`; guide pages 02, 05, 06, 08, 09 and 10 |
| This repo | `skills/`, `.agents/` | `testing-policy` (POLICY.md 2.3, AGENT-UNIT.md, SKILL-TEST-AUTHOR.md, SKILL.md), `test-triage`, `discover`, `discuss` with the uncommitted `prototype` wiring, `.agents/invocation.md`, `.agents/writing-docs.md`, every principle |
| Vendored pstack skills on the maintainer's machine | `~/.claude/skills/` | `architect`, `how`, `why`, `teach`, `unslop`, `technical-writing` and `typescript-best-practices` are model-invoked there; `no-comments` stays user-invoked; `PSTACK-README.md` lists the local changes |
| GSD-era skills on the maintainer's machine | `~/.agents/skills/` | `verify-before-complete`, `decompose-into-slices`, `design-an-interface`, `diagnose`, read for overlap only |

## What each source gives /do

### mattpocock implement

The five-line skill is the spine. One unit of work per run, with the context cleared between
tickets. Typecheck and single test files run continuously, the full suite once at the end. The
plan is never reopened.

Its docs page names the gaps, and `/do` closes each one:

| Gap in `implement` | What `/do` does instead |
|---|---|
| Nothing inside the skill agrees the seams, so "pre-agreed" degrades to "just write the code" | The behaviours list written from the ticket before the first cycle is the agreement (step 4) |
| Review runs before the commit, so the review sees an empty diff | One commit per behaviour lands first; the review reads the branch (steps 5 and 8) |
| "The spec or tickets" sends the model hunting for a file when the plan lives in the thread | Step 0 takes a ticket only; a plan that lives in the thread is sent to `/spec` (amended 2026-09-04, `docs/adr/0003`) |
| It never ticks acceptance criteria or closes the ticket | Step 10 ticks what was proven and closes with the evidence |
| A bare `#2` resolves against any numbered list in context | An issue number resolves only through `docs/agents/issue-tracker.md`; otherwise it is asked |

Left out: `implement-spec`, the task graph with implementer subagents in worktrees and a merger
subagent. It contradicts the Testing Policy, which runs the test authors in place and serialises
shared-asset creation, and mattpocock's own field report describes two parallel sessions corrupting
each other's commits and stash.

### mattpocock tdd and codebase-design

Taken: the vocabulary (module, interface, seam, adapter, depth), the three anti-patterns
(implementation-coupled, tautological, horizontal slicing), "one adapter is a hypothetical seam,
two adapters is a real one", "the interface is the test surface", and replace-don't-layer: once
tests exist at a deepened interface, the old shallow tests are deleted.

Left out: confirming seams by asking the user mid-build, and "refactoring belongs to the review
stage". The Testing Policy settles both. The behaviours list comes from the plan, and refactor
happens on green inside the loop.

### mattpocock code-review, to-tickets, to-spec and the tracker setup

From `code-review`: the two separate axes (does the code follow the repo's standards, does it match
the spec) and the scope-creep check. These are input for this repo's future `code-review` skill,
not a dependency of `/do`. The plugin skill needs commits first and a tracker file from its setup
skill, and it is not something this repo owns.

From `to-tickets` and the tracker templates: the ticket shape (`What to build`, `Blocked by`,
`Status`, acceptance checkboxes), the frontier (a ticket whose blockers are all done), and the
operations `/do` reuses. A local ticket is a file under `.scratch/<feature>/issues/NN-<slug>.md`,
claimed by a `Status: claimed` line and resolved by `Status: resolved`. A GitHub ticket is read with
`gh issue view <n> --comments`, claimed with `gh issue edit <n> --add-assignee @me`, closed with
`gh issue close`. `spec` (as `to-spec` did) records the testing decisions and the seams in the spec, which is where
the behaviours list finds its material when the ticket is thin.

### pstack poteto-mode

The strongest material is the discipline, not the routing. Taken:

- The matched playbook's steps become the checklist verbatim, and a skipped step stays visible as
  `skip: <reason>`.
- Every principle that changed a decision is named in the reply with the decision. A citation
  without a decision is a name-drop and is not allowed.
- A question is classified before it is asked. A fact you could observe by running something is
  answered by a probe, not by the human.
- The data shape and its organising structure are named before any logic.
- You own every subagent's diff, never its summary. A chained resume drops directives; a fresh
  dispatch with consolidated scope replaces it.
- "No is an acceptable answer." A recommendation is a judgment, not a validation.
- The reply frames impact for the consumer and for the maintainer before any implementation
  detail, and never fabricates a link or a transcript reference.
- Irreversible writes pause; reversible work proceeds and is presented.

From the playbooks:

- Feature: `how` before touching a subsystem; shared mutable state is split, not serialised; verify
  on the matching surface, where inconclusive is not a pass; rebase into small ordered commits.
- Bug fix: every shipped line traces to runtime evidence; a "might help" line is a hypothesis, not
  a fix, and is reverted; the failing repro is the evidence.
- Refactoring: pin the contract before moving structure; migrate every caller and delete the old
  API in one wave; the exit test is reduced reader load, otherwise revert.
- Opening a PR: conventional-commit titles `type(scope): subject`; the PR body sections Why,
  Scope, Tradeoffs, Blast Radius and Verification; no `## Summary` or `## Test plan` boilerplate.

Left out: everything Cursor-shaped. The model roster, `arena`, `swarm`, `interrogate`, the
`control-ui` and `control-cli` skills, `deslop`, the Origin forge, `poteto-agent`, the ten-lane live
verification of the multi-phase plan, and the `mode: true` frontmatter. Also left out: pstack's own
`tdd` escape hatch, "skip the test when it is expensive", which the Testing Policy forbids at unit
level. It survives only as the fallback for a project with no policy installed.

### pstack architect, figure-it-out, blast-radius, show-me-your-work

`architect` is vendored on the maintainer's machine as a model-invoked skill, so `/do` can call it
through the Skill tool. Taken from it: "deviations from the sketch are signal to surface, not
friction to absorb", and the scrap tells (the same workaround shape recurring, types that need
escape hatches, a second deviation of the same shape). From `figure-it-out`: state done as a
falsifiable predicate before the first edit, and the verdict words VERIFIED, NOT VERIFIED,
INCONCLUSIVE. From `blast-radius`: find the one fact the change is safe because of and prove it by
running code; that is the substance of the reply's Blast radius section and of the future review.
`show-me-your-work` is not taken: for a single-ticket run the checklist and the commits are the
trail.

### This repo

The Testing Policy is the hard constraint and it already is the TDD contract. One behaviour per
dispatch with the dispatch input (behaviour to prove, target, origin, expected red, placement, out
of scope). `RED_AS_EXPECTED` before any production code, then the minimal green, refactor on green,
next. Every new test goes through `unit-test-author`, `e2e-test-author` or the inline
`/test-author`. E2E is proven after the feature exists, never red-first. Done is the full unit suite
plus the affected E2E flows, green against the change. An infra failure is BLOCKED, only the user can
waive it, and a waiver is recorded as debt. The agent never commits; the caller does. Promotions land
in the same commit as the test that motivated them. So `/do` replaces mattpocock's `tdd` rather
than wrapping it.

`discover` runs once per unit of work, before the first symbol is created, and the audit line is
logged. `discuss` closes with a summary whose stated next step is "implement", so that summary is
`/do`'s primary input, and its `runnable` branches are already settled when `/do` starts. The new
`prototype` skill is reachable only through `/prototype` or from a `discuss` interview; `/do` does
not fork it.

From `test-triage`: the protected-branch rule, print the command line before running and wait for
a yes before a full e2e suite or a remote run, and "a fix is proven only on the surface the failure
happened on".

Principles that fire inside `/do`, each linked by path from the step that applies it:
`foundational-thinking`, `model-the-domain`, `subtract-before-you-add`, `laziness-protocol`,
`sequence-verifiable-units`, `prove-it-works`, `build-the-lever`, `never-block-on-the-human`,
`guard-the-context-window`, `encode-lessons-in-structure`, `fix-root-causes` for a fix,
`migrate-callers-then-delete-legacy-apis` and `minimize-reader-load` for a refactor,
`type-system-discipline` and `boundary-discipline` in typed code. The design-time principles
(`exhaust-the-design-space`, `redesign-from-first-principles`, `experience-first`) belong to
`discuss` and `architect`, not here.

### GSD-era skills

`verify-before-complete` contributes one rule worth keeping: the evidence is produced after the
last edit, in the same message as the claim, and the relevant output line is quoted. "Tests passed
earlier" is stale. `decompose-into-slices` and `design-an-interface` overlap with `to-tickets` and
`architect`; nothing taken. `diagnose` is a candidate the future `bug-fix` skill may build on.

## Where the sources collide

| Topic | mattpocock | pstack | Testing Policy | `/do` |
|---|---|---|---|---|
| TDD | at seams confirmed by asking | only when the test is cheap | strict red-first, one test per dispatch, always | the policy; pstack's `tdd` only as the fallback when no policy is installed |
| Who writes tests | the session | a code delegate | the test-author agents; the caller never derives the expectation | the agents, or `/test-author` inline |
| Refactor | at review stage | on green with the pin held | on green, inside the loop | on green, inside the loop |
| Where code is written | in place, current branch | a worktree, a delegate per unit | in place, one writer, shared assets serialised | a worktree, one writer: the session |
| Review | `code-review` before commit | `interrogate`, `no-comments`, `deslop` | not covered | this repo's `code-review`, TBD, after the commits |
| Delivery | commit to the current branch | small ordered commits, PR opened ready | the caller commits, promotions atomic | one green commit per behaviour, landed on the user's branch, no push |
| Verification | full suite once at the end | the real surface, inconclusive is not a pass | full unit suite plus affected E2E, BLOCKED on infra | the policy gate, E2E from the main checkout after landing |

## Decisions taken in the research session

1. **Input.** A ticket produced by `/tickets`.
   Nothing else. A request with no ticket is sent to `/tickets` when a spec exists, otherwise to
   `/discuss`. Amended 2026-09-04: the `/discuss` closing summary is no longer an input
   (`docs/adr/0003`).
2. **Design step.** When the work crosses a function boundary and no sketch exists, `/do` calls
   the Skill tool with `architect` and stops at the sketch. `/do` implements the sketch itself under
   the TDD loop, so every test still goes through the test-author agents. pstack's `no-comments`
   uses the same split, "architect shapes, the caller implements".
3. **No policy installed.** The run falls back to pstack's `tdd`, embedded in the skill as
   `references/tdd-fallback.md` with MIT attribution, read only when `.claude/agents/unit-test-author.md`
   is absent. pstack wrote it for bug fixes; the feature case gets the same rule, failing test first
   where a cheap path exists, otherwise the closest executable check with the reason stated.
4. **Worktree.** Every run works in a git worktree. The commits are cut per verifiable unit. A
   review-then-fix step precedes landing, and landing puts the worktree branch on the user's branch.
5. **E2E gate.** The unit loop and the full unit suite run in the worktree. After landing, `/do`
   runs the affected E2E flows from the main checkout, because Project facts may record that the
   E2E stack serves the primary checkout. A red flow becomes one more unit on the same branch. Done
   is reported only after that run.
6. **Landing.** The worktree branch is fast-forwarded or merged into the branch the user invoked
   `/do` from. Nothing leaves the machine; the user pushes.
7. **Commits.** One green commit per behaviour: the test, its implementation and any asset
   promotion together, so every commit is bisectable and the policy's atomic-promotion rule holds.
8. **Ticket.** Claimed at the start the way the tracker file describes. At the end each proven
   acceptance criterion is ticked, the evidence is added, and the ticket is closed. A local ticket
   file is edited in the last commit; a remote tracker write asks first.
9. **Bug tickets.** A future `bug-fix` skill in this repo owns diagnosis. The slot is `TBD`.
10. **Review.** A future `code-review` skill in this repo owns the review. The slot is `TBD`, and
    the step is written so that the new skill replaces it without other edits.
11. **Citation discipline.** Full: the checklist copied verbatim at the start, skips visible with
    their reason, and every principle that changed a decision named in the reply with the decision.
12. **Language.** Messages to the user in the language the session was opened in, as `discuss`
    does. Everything written into the repository is English.
13. **This document.** A design brief at `.agents/research/do.md`, not a draft `SKILL.md`.

## Derived from the constraints, not asked

These follow from the decisions above and from the repo's contracts. Each is a default the maintainer
can overturn before the skill is written.

- **Invocation.** User-invoked (`disable-model-invocation: true`, `policy.allow_implicit_invocation:
  false`) and inline, with no `context: fork`, because the run asks for confirmations, writes into
  the project and commits. `discuss` tells the user to run it; no skill calls it.
- **One writer.** The session writes the production code. No implementer subagents: the policy runs
  the test authors in place, serialises shared-asset creation, and the `unit-test-author` snapshots
  `git status` as its baseline, which assumes one writer in the tree. Bulk mechanical edits go to a
  script per `build-the-lever`, not to a fan-out.
- **Discovery.** One `discover` batch for the symbols the plan names, before the first one is
  created, and the audit line `Discovery: n FOUND · n DUPLICATE · n NOT_FOUND` in the thread.
- **Worktree mechanics.** `/do` creates the worktree itself with `git worktree add
  .claude/worktrees/do-<slug> -b do/<slug>` from the current HEAD, then switches the session into it.
  In Claude Code that is the worktree tool with `path`, which accepts an existing worktree; the
  tool's own create path branches from the remote default branch unless `worktree.baseRef` is set
  to `head`, which is why `/do` does not use it to create. In Codex the switch is a `cd`. The
  `.claude/worktrees/` location keeps every switch the Claude Code tool allows; any path works
  elsewhere.
- **Worktree lifetime.** The worktree stays until the E2E gate is green. A red flow after landing
  is fixed in the worktree as one more unit and landed again by fast-forward. The ticket close-out
  commit is the last commit, made in the worktree after the gate, followed by a final fast-forward.
  Then the worktree and the `do/<slug>` branch are removed.
- **Protected branch.** The `test-triage` rule applies to landing: when the user's branch is
  `main` or `master` beside a `develop`, `staging` or `release*` branch, or `production` beside any
  of those, `/do` does not merge. The worktree branch is left in place and the reply says so.
- **Forks during the build.** An empirical fork (which timing, which output, whether an API does
  the thing) is settled with a throwaway probe script in the worktree, deleted afterwards. A design
  fork means the plan is incomplete. The run stops at that step and tells the user to run `/discuss`
  on it. `/do` never forks the `prototype` agent; its description names `discuss` as the only caller,
  and widening that is a separate decision.
- **Commands.** Every test command comes from the policy's Project facts in `CLAUDE.md`, or from
  `references/tdd-fallback.md`'s detection rules when no policy is installed. The command line is
  printed before it runs. A full e2e suite or a remote command waits for a yes.
- **Evidence.** The gate output is produced after the last edit and the relevant line is quoted in
  the reply. A tool timeout is "did not finish", not green. An infra failure is BLOCKED.
- **Ticket references.** A path is read. An issue number or URL resolves through
  `docs/agents/issue-tracker.md`; when that file is absent, the number is asked for, never matched
  against a list in context. The ticket title is confirmed back in one line before the run starts.
- **Commit titles.** `type(scope): subject` with `feat`, `fix`, `refactor`, `test`, `docs` or
  `chore`. The body carries the behaviour line and the single-file command that passes.

## The run, step by step

The checklist as the run would show it. Steps 8 and the bug branch of step 5 carry the `TBD` slots.

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
- [ ] 8. Review, accepted findings become units                (TBD: code-review)
- [ ] 9. Landed on the user branch; affected E2E flows run from the main checkout
- [ ] 10. Ticket closed with evidence; worktree removed
- [ ] 11. Reply
```

**Step 0, resolve the input.** `$ARGUMENTS` is a ticket path or an issue reference, and it is
mandatory. Empty: one message telling the user to run `/tickets` on the spec, or `/discuss` when
there is no spec yet, and stop. Confirm the title back. Read the acceptance
criteria; with the policy's gate they are the predicate. Detect the mode: `unit-test-author` present
means the policy loop, absent means the fallback, stated in one line. Check the current branch
against the protected-branch rule and say now that landing will be refused if it applies. A bug ticket
that states neither its cause nor a reproduction stops here, per the `bug-fix` slot in step 5. Claim
the ticket. Show the checklist. Done when the title is confirmed, the predicate is stated, the mode is
stated and the ticket is claimed.

**Step 1, worktree.** Create it from HEAD and enter it. A dirty main checkout is the user's work and
is left alone; the worktree starts clean. Done when `git status --short` in the worktree is empty
and the branch name is in the thread.

**Step 2, ground.** Read `CONTEXT.md`, the ADRs the ticket touches and the code it names. When the
session lists a skill named `how`, call the Skill tool with it over the subsystem the ticket
reshapes, so the exploration stays out of the thread (`guard-the-context-window`). Run the discover
batch and log the audit line. State done as a predicate: the acceptance criteria plus the gate. Done
when the predicate and the audit line are in the thread.

**Step 3, shape.** Name the data shape and its organising structure before any logic
(`foundational-thinking`, `model-the-domain`). Delete dead weight the plan makes obsolete before
adding (`subtract-before-you-add`, `laziness-protocol`). When the work crosses a function boundary
and the plan carries no sketch, call the Skill tool with `architect` and stop at the sketch. The
sketch is the contract. A deviation during the build is surfaced in the reply, and a second
deviation of the same shape stops the run as a wrong sketch. Done when the shape is in the thread,
or the step reads `skip: no boundary crossed`.

**Step 4, behaviours.** Write the list from the ticket and the spec it points at, never from the
implementation. It holds the behaviours callers observe, critical paths and the logic that can be
wrong first, not one line per branch. Show it once. Each line becomes one dispatch. An empirical fork is
settled by a probe script; a design fork stops the run. Done when the list is in the thread.

**Step 5, build loop.** For each behaviour, in order:

1. Dispatch `unit-test-author` with the Agent tool and the dispatch input, or apply `/test-author
   unit` inline without the Agent tool. Wait for `RED_AS_EXPECTED`. `REFUSED_INCOMPLETE_INPUT`
   means the behaviour line was too vague: sharpen it and dispatch again. `BLOCKED` on a missing
   seam: make the seam in production code first, then dispatch again. Never mock around it.
2. Write the smallest production change that turns this test green and run the single file. A
   mechanical red (import path, renamed symbol) is fixed by `/do`. Any change to an assertion or an
   expectation goes back to the agent with the reason stated as the contract, never as the result.
3. Refactor on green, running the suite after each step. A test that goes red under a pure refactor
   was asserting implementation and goes back to the agent.
4. Typecheck. Format the touched files with the repo's formatter.
5. Commit the test, the implementation and any promotion changeset together.
6. Next behaviour. One dispatch in flight at a time.

Without a policy, the same loop runs under `references/tdd-fallback.md`: `/do` writes the failing
test itself where a cheap path exists, otherwise the closest executable check, and says why.

A bug ticket dispatches with `origin: bugfix`, so the red run reproduces the bug before the fix. A
bug ticket whose cause is unknown is the `TBD` slot: call the Skill tool with `bug-fix` once that
skill exists. Until then the step reads `skip: bug-fix not installed`, `/do` accepts a bug ticket
only when it states the cause and the reproduction, and stops otherwise with that reason.

Done when every behaviour line has a commit SHA beside it.

**Step 6, E2E authoring.** On a native or mixed surface, every user-observable change gets its flow
authored or extended by `e2e-test-author`, after the feature exists. A purely internal change states
why no flow is needed; it is never presumed. On a consumer surface the consumer flow lives in the
consumer repo, so it is recorded as pending debt in the reply with the consumers named. The flow is
committed on its own or with the last behaviour. Done when each user-observable change has a flow
or a stated reason.

**Step 7, gate in the worktree.** Full unit suite, typecheck, lint and format, run now, after the
last edit, with the output line quoted. Red goes back to step 5 as a unit. Never a skip, never a
weakened assertion, never a sleep. An infra failure is BLOCKED. Done when the suite and the
typecheck are green in output produced after the last edit.

**Step 8, review, `TBD`.** Call the Skill tool with `code-review`, this repo's future skill. Each
accepted finding becomes one more unit through step 5; a dismissed finding gets a one-line reason,
in the skeptical posture pstack applies to bot reviews. Re-run step 7. Until the skill exists the
step reads `skip: code-review not installed`, and the reply names the review as the user's next
step.

**Step 9, land, then E2E.** Switch back to the main checkout. On a protected branch, refuse: leave
the worktree and its branch, say so. Otherwise fast-forward the user's branch to the worktree branch,
rebasing the worktree branch first when the user's branch moved. No push. Run the affected E2E flows
from the main checkout with the single-flow command from Project facts, the command line printed
first. A full suite or a remote run waits for a yes. A red flow: back into the worktree, one more
unit, land again. An infra failure: BLOCKED, the work is not done, only the user can waive it, and a
waiver is recorded as debt. Done when the affected flows are green from the main checkout.

**Step 10, close.** In the worktree, tick each proven acceptance criterion in the ticket file, set
its status to resolved, append the evidence, commit, and fast-forward once more. On a remote tracker
ask, then comment the evidence and close. Remove the worktree and the `do/<slug>` branch. Done when
the ticket is closed and `git worktree list` no longer shows the run's worktree.

**Step 11, reply.** In the session's opening language. Who the work is for and what changes for
them, then what the next maintainer inherits. The commits. The evidence lines quoted: unit suite,
flows, typecheck. Every principle that changed a decision, with the decision. Every skipped step
with its reason. The PR-ready description with the sections Why, Scope, Tradeoffs, Blast Radius and
Verification, ready to paste. Pending debt: waivers, consumer coverage. The next step.

## Files the skill needs

- `skills/do/SKILL.md`. Frontmatter: `name: do`, a human-facing one-line `description`,
  `disable-model-invocation: true`, `argument-hint: "[ticket path or issue reference]"`. No
  `context`, so it runs inline. The
  operative one-liners for each principle stay inline in the steps; the file links
  `../../.agents/principles/<name>.md` for the rationale, as `discuss` does.
- `skills/do/agents/openai.yaml` with `interface.display_name`, `interface.short_description` and
  `policy.allow_implicit_invocation: false`.
- `skills/do/references/tdd-fallback.md`, adapted from pstack's `skills/tdd/SKILL.md` at the
  commit above, with the frontmatter stripped and a line naming the source and the MIT licence in
  `.agents/principles/PSTACK-LICENSE`.
- `skills/do/evals/`, cases in the `discuss` layout: a plain request with no plan is sent to
  `/discuss` and nothing is written; the worktree exists before the first edit; one dispatch at a
  time, never a batch of tests ahead of the code; one green commit per behaviour; the ticket is
  closed only after the gate.
- `docs/do.md` per `.agents/writing-docs.md`, with the chains above under "Where it fits".
- A row under User-invoked in `README.md` and `skills/README.md`, the user-invoked list in
  `.agents/invocation.md`, and a rerun of `scripts/link-skills.sh`.

## TBD slots and open items

- **`code-review`.** Step 8 calls it. Until it exists the checklist shows the skip. When it lands,
  its row joins the READMEs and the skip line is deleted; nothing else in `/do` changes.
- **`bug-fix`.** The bug branch of step 5 calls it. Until it exists a bug ticket without a stated
  cause stops at step 0. `diagnose`, present on the maintainer's machine, is a candidate base.
- **Consumer surfaces.** The policy's per-change gate includes the impacted consumers' flows run
  against this repo's local build. How `/do` runs another repo's flows after landing is open; the
  brief records it as pending debt in the reply until decided.
- **Codex wording.** The worktree switch is a `cd` there; the `SKILL.md` has to say both without
  naming a harness tool as the only way.
- **Prototype door.** Not used by `/do`. Reopen only if a build regularly stalls on a fork that a
  probe script cannot settle.
