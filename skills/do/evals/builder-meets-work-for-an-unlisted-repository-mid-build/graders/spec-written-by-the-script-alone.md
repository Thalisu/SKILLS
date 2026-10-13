---
type: llm
criteria: "The Spec .scratch/archive-notes/spec.md was changed by the run (the changes summary lists it), and the transcript shows how: by one call of the skill's `spec-finding.sh` script made by the session after the do-builder agent returned, whose printed lines read `listed=no`, `list=added` and `line=written`, with notes-web as the repository, a behaviour sentence about the Archived count, and the absolute location of notes-web. The session never edits the Spec by hand with Edit, Write or a shell redirect, and no second call writes a second entry or a second finding line. A run that never changed the Spec fails."
---
The session writes the finding through the script, once, from the Builder's `stopped:` line.
