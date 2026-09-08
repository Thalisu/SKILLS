---
type: llm
criteria: "The fixture has no `.claude/agents/unit-test-author.md` and no Testing Policy section in `CLAUDE.md`. The run's first message, before any edit, carried the loop line `Loop: fallback` and not `Loop: policy`, and before writing its first test the run read the skill's `references/tdd-fallback.md` (a Read, a cat or an equivalent of that file appears in the transcript). The run never treated the missing author as a blocker, never asked the developer to install a Testing Policy, and never invented a policy of its own."
---
The loop line reads `fallback` and the fallback reference is read before the first test.
