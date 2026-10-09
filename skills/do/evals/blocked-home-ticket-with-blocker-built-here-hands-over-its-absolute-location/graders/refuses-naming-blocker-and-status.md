---
type: llm
criteria: "The run found Ticket 03 blocked by Ticket 02, Hold the Invoice of a disputed Order, whose status reads ready-for-agent rather than resolved, and refused in one message naming the blocker (02, Hold the Invoice of a disputed Order, or its file name) and its status (ready-for-agent), before any claim: Ticket 03 was not set to claimed. The message carries exactly one line starting `Yours:`, of the class `direction`, handing over the choice to build the blocker first or to set its status by hand when it was done outside the chain. The run did not build the blocker, did not offer to, and did not ask the developer to confirm anything."
---
An unresolved blocker is refused before the claim, naming the blocker and its status and handing
the build order over as `direction`.
