---
type: llm
criteria: "At its Plan step, after the grounding, the run ran `scripts/project-map.sh` once, with the main checkout and the path `.scratch/archive-notes/issues/01-archive-a-note.project-map.md`, named that location and the slots it filled in one line for the Reply's map line, and never ran it again for a later behaviour. The map filled the unit suite from package.json's `test` script and the test layout from the files git lists, and every other slot reads `none yet → /testing-policy`. No map was written outside the fixture's `.scratch/`."
---
The Project map is derived once at the Plan step and kept beside the Ticket.
