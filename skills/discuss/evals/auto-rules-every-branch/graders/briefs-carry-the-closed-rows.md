---
type: llm
criteria: "The session called the Agent tool with subagent_type choice-taker more than once, one call per branch, one after another in the order of the tree it showed, never two briefs in one batch. Each brief names discuss as its caller, carries the branch's question, two or more options, a Principles path that is absolute, and a Context that holds the plan's own text and the grounding note's text. Every brief after the first also holds, in its Context, the one-line row of each branch the session had closed before it (ruled by an earlier fork, or closed from the repository), including the side taken on the branch ruled just before it."
---
Each open branch is forked to the `choice-taker` in walk order, with the plan, the grounding note and every branch already closed.
