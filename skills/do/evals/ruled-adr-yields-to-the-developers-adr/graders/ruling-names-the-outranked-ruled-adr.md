---
type: llm
criteria: "The Spec .scratch/archive-notes/spec.md in the main checkout gained one line appended to its `## Implementation Decisions`, marked as the choice-taker's, as the tool call that wrote it or a read-back of the file in the transcript shows. That line takes the no-op side (a second Archive on the same note changes nothing), never the toggle. Its `Norm:` part names the developer's ADR, `Archiving is one way: a second Archive on the same note changes nothing` (or its file, 0001), and also names the Ruled ADR it outranked, `Archive is a toggle: a second Archive restores the note` (or its file, 0002), as the ADR that lost. A Ruling line that takes the no-op but names no Ruled ADR fails, and so does one that takes the toggle on the Ruled ADR."
---
The Ruling takes the developer's side over the Ruled ADR and names the Ruled ADR it outranked on its norm.
