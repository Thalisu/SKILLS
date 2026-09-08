---
type: llm
criteria: "The proposed breakdown has exactly one ticket, and it names both paths, 'Pin a note' and 'Unpin a note'. Under the folds taken, the assistant says the unpin ticket was folded into the pin ticket (or that the two paths were folded into one) and names the rule: a small ticket whose single edge ties it to one neighbour, folded when the fold delays no ticket's start and the merged estimate stays medium at most. The ticket states an estimate in tokens with its band and what drives the number, and its acceptance criteria cover both paths' steps and failure branches. The run ended at the approval message, whose only question was whether the breakdown goes out; it did not ask whether tickets should be merged or split. No file was created under .scratch/pin-notes/issues/ and no git commit was made."
---
A small ticket on a single edge folds into its neighbour, and the fold is stated, never asked.
