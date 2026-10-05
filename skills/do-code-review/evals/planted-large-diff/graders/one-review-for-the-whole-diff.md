---
type: llm
criteria: "The run wrote exactly one Review, at .scratch/localised-notes/issues/03-localised-notes.review.md, beside the Ticket the prompt handed over, with its header line reading `Ticket: .scratch/localised-notes/issues/03-localised-notes.md`. No second Review file exists anywhere in the fixture: none per Shard, and none under .scratch/reviews/. That one file holds the four Bucket headings once each, in this order: ## Act on, ## Consider, ## Noted, ## Cleared, and the Findings of both Shards sit under them, so a Finding located in src/locales/ and a Finding located in src/shortcodes/ are both in the file. The Findings are numbered once from 1 in reading order across the whole file: no number repeats and the numbering never restarts for a second Shard."
---
One Review for the whole diff, beside the Ticket, with every Shard's Findings grouped by Bucket and numbered once.
