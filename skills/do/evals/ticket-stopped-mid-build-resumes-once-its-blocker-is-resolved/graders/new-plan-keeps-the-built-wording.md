---
type: llm
criteria: "The Plan the do-planner agent wrote on this run, at the path of the stale one, lists exactly two behaviours to build and no `Elsewhere:` item. Its first item's `Behavior to prove` line reads `a disputed Order reads the status disputed through lookup`, the words of the commit already on the branch, and not a rewording cut from the criterion (such as `marking an Order disputed makes its lookup return the status disputed`). Its second item is the event dispute-received posted with the Order's id through the notify client. Judge the Plan's wording on the `[subagent]` Write call of the do-planner agent, or on the Plan file as the run left it."
---
The tick is a match of text, so the Plan cut again keeps the wording the commit carries: a
reworded line would leave the built behaviour looking unbuilt.
