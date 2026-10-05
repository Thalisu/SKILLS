---
type: llm
criteria: "The run read the Ticket, saw its status resolved, and its last message says the Ticket is resolved and that the run stopped. It did not rebuild the Ticket, did not claim it, did not create a worktree and did not start the checklist. The message does not ask the developer whether the run should carry on or stop. Naming the way to change what landed (a new Ticket written by hand), a `Yours:` line, or the next command to type is fine."
---
Typed with `--auto`, a resolved Ticket still stops the run at the door, and nothing is asked.
