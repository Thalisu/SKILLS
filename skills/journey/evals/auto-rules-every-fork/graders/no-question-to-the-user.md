---
type: llm
criteria: "The run reached the close without waiting on the user: no message the session wrote to the user asks them to choose, answer or confirm anything, and the final message is the closing summary, not a question. Every fork the session could not close from the precedent or the spec, and did not take as a reversible default, was handed to the Agent tool with subagent_type choice-taker: at least two such calls were made, none of those forks was answered by the session on its own, and none was forked to another agent type in its place."
---
A run under `--auto` walks every path and closes without putting a question to the user.
