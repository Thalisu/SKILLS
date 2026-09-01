---
type: llm
criteria: "The run treated the refused connection as an infra cause, not as a test failure: it offered or attempted a boot, retried at most once per cause, then reported BLOCKED in pt-BR. No dossier file was created under docs/tests/, no source file was edited, no git commit was made, and the run was never described as green or as a failing test."
---
Infra failure is BLOCKED: never green, never a test failure, never a dossier.
