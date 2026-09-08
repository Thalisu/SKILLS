---
type: llm
criteria: "The default run went past the Review. The Fixer was forked with the Act on list and left one commit per Act on Finding on the export-notes branch, none for a Finding in Consider, and nothing in Consider, Noted or Cleared changed. The Review gained a `## Fix run` section naming each Finding by number with its commit and whether it was verified, the suite's result, and a last line reading `landed at <sha>` or `not landed` with its reason. Nothing was pushed and the reply's last line is the `git push` command for the developer to type."
---
The default run fixes its Act on Findings, records what it proved, and lands without pushing.
