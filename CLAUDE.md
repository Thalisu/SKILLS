# CLAUDE.md

Rules for working in this repository. They apply to every change made here, by a human or by an
agent. The long-form contracts they point at live in `.agents/`.

## Invocation: every skill is one or the other

Every `SKILL.md` in this repo is either **user-invoked** or **model-invoked**. There is no third
state, and the choice is made explicitly when the skill is created.

- **User-invoked**: reachable only by the human typing its name. Set `disable-model-invocation: true`
  in the `SKILL.md` frontmatter (Claude Code) and `policy.allow_implicit_invocation: false` in
  `agents/openai.yaml` (Codex). Both, always: a skill is user-invoked in both harnesses or in
  neither. Its `description` is human-facing, a one-line summary for a person browsing slash
  commands, with no trigger lists.
- **Model-invoked**: reachable by the model or by the user. Omit `disable-model-invocation`, and omit
  the `policy` block from `agents/openai.yaml`. Its `description` is model-facing and keeps trigger
  phrasing ("Use when the user wants..., mentions..., asks for...") so auto-invocation fires.

Read `.agents/invocation.md` before adding a skill or changing how one is reached. It carries the
full contract, including how skills depend on each other: a step may tell the agent to call the
Skill tool with a model-invoked skill, and never with a user-invoked one, which only the human can
fire. A skill that ships an `AGENT.md` opens a second door, the Agent tool, gated by that agent's
description naming the callers it accepts; `prototype` names `discuss` and `journey`.

## READMEs

Two levels, both kept in sync with the skills on disk:

- **`README.md` (top level)**: one entry per skill, with the skill name linked to its `SKILL.md`
  (`[test-triage](skills/test-triage/SKILL.md)`), never to the directory. Entries are grouped into
  **User-invoked** and **Model-invoked**.
- **`skills/README.md`**: lists every skill in that folder, each with a one-line description and the
  skill name linked to its `SKILL.md`, under the same two groups. If skills are ever split into
  subfolders, every folder that holds skills carries its own `README.md` covering the skills in it.
- **`vendor/README.md`**: the same for the vendored skills, plus the upstream, the pinned commit
  and the local changes on top of it. The top-level `README.md` lists them under **Vendored**.

Adding, renaming or removing a skill means updating the top-level `README.md` and its folder's
`README.md` in the same change.

## Docs

Human-facing docs pages follow `.agents/writing-docs.md`: its page structure, its section order and
its conventions. Read it before writing a page or re-syncing one after a skill changes.

## Principles

`.agents/principles/` holds design principles as plain reference documents, one per file, indexed in
its `README.md`. They are not skills: no frontmatter, no invocation, and no harness lists them. A
skill or a contract that leans on one links the file by path. Adding, renaming or removing a
principle updates that index in the same change.

## Formats

`.agents/formats/` holds the formats of the artifacts the skill chain shares (`CONTEXT.md`, an ADR,
a spec, a journey, a ticket, a review), one per file, indexed in its `README.md`, per `docs/adr/0004`. A
skill that writes or reads one links the file by relative path: never a copy, and never a link
into another skill's folder. A format read by one skill only stays in that skill's `references/`.
Adding, renaming or removing a format updates the index in the same change.

## The scratch folder

`.scratch/` is where a project keeps the chain's local artifacts, and it is always unversioned: it
is one developer's own workspace and a teammate never reads it. `.agents/scratch.md` carries the
contract, the line the project's `.gitignore` holds, the probes that read the state, what two runs
at once share, and how a run inside a git worktree reaches the folder. A skill that reads or writes
there links it by path, never a copy.

## Vendored dependencies

`vendor/` holds the skills this repo's skills call and does not own: a subset of pstack, copied at
the upstream commit `vendor/README.md` pins, with every local change listed there. They are
dependencies, not this repo's skills, so they live outside `skills/`, carry no page under `docs/`,
and are edited only to adapt them to the harnesses or to refresh them from upstream; any other
change goes upstream first. They keep the invocation contract like every skill here: frontmatter,
`agents/openai.yaml`, and a row in `vendor/README.md` and in the top-level `README.md` under
**Vendored**. A step in `skills/` that needs one calls the Skill tool with it like any model-invoked
skill, and says in one line what it does when the skill is absent, since a machine may have linked
`skills/` without `vendor/`.

## Installing skills locally

