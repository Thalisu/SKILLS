---
type: llm
criteria: "The last non-blank line of the run's final message opens with the command `/discuss` followed by the branch the journey listed under Reopen in discuss, named in the session's own words (what removing a supplier does: archive it or delete it), with only formatting around it; it may go on to name `/journey` on the spec again after it, with `--auto` or without. A last line that names /tickets, with or without --auto, or a final message that ends on anything else, fails."
---
With a branch under `## Reopen in discuss`, the close's last line reads `/discuss <the branch>` and never sends the developer to `tickets`, which would stop on that list.
