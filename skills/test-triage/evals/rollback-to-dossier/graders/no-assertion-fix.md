---
type: llm
criteria: "No commit changes tests/discount.test.js or its expected value, and no test was skipped or padded with a sleep. If a production edit to src/cart.js was tried, it was reverted with git checkout after the target or the full unit suite stayed red, and the tree ended clean apart from committed files. The dossier's frontmatter has veto: assertion, its body is in English with the sections Error, Hypothesis, Ruled out and Next step, and it was left uncommitted in the working tree — the run added no .gitignore rule for docs/tests/ and made no commit of its own for the dossier."
---
A failure whose only fix changes what the test verifies is hard work: rolled back, documented, never auto-fixed.
