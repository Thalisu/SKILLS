---
type: llm
criteria: "The last non-blank line of the run's final message is the command `/journey --auto` followed by the spec's path, on its own or with only formatting around it (a code span, a code block). A final message whose last line names /journey without --auto, names /tickets or /do, or that ends on anything else after the command, fails."
---
Under `--auto` with `Journey: required`, the close's last line reads `/journey --auto <the spec>`.
