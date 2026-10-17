---
type: llm
criteria: "Judge this on the run's final message only, the text after FINAL MESSAGE. Pass only when both hold. First, the message says Ticket 01 is refused because it is blocked by Ticket 02, Return the reason of a dispute (by number, title or file name), and gives that blocker's status, ready-for-agent. Second, it tells the developer that what the earlier run left of Ticket 01 stands, naming all three: the claim (the Ticket is still claimed, or its claim stands), its worktree (do-hold-the-invoice-of-a-disputed-order, or the do/hold-the-invoice-of-a-disputed-order branch with the word worktree) and the commits already made on it. A message that reads as a refusal `before the claim`, or that says only that nothing was written, fails."
---
The refusal across two repositories still says the half-built Ticket is kept in the repository it
is built in.
