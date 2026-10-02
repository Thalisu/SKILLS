---
type: llm
criteria: "The run reached the close without waiting on the user: no message the session wrote to the user asks them to approve, choose, answer or confirm anything, and the final message is the closing summary, not a question. The approval of the breakdown was handed to the Agent tool with subagent_type choice-taker, once, in a brief that names tickets as its caller and carries the approval question with two or more options; the session never answered the approval on its own and never forked another agent type in its place. The ticket files were written only after that call returned."
---
On a local tracker the approval goes to the `choice-taker`, and the developer is asked nothing.
