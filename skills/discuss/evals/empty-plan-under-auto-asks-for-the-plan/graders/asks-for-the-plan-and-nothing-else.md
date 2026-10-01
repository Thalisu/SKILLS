---
type: llm
criteria: "The run's final message asks the developer for the plan (what to discuss: the plan, feature or change) and carries nothing else: no grounding note about the repository, no tree of branches, no question about a design decision, no recommendation, no Rulings section and no closing summary. The session never proposes or picks a plan of its own, from the repository or anywhere else, and never discusses one."
---
`--auto` never supplies the plan: with the flag alone the plan is empty, and it is asked for in one
message carrying nothing else, as it is without the flag.
