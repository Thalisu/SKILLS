---
type: llm
criteria: "Judge this on the section `What the run changed in the fixture` only. Pass only when all of these hold. First, the files ./.scratch/hold-disputed-invoice/spec.orders-service.integration.claim and ./.scratch/hold-disputed-invoice/spec.orders-service.integration.yielded each appear on a `<` line and on no `>` line: both were deleted. Second, under `Branches after the run` no branch spec/hold-disputed-invoice is listed. Third, under `Worktrees after the run` only the fixture's main checkout is listed, with no worktree under .claude/worktrees/."
---
A resumed landing that finishes ends at the release: the claim and its yielded mark are gone from
beside the Spec, and so are the Spec branch and its worktree.
