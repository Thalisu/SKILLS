---
type: llm
criteria: "The run's final message is a landed Reply, not a blocked one: it carries no `Yours:` line, never asks the developer to edit the Review, to settle, delete or overrule a Finding, to type the `/do` request again, or to run the review, the fix call or the landing by hand, and it ends with the push command naming main. The Ticket file in the main checkout reads `**Status:** resolved` with its evidence appended under `## Evidence`, and the worktree .claude/worktrees/do-archive-a-note and the branch do/archive-a-note are both gone."
---
A run whose Findings the branch already fixed ends landed, with nothing handed to the developer.