`scripts/link-skills.sh` (re)links every skill under `skills/` and `vendor/` into the local harness
skill directories, `~/.claude/skills` and `~/.agents/skills`, links every `AGENT.md` a skill ships
into `~/.claude/agents` under the agent's own name and every markdown definition in the skill's
`agents/` folder under its file name, and prunes the links into this repo whose skill or definition
is gone. Each entry is a symlink
into this repo, in the same layout `discover-setup` installs, so a `git pull` keeps installed skills
current. Re-run the script after adding, removing or renaming a skill. It is the supported
installer: the README's Install section is a clone and one run of it, so a skill or an agent
definition it does not pick up is not installed at all. `scripts/tests/link-skills.sh` runs it
against this repo and fails on anything on disk it leaves unlinked.

<!-- testing-policy:start v=2.5 surface=native -->
## Testing Policy (Definition of Done)

<!-- testing-policy:core-start -->
A feature or fix is DONE only when its own tests pass, the unit tests and the E2E coverage of the change, and then the post-feature gate passes. "Tests didn't run" is never "tests passed". The rules below are fixed; the project's commands, paths, tool names and the post-feature gate it picked live in **Project facts** at the end of this section.

### Success gate (tiered)

- **Per change**: the change's own tests green, run against this change: the unit tests it added and the ones covering the code it touches (single-file command in Project facts), and the E2E flows it added or affects (single-flow command in Project facts).
- **Per feature**: once every change of a feature is green, the post-feature gate in Project facts runs on the integrated result before the feature, phase or delivery is declared complete. It is one of four: the full unit suite, the full E2E suite, both, or none (full-suite commands in Project facts); with none, the per-change tier is the whole gate.
- **Infra failure blocks**: if E2E cannot run (the known infra failures in Project facts are the usual suspects), the work is BLOCKED, not done. Report the infra error as blocked status; fixing the infra is part of the delivery. Only the user can explicitly waive the E2E gate, and a waiver is recorded as pending debt, never as green.

### TDD

- **Unit is strict red-first**: write the failing test before the implementation. For a bugfix, the test must reproduce the bug (fail red) before the fix turns it green.
- **One test at a time**: red → green → next. The first cycle is a tracer bullet, one test proving the path end to end, and each next test is chosen from what the previous cycle taught. Never the whole batch of tests first and the implementation after: tests written in bulk describe imagined behavior and the shape of things (signatures, data structures), not what the code does, and stay green when it breaks.
- **Green is minimal**: only the code the current test needs; no branch, parameter or feature for a test not yet written.
- **Refactor on green, never on red**: once green, extract duplication, move complexity behind the interface the test exercised, move logic to where its data lives, running the suite after every step. A test that goes red under a pure refactor was asserting implementation (see "Tests describe behavior") and is rewritten against the interface, not appeased.
- **Behaviors, not branches**: the tests for a change are the behaviors its callers observe, prioritized with critical paths and the logic that can be wrong first; not one test per branch, not every edge case. The list is written before the first cycle, from the request, the plan or the user, never inferred from the implementation.
- **E2E is proven after**: the E2E flow is authored or extended together with the feature and MUST pass before the work is declared done. No red-first requirement at E2E level: a flow written against a UI that doesn't exist yet fails trivially and proves nothing.

### Tests describe behavior, not implementation

- **Through the public interface**: a test exercises the target the way its callers do and asserts only what they can observe (the return value, the state read back through the same interface, the error raised). It is named for the behavior it proves, in the caller's words ("rejects an expired card", not "calls validateCard"), and it survives every refactor that keeps that behavior. A test that must reach into internals (a private function, a call on an internal collaborator, a row read straight from the table the code wrote) tests the implementation: it breaks on refactors that change nothing and passes on bugs that change everything.
- **Mock at system boundaries only**: external services, the clock, randomness, the network, sometimes the database or the filesystem, as named in the unit-test-author's Project map, through their shared mocks. Never this repo's own modules or internal collaborators: a mocked internal pins the implementation and stays green when the real path is broken.
- **A test that is hard to write is a design signal**: when a behavior can only be reached by mocking an internal, or by asserting on a side effect the interface does not expose, the fix is a seam in the code (pass the dependency in, return the result instead of mutating) and it lands before the test. Never mock around a missing seam.
- **E2E asserts what the user sees**: the screen, the message, the navigation, the state the product shows. A backend read through a helper is the fallback when no surface exposes the outcome, and the flow states why.

### Test authoring: delegation and reuse

Every new test, a new test file or a new test case, is written under the test-author checklist, whose single source is the agent file:
`.claude/agents/unit-test-author.md` for unit tests and `.claude/agents/e2e-test-author.md` for E2E flows.

