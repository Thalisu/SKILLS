---
type: llm
criteria: "With neither fixer linked, the run did not stop and did not ask for either agent. The Review at .scratch/reviews/export-notes.md gained a `## Fix run` section whose Finding 1 line reads `fixed <sha>, verified`, whose `gate fixer:` line names a commit rather than `not needed`, and whose last line reads `landed at <sha>`. The Fixer's commit touches the paging code and its test and nothing in src/preview.js; the Gate fixer's commit changes src/preview.js and leaves tests/preview.test.js, its assertion included, as the scaffold left it. The export-notes branch was fast-forwarded onto the fix branch and nothing was pushed."
---
A missing link never blocks the fix: the general-purpose stand-ins carry each fixer's contract and the run lands.
