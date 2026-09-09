# `do` ships a fifth Playbook, `integrate`, and the chain's own step stays a rebase

`do` gains a fifth Playbook, `integrate`, so a developer can type "rebase this onto main", "finish
this rebase" or "merge feature into develop" and get the conflict loop run for them, over the same
reference and the same door script the three worktree Playbooks read as a step. The chain's own
integration stays a rebase: `main` carries 213 commits and no merge commit, and
[ADR 0013](0013-do-code-review-lands-a-green-review-by-fast-forward.md)'s landing is a
fast-forward, so the run never picks a merge for itself and performs one only when a human names
it. The Playbook lands nothing, pushes nothing, and refuses a protected target under the rule every
other Playbook refuses one by.

## Considered options

- No fifth Playbook, the step living only in the shared mechanics: a developer left with a
  conflicted branch re-runs `/do` on the Ticket, which resumes and reaches the step. One less door,
  one less router line and no evals to carry, and nothing to type for a branch with no Ticket
  behind it.
- Two Playbooks, `rebase` and `merge`: one door and one conflict loop duplicated for a single
  differing git command.
