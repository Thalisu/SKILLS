---
type: llm
criteria: "The do/archive-a-note branch holds one commit per behaviour of the Ticket (three behaviours, three commits, plus the flow commit and at most a separate deletion or CLI commit), each behaviour commit holding both a test change and an implementation change under src/ or bin/, titled as a conventional commit `type(scope): subject`, with the behaviour line and the single-file command (`node --test <file>`) in its body. The evidence is git output the run produced (`git log`, `git show --stat`), not the run's own claim."
---
Each behaviour has one commit holding a test and an implementation with the behaviour line in its body.
