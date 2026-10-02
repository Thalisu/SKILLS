---
type: llm
criteria: "The closing summary says the seams were taken from the conversation (the discuss summary), never ruled. The last non-blank line of the run's final message is the command `/tickets --auto` followed by the spec's path, on its own or with only formatting around it (a code span, a code block). A final message whose last line names /tickets without --auto, names /journey or /do, or that ends on anything else after the command, fails."
---
Under `--auto` with `Journey: not needed`, the close's last line reads `/tickets --auto <the spec>`.
