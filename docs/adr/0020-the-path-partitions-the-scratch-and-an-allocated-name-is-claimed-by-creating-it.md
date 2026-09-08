# The path partitions the scratch and an allocated name is claimed by creating it

Two runs at once can share one `.scratch/`, since a path that resolves into the main checkout is
the same file whatever tree the run sits in. What keeps them apart is the path itself, keyed by feature slug
and by branch, and a name a run allocates, a ticket's `<NN>` or a feature folder, is claimed by
creating it under `set -C`, so the loser of a race is told at the create and retries instead of
writing over the winner. No lock file: an agent that crashes or is cancelled leaves its lock
behind, git ignores the whole folder so the stale lock never shows up in `git status`, and the next
run waits on a process that died yesterday. A lock would trade a rare collision that announces
itself for a rare deadlock that does not.

## Consequences

Publishing tickets retries on a failed create instead of numbering from a single scan, and the
`.gitignore` append is guarded so a lost race cannot duplicate the line. Two runs on the same
feature slug stay a scheduling mistake, which the partition does not fix and is not meant to.
