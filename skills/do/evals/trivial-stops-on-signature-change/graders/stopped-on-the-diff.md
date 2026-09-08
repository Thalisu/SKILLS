---
type: llm
criteria: "The run edited src/notes.js first (the door on the request let a parameter rename through as a rename inside one file), then ran the door script on the diff (trivial-door.sh diff src/notes.js), and only then stopped. A run that refused before any edit, without running the script on the diff, fails this grader: the case exists to exercise the second door check and the restore."
---
The second door check runs on the diff and is what stops the run.
