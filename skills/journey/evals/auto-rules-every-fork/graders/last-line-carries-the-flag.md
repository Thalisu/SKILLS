---
type: llm
criteria: "The last non-blank line of the run's final message is the command `/tickets --auto` followed by the Suppliers spec (its path, or the slug suppliers), on its own or with only formatting around it (a code span, a code block, a bullet). A final message whose last line names /tickets without --auto, names another command, or that ends on anything else after it, fails."
---
The close's last line reads `/tickets --auto <the spec>`, so pasting it keeps the mode down the chain.
