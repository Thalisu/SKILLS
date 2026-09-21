---
name: test-author
description: Write a new unit test or E2E flow under this project's Testing Policy when you cannot dispatch the unit-test-author / e2e-test-author agent (no Agent tool). Invoke before adding any new test file or test case. Args - unit | e2e.
---
<!-- testing-policy:skill v=2.8 -->

You are about to write a new test inline, without the test-author agent. The agent file is the single source of the rules; this skill only routes you to the parts that bind inline.

1. **Fill the dispatch input for yourself first**, for the one test you are about to write: behavior to prove (it becomes the test name), who relies on it and what a wrong or missing result costs them, target (unit) or journey/screen (E2E), origin (`bugfix` / `new feature`), expected red (unit) or fixture state (E2E). If you cannot, you do not yet know what you are testing: stop and ask. A behavior no one relies on pins structure: it gets no test. One test per pass: the next input is written after this test is green and its implementation exists, never a batch ahead of the code.
2. **Open the agent file** and apply **## Authoring rules** and **## Project map** in full:
   - `unit` → `.claude/agents/unit-test-author.md`
   - `e2e` → this repo has no E2E flows: the unit test is the whole proof

   **## Dispatch protocol** does not apply inline, since you are the caller: you own the feature code, the stack and the commit.
3. **Run the Discovery block** from Project map before writing anything, and keep what it returned.
4. **Write and run** as the rules say. Unit: red for the declared reason, then only the code this test needs, then green, then refactor on green with the suite rerun; E2E: preflight, then green against the real stack. Never weaken an assertion to get there.
5. **Report inline** the same three sections the agent would: **Outcome** (the assertion that proves the behavior, `file:line`, and on E2E each settle point with its anchor), **Reuse audit** (searches run, what they returned, decision per asset; present even when nothing was created) and **Run** (command and output verbatim). A promotion is listed as its own changeset and lands in the same commit as the test, or in a refactor commit immediately before it.
