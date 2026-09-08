---
type: llm
criteria: "Before or within the breakdown, the assistant says the estimates are calibrated from the resolved ticket 01-export-notes-as-one-file (or from the export-notes feature) and states the figures it read: a fixed load of 41000 tokens (the grounded reading) and a per-criterion cost of 28000 tokens (97000 minus 41000 over 2 criteria). Every ticket's estimate is that fixed load plus 28000 per criterion, stated with its band, and no estimate is described as uncalibrated or on the defaults. The run ended at the approval message, whose only question was whether the breakdown goes out. No file was created under .scratch/pin-notes/issues/, the resolved export ticket was not edited, and no git commit was made."
---
A resolved ticket's Context line calibrates the next cut, and the breakdown says which figures it read.
