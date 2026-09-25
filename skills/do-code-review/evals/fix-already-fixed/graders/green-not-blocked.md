---
type: llm
criteria: "The run ends Green: the new `## Fix run` section carries a gate line that reads green, and its last line does not read `not landed`. Since the Review judged the branch the checkout is on and no Fixer committed, the run says there is nothing to land, and nothing was pushed. The reply asks the developer to edit nothing in the Review."
---
A fix call whose only Finding the branch already fixed ends Green, with nothing asked of the developer.
