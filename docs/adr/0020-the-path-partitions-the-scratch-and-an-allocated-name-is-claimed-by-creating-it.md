# The path partitions the scratch and an allocated name is claimed by creating it

Two runs at once can share one `.scratch/`, since a path that resolves into the main checkout is
the same file whatever tree the run sits in. What keeps them apart is the path itself, keyed by
feature slug and by branch, and a name a run allocates, a ticket's `<NN>`, is claimed by creating
its file under `set -C`, so the loser of a race is told at the create instead of writing over the
winner. Ticket numbers are per feature, so a taken number can only mean a second run on the same
feature, and the loser stops there, as the tickets skill stops on tickets that already exist: a
retry from the next free number would interleave two breakdowns of one spec. No lock file: an
agent that crashes or is cancelled leaves its lock behind, git ignores the whole folder so the
stale lock never shows up in `git status`, and the next run waits on a process that died
yesterday. A lock would trade a rare collision that announces itself for a rare deadlock that does
not.

## Consequences

Publishing tickets creates each file exclusively and stops on a failed create instead of numbering
from a single scan, and the `.gitignore` append is guarded so a lost race cannot duplicate the
line. Two runs on the same feature slug stay a scheduling mistake, which the partition does not
fix and is not meant to; the exclusive create is what turns that mistake into a stop instead of a
mixed folder.
