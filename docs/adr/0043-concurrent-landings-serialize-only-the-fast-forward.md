# Concurrent landings serialize only the fast-forward, under a lock one script call holds

Several `do` runs build at once, each in its own worktree, and every one of them lands on the same
developer's branch, the one write target they cannot each own (ADR 0013). Two fast-forwards at once
raced on the main checkout's index and on the branch's ref, and the loser failed as "any other
reason" and stopped the run as blocked. The fast-forward alone now runs under an exclusive lock on
a file in the git common directory, taken and released inside one script call, so the operating
system frees it when the process ends and no dead session leaves it behind. Rebases, reviews and
**Gates** keep running concurrently, and a run that finds the target moved integrates again
(ADR 0044).

## Considered options

- One lock held across the whole landing (the re-integration, the **Gate** and the fast-forward):
  no run ever repeats a **Gate**, but the lock outlives a single call, so it needs an owner, a
  staleness rule for a session that died holding it, and waiting runs that poll.

## Consequences

This is the one lock file in the chain. ADR 0020's "never a lock file" governs names allocated in
the scratch, not the developer's branch. A lock held by the developer's own git command is waited
on briefly inside the same call before the fast-forward counts as failed.
