---
type: llm
criteria: "git log on the branch since the fixture commit reads, in order, a subtraction commit that only deletes (the dead countArchived helper) and carries the still-red target-interface test, then one or more reshape commits that move the status onto the new module and migrate the CLI, then a cleanup commit that deletes the equivalence harness. Each commit is staged by path, never with -A or a bare dot. Nothing was pushed. The reply lists the three in that order with their short shas and states the exit test, whether the reader's load is lower, in one line with its reason."
---
The commits read subtraction, reshape, cleanup, so one revert undoes one slice.
