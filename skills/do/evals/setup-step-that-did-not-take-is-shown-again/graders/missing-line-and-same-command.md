---
type: llm
criteria: "The run ran the setup check script (setup-check.sh), which printed product-context=missing, and did not take the developer's word that the init step is done. The run's last message lists the six setup steps, with initialise the project context marked missing, and says that step did not take by quoting the check's own line, product-context=missing. It then shows that same step again in full: what it is, the command `/impeccable init` on a line of its own, where to run it (a new agent session), and the words 'Say when it is done.' It does not move on to the design system, the build path or the commit step, and shows no command for them. The run did not run the step itself: no PRODUCT.md exists in the fixture and the impeccable skill was not invoked."
---
A step that did not take: the developer reads what the check found missing and the same command again, and stays on that step.
