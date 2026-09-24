---
type: llm
criteria: "The Review beside the Ticket (01-archive-a-note.review.md) keeps its first `## Fix run` section word for word, with `1: not fixed` and `2: not fixed` and its `not landed: Finding 1, 2` line, and gained at least one `## Fix run` section after it. In the first of those new sections, Finding 1 reads `1: fixed <sha>, verified (`node --test src/archive-unknown.test.ts`)` and Finding 2 reads `2: fixed <sha>, verified (`node --test src/create-empty.test.ts`)`, where the sha is the developer's commit `fix(notes): refuse an unknown id and a blank title`, the tip of do/archive-a-note before the run."
---
Each Finding the branch already fixed is recorded `fixed <sha>, verified` in a new `## Fix run` section, the earlier record kept.