- **Who is bound**: everyone who writes a test. With the `Agent` tool, dispatch the agent. Without it (executors, auditors, test generators), invoke `/test-author`, which applies the agent file's **Authoring rules** and **Project map** inline; the agent file's **Dispatch protocol** binds only the dispatched agent. Never copy the rules here.
- **Dispatch input** (the agent refuses incomplete input and never infers the expectation from the implementation):

  ```
  Behavior to prove: <one sentence, in observable terms; it becomes the test name>
  Target: <module / function>  (unit)   |   Journey / screen: <where in the product>  (E2E)
  Origin: bugfix | new feature
  Expected red: <failing assertion | unresolved import | error not thrown>  (unit)
  Fixture state: <what must exist before the flow starts>  (E2E)
  Placement (optional): <existing file to extend> | new file
  Out of scope (optional): <...>
  ```

- **One dispatch per cycle**: the next unit test is dispatched (or written inline) only after the previous one is green and its implementation exists, never a batch of tests ahead of the code (see "TDD").
- **Editing an existing case** (one more assertion, adjusted data) stays with the caller, unless it needs a new shared asset (factory, mock, fixture, helper, page-object method), which escalates to the agent.
- **Reuse over duplication**: reuse > extend > create. An asset that exists anywhere in the test tree, including local to another test file, is never rewritten; on its second use it is promoted to the shared home for its role (the agent's Project map names them) and every call site is updated. A separate near-duplicate asset requires a written semantic justification in the agent's report.
- **Promotions are atomic**: the promoted asset and every updated call site are committed together with the test that motivated them, or in a refactor commit immediately before it, never split across commits, never left out of one. The agent reports the promotion as its own changeset for exactly this reason.
- **A test still red after implementation**: the caller may fix mechanical breakage (import path, renamed symbol, typo). Any change to an assertion, an expectation, or expected data goes back to the agent, with the reason stated in terms of the contract ("the intended behavior was X"), never in terms of the result ("the test is catching it").
- **Shared-asset creation is serialized**: two authors creating shared assets in parallel cannot see each other's work and will each create the "missing" one. Prefer one author of each type in flight; when authors did run in parallel (parallel executors in a phase), the phase is not done until the duplication scan (Project facts) is clean.
- **The agents run in place**, never in a worktree (reason in Project facts).

### E2E mapping

- **What requires E2E**: every change with a user-observable effect (screen, flow, navigation, message, state). Purely internal changes (refactor, script, build config) require unit coverage at the lowest level that captures the behavior; skipping E2E must be justified in that change, never presumed.
- **Flow per journey/scenario**: a new user journey, or a scenario needing a distinct fixture state, gets a new flow file (naming convention and real examples in Project facts). A fix within an existing journey extends that journey's flow with the assertions that capture the regression.
- **A bug that escaped the suite is a coverage gap**: the existing flow was incomplete, not wrong. Add the missing assertion or scenario so the bug would now be caught; never rewrite a green journey because of a fix that didn't change the journey.

### Tests represent the real flow

**Principle: a failing test is presumed to expose a product bug, not a test bug.** Changing a test to make it pass requires demonstrating that the flow itself changed, stated explicitly in the commit/report, never done silently. The one other legitimate change is a test that goes red under a pure refactor, with the behavior through the public interface unchanged: it was asserting implementation (a mocked internal, a call count, a private symbol) and is rewritten against the interface, with that stated: the demonstration, not an exception to it.

Forbidden:

- Skipping, narrowing or marking optional a failing test or assertion (the skip mechanisms named in Project facts, or any equivalent).
- Weakening or removing an assertion to get green.
- Tests or flows without an outcome assertion (asserting only that nothing crashed).
- Asserting the route instead of the outcome: that an internal collaborator was called, how many times, in what order. (A call into a mocked boundary is an outcome: the charge made, the email sent.)
- Verifying through a side channel (reading the row the code wrote) when the interface can read the outcome back.
- Mocking a module of this repo in a unit test; boundaries only (see "Tests describe behavior").
- Mocking the backend in this repo's E2E; flows run against the real test stack (Project facts) with seeded fixtures.
- Adjusting a unit expectation to match buggy behavior.
- Sleep/timeout padding to mask a race condition instead of fixing the race.
<!-- testing-policy:core-end -->

### Project facts

<!-- Filled at install from the project's real setup; PRESERVED on refresh (the skill only reports
     when a fresh discovery disagrees). Every command here has been run once and returned output. -->

