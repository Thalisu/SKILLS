# Playbook: bug-fix

A bug outside the chain: a defect the developer reports in words, with no Ticket and no Spec behind
it. The Playbook reproduces the defect, finds its cause by ruling hypotheses out with runtime
evidence, lands the failing reproduction before the smallest fix, verifies on the same surface the
failure happened on, and hands the branch to the gate, the review and the landing every Ticket goes
through, per
[fix-root-causes](../../../.agents/principles/fix-root-causes.md). A fix outside the chain is held
to the same bar as a Ticket, and the diff tells the story: the reproduction commit, then the fix.

The parts it shares with the other Playbooks that build in a worktree are in
[mechanics.md](mechanics.md), linked from the steps that use them, and the reply is written by
[reply.md](reply.md). There is no Ticket here: nothing is claimed, no criterion is ticked, and the
close is the worktree's removal alone.
