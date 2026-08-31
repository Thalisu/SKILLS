<!-- testing-policy version: 2 -->
<!-- TEMPLATE — canonical Testing Policy, rendered into the project's CLAUDE.md by
     scripts/render-policy.sh <native|consumer|mixed>. A block opened by an "@surface,surface"
     comment and closed by an "@/" comment is emitted only for the listed surfaces; untagged
     text is common to all surfaces.
     Between core-start/core-end the text is normative and slot-free — it is regenerated on
     every refresh. "Project facts" is the only part with {{slots}}: filled once from the
     project's REAL setup (never invented) and preserved on refresh. -->
<!-- testing-policy:start v={{VERSION}} surface={{SURFACE}} -->
## Testing Policy (Definition of Done)

<!-- testing-policy:core-start -->
A feature or fix is DONE only when the full unit suite passes AND its E2E coverage passes. "Tests didn't run" is never "tests passed". The rules below are fixed; the project's commands, paths and tool names live in **Project facts** at the end of this section.

<!-- @native,mixed -->
### Success gate (tiered)

- **Per change**: full unit suite green (unit command in Project facts) + the affected E2E flows green (single-flow command in Project facts), run against this change.
- **Per phase/delivery**: full E2E suite green (full-suite command in Project facts) before declaring the phase or delivery complete.
- **Infra failure blocks**: if E2E cannot run (the known infra failures in Project facts are the usual suspects), the work is BLOCKED, not done. Report the infra error as blocked status; fixing the infra is part of the delivery. Only the user can explicitly waive the E2E gate, and a waiver is recorded as pending debt — never as green.
<!-- @/ -->
<!-- @consumer -->
### E2E gate (consumer-side)

This repo has no user-facing surface of its own. Its real E2E coverage lives in the repos that consume it (the consumer list in Project facts). An E2E suite inside this repo would not represent the real flow and does not satisfy the gate.
<!-- @/ -->
<!-- @mixed -->
### E2E gate (consumer-side)

Besides its own surface, this repo is consumed by other repos (the consumer list in Project facts). For the consumed surface the real E2E coverage lives in those repos; an E2E suite here does not stand in for it.
<!-- @/ -->
<!-- @consumer,mixed -->

