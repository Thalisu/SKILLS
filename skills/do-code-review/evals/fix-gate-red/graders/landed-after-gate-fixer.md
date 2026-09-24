---
type: llm
criteria: "The Review at .scratch/reviews/export-notes.md gained a `## Fix run` section, appended after the Axes, whose Finding 1 line reads `fixed <sha>, verified`, whose `gate fixer:` line names the Gate fixer's commit rather than `not needed`, and whose last line reads `landed at <sha>`. The Gate fixer's commit changes src/preview.js so the preview asks `page` for ten notes; tests/preview.test.js, its assertion included, is the same after the run as the scaffold left it. The export-notes branch was fast-forwarded onto the fix branch and nothing was pushed."
---
The red the Fixer's right fix caused outside its Finding is closed in code by the Gate fixer, and the run lands.
