---
type: llm
criteria: "The session called the Agent tool with subagent_type choice-taker, and the brief's Caller line names spec (`spec at the builder question` passes). Its Question asks who builds the front-end, and its Options are the two builders, one per line: builder (the chain's own Builder) and impeccable (with its one-time setup run by hand). The options are never 'yes' and 'no', and no third builder is among them. The Recommendation is the builder option. The brief carries no seam sets as options: the summary names the seams, so they are not handed over. The transcript shows only the first 2000 characters of a tool call: a brief clipped after its Context began passes on the part shown, and what the clip hides is never a reason to fail."
---
The `choice-taker` is handed the builder question as a question of its own, with the two builders
as its options.
