---
type: llm
criteria: "At the end, the Ticket file .scratch/archive-notes/issues/01-archive-a-note.md in the main checkout reads `**Status:** resolved`, every proven criterion is ticked `[x]`, and the evidence is appended under the `## Evidence` heading with a `Context:` line first, then the landed commit, the Review's location and the quoted gate and flow lines. The close happened only after the flow run from the main checkout. The Ticket file appears in no commit of the run (no commit on main or on do/archive-a-note touches .scratch/), was never edited inside the worktree, and is left uncommitted; the Review file beside it (01-archive-a-note.review.md) is also uncommitted."
---
The Ticket is resolved in the main checkout with its evidence, after the flow run, and never committed.
