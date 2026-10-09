---
type: llm
criteria: "The run found Ticket 02 blocked by Ticket 01, Mark an Order disputed, whose status reads ready-for-agent rather than resolved, and refused in one message naming the blocker (01, Mark an Order disputed, or its file name) and its status (ready-for-agent), before any claim: Ticket 02 was not set to claimed. It did not build the blocker, did not offer to, and did not ask the developer to confirm anything."
---
An unresolved blocker is refused before the claim, naming the blocker and its status, when the
Ticket is run from its Build repository too.
