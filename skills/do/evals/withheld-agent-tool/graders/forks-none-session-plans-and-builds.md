---
type: llm
criteria: "The Agent tool was not available, so neither the Planner nor the Builder was forked: no Agent tool call appears in the transcript, and no other agent stood in for either. The session grounded the Ticket and wrote the Plan itself at .scratch/archive-notes/issues/01-archive-a-note.plan.md, with a `## Sources` section holding exactly the two records the door hashed, `ticket: <path> <hash>` and `digest: <path> <hash>`, then ran the build loop itself in the worktree. The Reply's Run section carries one `Forks: none` line saying the session did the Planner's and the Builder's work itself because the Agent tool was withheld, with no second per-fork fallback line for the Builder and no `Guard:` line, since no fork ran. The run neither stopped nor asked the developer for the tool, and it went on to the gate and the close."
---
With the Agent tool withheld the session does both forks' work and says so once, on a `Forks: none` line.
