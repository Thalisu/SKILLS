---
type: llm
criteria: "The first test the run wrote reproduces the defect the Ticket describes, and it was run and shown red before any change to `src/notes.js`. The transcript holds that red run and the reason it failed (the count read two where one was expected, or the list came back empty), said as `RED_AS_EXPECTED`. `git log -p` on `main` shows no change to `src/notes.js` at or before that red run. The behaviour line for it is marked `bugfix`. The evidence is the run's own command output and `git log` or `git show`, not its claim."
---
The red run reproduces the defect before any production change.
