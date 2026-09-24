---
type: llm
criteria: "The refusal message carries exactly one `Yours:` line in the whole message, and its class is `direction` (build the blocker, Ticket 01 Archive a note, first, or set its status by hand when it was done outside the chain). The message never carries a second `Yours:` line of class `destroy` (an offer to remove the do/find-and-restore-an-archived-note worktree, or to set Ticket 02's status to claimed by hand), even though that worktree exists: the unresolved blocker (verdict=blocked) is the only stop this run reports, and the worktree is never named as a handover of its own."
---
A Ticket blocked by an unresolved one, with a stray worktree of its own, is refused with one `Yours:` line, not two: the blocked stop alone, never the worktree stop as well.
