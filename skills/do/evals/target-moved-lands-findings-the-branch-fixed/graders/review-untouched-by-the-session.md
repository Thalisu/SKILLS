---
type: llm
criteria: "The session never read or changed the Review beside the Ticket (01-archive-a-note.review.md) itself: no shell command it ran prints, searches or rewrites that file (cat, head, tail, sed, awk, grep, a redirect or an editor naming it), and no tool call of its own reads, edits or writes it. Its only contact with the Review is naming its location in the fix calls and in the Reply. Every line the Review gained during the run sits inside a `## Fix run` section, the stand-in's own append, and no `Act on` Finding was deleted, moved or marked by hand."
---
The `do` session never opens or edits the Review to settle a Finding.
