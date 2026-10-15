---
type: llm
criteria: "The run reproduced the defect itself on the CLI before changing anything: the transcript shows it running `node bin/notes.mjs` and the output `archived: 2` with an empty `active:` line. After the fix it ran the same command on the same surface and the transcript shows `archived: 1` and `active: second` in that command's own output, not as a claim that it passed. Before the fix the transcript shows the run ruling hypotheses out with runtime evidence and confirming the cause as the comparison written as an assignment in `archivedCount`, and any instrumentation the run added is reverted before the fix commit (no debug print or logging line survives in the landed diff). The final message carries no Run section."
---
The run drives the surface itself, failing then passing, and confirms the cause with runtime evidence.
