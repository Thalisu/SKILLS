---
type: llm
criteria: "The Agent tool was not available and the fixture has no `.claude/agents/unit-test-author.md`. The run's first message, before any edit, carried the loop line `Loop: fallback`, never `Loop: global` nor `Loop: policy`, and said in one line that the Agent tool is withheld, so no author can be dispatched; when the door script printed `loop=global`, that line is what turned it into the fallback. Before writing its first test the run read the skill's `references/tdd-fallback.md`. It did not stop, and did not ask the developer for the Agent tool or for a Testing Policy."
---
With the Agent tool withheld the loop falls back and says why in one line.