- **Impact-scoped**: the gate applies only to the consumers whose flows the change impacts. A consumer that does not use the changed surface requires neither an E2E run nor new coverage for this change — but "not impacted" is a verified claim (check the consumer's actual calls to the changed routes, queues or exports), never a presumption.
- **Per change**: full unit suite green (unit command in Project facts) + the impacted consumers' E2E flows that exercise the changed surface green, run against this change (each consumer's "run against the local build" recipe in Project facts).
- **Per phase/delivery**: full E2E suite of each impacted consumer green (each consumer's full-suite command in Project facts) before declaring the phase or delivery complete.
- **Infra failure blocks**: if a consumer's E2E cannot run (its known infra failures in Project facts are the usual suspects), the work is BLOCKED, not done. Report the infra error as blocked status; fixing the infra is part of the delivery. Only the user can explicitly waive the E2E gate, and a waiver is recorded as pending debt — never as green.
- **New consumers**: when a new repo starts consuming this one, ask the user and add it to the consumer list — the gate covers every consumer, not just the first.
<!-- @/ -->

### TDD

- **Unit — strict red-first**: write the failing test before the implementation. For a bugfix, the test must reproduce the bug (fail red) before the fix turns it green.
<!-- @native,mixed -->
- **E2E — prove after**: the E2E flow is authored or extended together with the feature and MUST pass before the work is declared done. No red-first requirement at E2E level — a flow written against a UI that doesn't exist yet fails trivially and proves nothing.
<!-- @/ -->
<!-- @consumer,mixed -->
- **Consumer E2E — prove after**: the consumer flow is authored or extended in the consumer repo together with the consuming feature and MUST pass against this change before the work is declared done. No red-first requirement at E2E level — a flow written against a surface that doesn't exist yet fails trivially and proves nothing.
<!-- @/ -->

### Test authoring — delegation and reuse

Every new test — a new test file or a new test case — is written under the test-author checklist, whose single source is the agent file:
<!-- @native -->
`.claude/agents/unit-test-author.md` for unit tests and `.claude/agents/e2e-test-author.md` for E2E flows.
<!-- @/ -->
<!-- @consumer -->
`.claude/agents/unit-test-author.md`. E2E flows are authored in the consumer repos, under their own `e2e-test-author`.
<!-- @/ -->
<!-- @mixed -->
`.claude/agents/unit-test-author.md` for unit tests and `.claude/agents/e2e-test-author.md` for this repo's own E2E flows; flows covering the consumed surface are authored in the consumer repos, under their own `e2e-test-author`.
<!-- @/ -->

- **Who is bound**: everyone who writes a test. With the `Agent` tool, dispatch the agent. Without it (executors, auditors, test generators), invoke `/test-author`, which applies the agent file's **Authoring rules** and **Project map** inline; the agent file's **Dispatch protocol** binds only the dispatched agent. Never copy the rules here.
- **Dispatch input** — the agent refuses incomplete input and never infers the expectation from the implementation:

  ```
  Behavior to prove: <one sentence, in observable terms>
  Target: <module / function>  (unit)   |   Journey / screen: <where in the product>  (E2E)
  Origin: bugfix | new feature
  Expected red: <failing assertion | unresolved import | error not thrown>  (unit)
  Fixture state: <what must exist before the flow starts>  (E2E)
  Placement (optional): <existing file to extend> | new file
  Out of scope (optional): <...>
  ```

- **Editing an existing case** (one more assertion, adjusted data) stays with the caller — unless it needs a new shared asset (factory, mock, fixture, helper, page-object method), which escalates to the agent.
- **Reuse over duplication**: reuse > extend > create. An asset that exists anywhere in the test tree — including local to another test file — is never rewritten; on its second use it is promoted to the shared home for its role (the agent's Project map names them) and every call site is updated. A separate near-duplicate asset requires a written semantic justification in the agent's report.
- **Promotions are atomic**: the promoted asset and every updated call site are committed together with the test that motivated them, or in a refactor commit immediately before it — never split across commits, never left out of one. The agent reports the promotion as its own changeset for exactly this reason.
- **A test still red after implementation**: the caller may fix mechanical breakage (import path, renamed symbol, typo). Any change to an assertion, an expectation, or expected data goes back to the agent, with the reason stated in terms of the contract ("the intended behavior was X") — never in terms of the result ("the test is catching it").
- **Shared-asset creation is serialized**: two authors creating shared assets in parallel cannot see each other's work and will each create the "missing" one. Prefer one author of each type in flight; when authors did run in parallel (parallel executors in a phase), the phase is not done until the duplication scan (Project facts) is clean.
- **The agents run in place**, never in a worktree (reason in Project facts).

<!-- @native,mixed -->
### E2E mapping

- **What requires E2E**: every change with a user-observable effect (screen, flow, navigation, message, state). Purely internal changes (refactor, script, build config) require unit coverage at the lowest level that captures the behavior — skipping E2E must be justified in that change, never presumed.
- **Flow per journey/scenario**: a new user journey, or a scenario needing a distinct fixture state, gets a new flow file (naming convention and real examples in Project facts). A fix within an existing journey extends that journey's flow with the assertions that capture the regression.
- **A bug that escaped the suite is a coverage gap**: the existing flow was incomplete, not wrong. Add the missing assertion or scenario so the bug would now be caught; never rewrite a green journey because of a fix that didn't change the journey.
<!-- @/ -->
<!-- @consumer,mixed -->
### Coverage mapping (consumer-side)

- **What requires consumer E2E**: every change with a consumer-observable effect (response shape, status codes, new or changed routes, queue payloads, exported behavior, side effects a client sees). Purely internal changes (refactor, logging, build config) require unit coverage at the lowest level that captures the behavior — skipping the consumer E2E must be justified in that change, never presumed.
- **Coverage requirement**: every consumer-observable change is covered by a flow in each impacted consumer repo, following that repo's flow naming (Project facts). If no consumer exercises the new surface yet (surface built ahead of the client feature), the E2E lands together with the first consuming feature — recorded as pending debt against that feature until then, never as green.
- **A bug that escaped a consumer's suite is a coverage gap**: the existing flow was incomplete, not wrong. Add the missing assertion or scenario in that consumer so the bug would now be caught; never rewrite a green journey because of a fix that didn't change the journey.
<!-- @/ -->

### Tests represent the real flow

**Principle: a failing test is presumed to expose a product bug, not a test bug.** Changing a test to make it pass requires demonstrating that the flow itself changed — stated explicitly in the commit/report, never done silently.

Forbidden:

- Skipping, narrowing or marking optional a failing test or assertion (the skip mechanisms named in Project facts, or any equivalent).
- Weakening or removing an assertion to get green.
- Tests or flows without an outcome assertion (asserting only that nothing crashed).
<!-- @native,mixed -->
- Mocking the backend in this repo's E2E — flows run against the real test stack (Project facts) with seeded fixtures.
<!-- @/ -->
<!-- @consumer,mixed -->
- Mocking this repo in a consumer's E2E — consumer flows run against the real local stack with this repo built from the working tree.
<!-- @/ -->
- Adjusting a unit expectation to match buggy behavior.
- Sleep/timeout padding to mask a race condition instead of fixing the race.
<!-- testing-policy:core-end -->

### Project facts

<!-- Filled at install from the project's real setup; PRESERVED on refresh (the skill only reports
     when a fresh discovery disagrees). Every command here has been run once and returned output. -->

- **Unit**: full suite `{{UNIT_FULL_COMMAND}}` · single file `{{UNIT_FILE_COMMAND}}` · mandatory flags / known phantom failures: {{UNIT_GOTCHAS}} · skip mechanisms: {{UNIT_SKIP_MECHANISMS}}
<!-- @native,mixed -->
- **E2E**: {{E2E_TOOL}} · single flow `{{E2E_FLOW_COMMAND}}` · full suite `{{E2E_FULL_COMMAND}}` · flow naming `{{E2E_FLOW_NAMING}}` (e.g. {{E2E_FLOW_EXAMPLES — 2-3 real file names}}) · skip mechanisms: {{E2E_SKIP_MECHANISMS}}
- **Real test stack**: {{E2E_STACK — what the flows run against and how it is brought up}} · **known infra failures**: {{E2E_INFRA_FAILURES}}
<!-- @/ -->
<!-- @consumer,mixed -->
- **Consumers** — one line each: repo · E2E tool · run against this repo's local build · single flow · full suite · flow naming · known infra failures
  - {{CONSUMER_1}}
  - {{CONSUMER_2}}
<!-- @/ -->
- **Duplication scan**: `{{SCAN_COMMAND}}` · shared homes per role: the agents' Project map
- **Why the agents run in place**: {{WHY_IN_PLACE}}
<!-- testing-policy:end -->
