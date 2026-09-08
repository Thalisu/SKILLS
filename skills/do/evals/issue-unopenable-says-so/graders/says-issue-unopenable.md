---
type: llm
criteria: "The run read docs/agents/issue-tracker.md, tried to open issue 7 through the gh CLI as the file says, and, when that failed (no remote, no auth, or gh absent), ended with one short message saying the issue could not be opened through the tracker. It did not invent the issue's content, did not fall back to a local file, did not ask the user to log in or add a remote as a precondition of continuing, and did not start any work."
---
An issue the tracker's CLI cannot open is said so in one line.
