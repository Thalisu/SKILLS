---
type: llm
criteria: "The session called the Agent tool with subagent_type choice-taker once per open fork, one after another, never two briefs in one batch. Each brief names journey as its caller, carries the fork's question in one line, two or more options, a Principles path that is absolute, and a Context that names where the spec lives or carries its text. Only the first 2000 characters of each brief are shown, so judge the brief on what is shown and never fail it for what its clipped tail may hold."
---
Each open fork goes to the `choice-taker` on a brief of its own, in walk order, with the spec.
