---
type: llm
criteria: "No Planner could be forked, so the session grounded the Ticket and wrote the Plan itself: the transcript carries one line saying the Agent tool is withheld, naming that branch and not the other (no `do-planner` agent listed), and the Plan was written by the session at .scratch/archive-notes/issues/01-archive-a-note.plan.md, with a `## Sources` section holding exactly the two records the door hashed, `ticket: <path> <hash>` and `digest: <path> <hash>`. The run neither stopped nor asked the developer for the tool, and it forked no other agent in the Planner's place. The same holds at the build step: the session ran the build loop itself and said which of the two branches held, and no agent stood in for the Builder."
---
With the Agent tool withheld the session writes the Plan and runs the loop itself, and forks nobody in either fork's place.
