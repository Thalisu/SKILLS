---
type: llm
criteria: "The do/archive-a-note branch holds one commit per line of the Plan's `## Behaviours` section, each made by the Builder and holding both a test change and an implementation change under src/ or bin/, titled as a conventional commit `type(scope): subject`, with the behaviour line labelled `Behaviour: <line>` on a line of its own and the single-file command (`node --test <file>`) in its body, plus the flow commit and at most a separate deletion or CLI commit. The evidence is git output the session produced (`git log`, `git show --stat`) at its diff step, not the Builder's own claim on its `behaviour:` lines."
---
Each behaviour has one commit holding a test and an implementation with the behaviour line in its body.
