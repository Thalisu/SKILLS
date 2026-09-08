---
type: llm
criteria: "The final reply opens with `Playbook: ticket` and follows the reply reference's sections in order: for whom, inherited, commits, evidence (the gate and flow command lines with their output lines quoted), principles (each beside the decision it changed, or `none`), skipped, a PR-ready description with exactly the headings Why, Scope, Tradeoffs, Blast Radius and Verification, left uncommitted (listing the Ticket file and the Review file), pending debt, and a next step whose last line is the push command `git push` naming main. No `## Summary` and no `## Test plan`."
---
The reply carries the PR sections, lists the Ticket and the Review as left uncommitted, and ends with the push command.
