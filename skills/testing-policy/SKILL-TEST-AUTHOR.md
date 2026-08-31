---
name: test-author
description: Write a new unit test or E2E flow under this project's Testing Policy when you cannot dispatch the unit-test-author / e2e-test-author agent (no Agent tool). Invoke before adding any new test file or test case. Args - unit | e2e.
---
<!-- TEMPLATE — generated into <project>/.claude/skills/test-author/SKILL.md by the testing-policy
     skill. Fill the {{slots}}; remove this comment when installing. -->

You are about to write a new test inline, without the test-author agent. The agent file is the single source of the rules; this skill only routes you to the parts that bind inline.

1. **Fill the dispatch input for yourself first** — behavior to prove, target (unit) or journey/screen (E2E), origin (`bugfix` / `new feature`), expected red (unit) or fixture state (E2E). If you cannot, you do not yet know what you are testing: stop and ask.
2. **Open the agent file** and apply **## Authoring rules** and **## Project map** in full:
   - `unit` → `.claude/agents/unit-test-author.md`
   - `e2e` → {{TEST_AUTHOR_E2E_LINE — native: "`.claude/agents/e2e-test-author.md`" · consumer-side: "this repo has no E2E of its own; flows live in <consumer repos> — author them there with that repo's `/test-author e2e`"}}

   **## Dispatch protocol** does not apply inline — you are the caller: you own the feature code, the stack and the commit.
3. **Run the Discovery block** from Project map before writing anything, and keep what it returned.
4. **Write and run** as the rules say — unit: red for the declared reason, then green after the implementation; E2E: preflight, then green against the real stack. Never weaken an assertion to get there.
5. **Report inline** the same two sections the agent would: **Reuse audit** (searches run, what they returned, decision per asset — present even when nothing was created) and **Run** (command and output verbatim). A promotion is listed as its own changeset and lands in the same commit as the test, or in a refactor commit immediately before it.