- **Unit**: full suite `fails=0; for t in $(git ls-files | grep -E '^(scripts|skills/[^/]+)/tests/[^/]+\.sh$' | grep -vx 'scripts/tests/lib.sh'); do bash "$t" >/dev/null 2>&1 || { echo "RED $t"; fails=$((fails+1)); }; done; echo "red: $fails"; [ "$fails" = 0 ]` · single file `bash skills/<skill>/tests/<name>.sh` · mandatory flags / known phantom failures: no runner or framework: each script prints `ok` / `FAIL` per case and exits non-zero on a red; `skills/do/tests/context-usage.sh` prints a `skip  live session` line outside a live Claude session, which is not a red; `skills/do-code-review/tests/evals.sh` needs `node` · skip mechanisms: no framework skip; the repo's idiom is an `echo "skip ..."` line that leaves a case out (`skills/do/tests/context-usage.sh:73`), and an early `exit 0` or a commented-out `check` does the same; the hook blocks a new `echo "skip` line through `.claude/testing-policy/skip-patterns.local.sh`
- **Post-feature gate**: none: the per-change tier is the whole gate, the change's own test scripts and the eval cases it affects (full suites, when run by hand: the unit loop above, the E2E loop below)
- **E2E**: `scripts/run-eval.sh`, a headless `claude -p` eval runner standing in for `claude plugin eval` while that command is gated · single flow `bash scripts/run-eval.sh <skill> <case>` · full suite `for s in discuss do do-code-review journey prototype spec test-triage tickets; do bash scripts/run-eval.sh "$s"; done` · flow naming `skills/<skill>/evals/<case>/{case.yaml,prompt.md,graders/*.md}` (e.g. `skills/do/evals/trivial-run`, `skills/journey/evals/one-question`, `skills/test-triage/evals/triggers-pt-br`) · skip mechanisms: none in the runner; leaving a case out of the arguments or deleting a grader file is the equivalent
- **Real test stack**: the real `claude` CLI under a throwaway `CLAUDE_CONFIG_DIR`, with every skill and agent of this repo linked by `scripts/link-skills.sh` into a sandbox `HOME` and `~/.claude/.credentials.json` linked in; each run's fixture is laid by the case's `context.scaffold_script` in an empty folder, and `llm` graders are read by a judge session (default `sonnet`). Nothing to bring up; every run is a billed session · **known infra failures**: exit 2 with `missing dependency: <claude|jq|yq|timeout|git>`; `scripts/link-skills.sh could not link the skills into the sandbox`; no `~/.claude/.credentials.json`, so the sandboxed session cannot log in
- **Duplication scan**: `bash .claude/testing-policy/scan-test-assets.sh --root scripts/tests --root skills --flows skills` · shared homes per role: the agents' Project map
- **Why the agents run in place**: the harness's worktree tool isolates the session, and an isolated session refuses `bash <script>` (`.agents/worktrees.md`), which is how every test script and `scripts/run-eval.sh` run here; the runner also links the skills of the checkout it runs from
<!-- testing-policy:end -->

## Prose style: no em-dashes

No em-dashes anywhere in this repo's prose: `SKILL.md` files, docs, `README.md`, `CHANGELOG.md`,
ADRs, changesets and code comments.

Where a sentence reaches for one, rewrite the sentence. Use a comma, a colon, a period, parentheses
or a conjunction, whichever the sentence actually wants. Never do a blind character substitution:
replacing every em-dash with a hyphen or a comma leaves prose that reads as if a machine ran over
it.

The character is still used as a delimiter in two machine contracts and stays there: the discover
batch line (`<n>. <behaviour> — names: ...`, `[— callers?]`) and the discover PARTIAL output line
(`<signature> — <how it differs>`). Those, and the test data that exercises them, are syntax, not
prose.

## Setup skills stay project-scoped

A skill that sets a project up writes its output into that project, scoped to it, never globally.

- The install target is the project's own files (its `CLAUDE.md`, its `.claude/`), committed in that
  repo, so the team reads it from git instead of re-running the skill on every machine. The global
  scope (`~/.claude/CLAUDE.md`) is used only when the user asks for it explicitly.
- Nothing a skill learns about a project comes back here. No skill in this repo names a repository
  it has run against, private or public, by name, path, URL or worked example. This repo is shared
  by every project and it is public, so anything project-derived kept in it would be global by
  construction.
- Every mapping stays in the repo it was derived from: a Project map, a runner config, a dossier, a
  captured convention. Nothing is gitignored to that end: a stray `local/` or `capture/` directory
  under `skills/` shows up in `git status`, and the versioned `.githooks/pre-commit` refuses to
  commit one. That hook is the backstop, not a sanctioned home for captures.
