# The integration rebases onto the remote branch, and a conflicting pull request is resolved by merge

Before the review, the integration fetches and rebases onto `origin/<branch>`, not the developer's
local branch, and the review's fixed point is that merge base, so the **Review** reviews exactly the
diff the pull request shows: a local branch ahead of the remote would put the developer's unpublished
commits in it, and a remote ahead of the local branch would open it conflicting. The developer's
local branch is never touched. After `gh pr create` the run reads `gh pr view --json mergeable`; on
`CONFLICTING`, the target having moved between the fetch and the create, it merges
`origin/<branch>` into the head through the existing conflict loop, lands the resolution through
`fix` and the **Gate** with no second review (ADR 0044), pushes without force and leaves the pull
request open. A merge, unlike a rebase or a cherry-pick, keeps the push a fast-forward, so ADR 0117's
"never forced" holds; a squash on GitHub removes the merge commit where linear history matters.

This amends ADRs 0029 and 0044.

## Considered options

- Re-running the rebase loop and pushing with `--force-with-lease` pinned to the run's own sha: a
  second exception to "never forced".
- Cherry-picking onto the new tip: a hand-made rebase, the same rewrite and the same forced push.
- Stopping the run as blocked on `CONFLICTING`.
