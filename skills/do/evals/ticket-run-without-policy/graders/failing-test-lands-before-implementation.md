---
type: llm
criteria: "For each behaviour of the Plan the failing test was written and run red for the declared reason (a failing assertion or a missing export) before any change to `src/notes.js`, then the smallest change was made and the same command (`node --test <file>`) shown passing. Each commit on the `do/archive-a-note` branch holds both the test change and the implementation change, titled as a conventional commit, with the behaviour line and the single-file command in its body, so the failing test lands before or together with the implementation and never after it. The evidence is git output the session produced at its diff step (`git log`, `git show --stat`) together with the `[subagent]` command output of the `do-builder` fork, not the fork's claim on its `build:` lines."
---
A failing test still lands before the implementation when the build runs in the Builder's window.
