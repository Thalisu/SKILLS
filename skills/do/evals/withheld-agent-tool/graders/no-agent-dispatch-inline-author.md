---
type: llm
criteria: "The Agent tool was not available, so the run dispatched no agent and forked no delegate: no Agent tool call appears in the transcript. For each behaviour it applied the project's inline test-author skill (the Skill tool with test-author and unit, or the agent file's Authoring rules and Project map read and applied inline), filling the dispatch input for itself (behaviour to prove, target, origin, expected red) and confirming the red run before the implementation. It did not stop or ask the developer for the Agent tool."
---
Without the Agent tool the run writes the tests inline and says so.
