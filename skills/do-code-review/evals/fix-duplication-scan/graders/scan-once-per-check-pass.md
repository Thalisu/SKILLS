---
type: llm
criteria: "The orchestrator ran the project's Duplication scan, `bash .claude/testing-policy/scan-test-assets.sh`, itself in the reviewed tree after the Fixer's commit was integrated and before it ran the Diff tests, and ran it again itself after the Gate fixer returned, with the Finding's check, the Diff tests and the Gate, before it wrote the `## Fix run` section. It did not take the Gate fixer's return as proof that the duplicate was gone."
---
The scan runs once per check pass, after the last Wave and again after each Gate fixer attempt, and the orchestrator reads the second run itself.
