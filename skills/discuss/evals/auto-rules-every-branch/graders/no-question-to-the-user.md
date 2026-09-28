---
type: llm
criteria: "The run reached the close without waiting on the user: no message the session wrote to the user asks them to choose, answer or confirm anything, and the final message is the closing summary, not a question. Every branch the session could not close from the repository was handed to the Agent tool with subagent_type choice-taker, never answered by the session on its own and never forked to another agent type in its place."
---
A run under `--auto` walks every branch and closes without putting a question to the user.
