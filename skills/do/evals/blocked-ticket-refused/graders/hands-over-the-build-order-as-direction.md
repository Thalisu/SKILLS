---
type: llm
criteria: "The refusal message carries one line reading `Yours: direction:` followed by the choice it hands the developer: build the blocker (Ticket 01, Archive a note) first, or set its status by hand when it was done outside the chain (both options, or equivalent wording naming both). The class on that line is `direction` and no other word (not `destroy`, `trust` or `outward`), there is exactly one `Yours:` line, and the run neither builds the blocker nor sets any status itself to act on that choice."
---
An unresolved blocker hands the build order to the developer under the `direction` class.
