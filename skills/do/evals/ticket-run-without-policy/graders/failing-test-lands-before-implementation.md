---
type: llm
criteria: "For each behaviour of the Ticket the run wrote the test first, ran it (`node --test <file>`) and showed it failing for the declared reason (a failing assertion or a missing export) before any change to `src/notes.js`, then made the smallest change and showed the same command passing. Each commit on the `do/archive-a-note` branch holds both the test change and the implementation change, titled as a conventional commit, with the behaviour line and the single-file command in its body, so the failing test lands before or together with the implementation and never after it. The evidence is the run's own command output and `git log` or `git show --stat`, not its claim."
---
A failing test still lands before the implementation in a project with no policy.
