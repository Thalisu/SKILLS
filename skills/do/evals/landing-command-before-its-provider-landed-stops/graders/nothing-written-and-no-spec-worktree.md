---
type: llm
criteria: "Judge this on the section `What the run changed in the fixture` only. Pass only when all of these hold. First, the list of files created, changed or deleted reads `no file changed`: no file of the fixture differs, so no claim file such as `spec.orders-service.integration.claim` was written under ./.scratch/ and no worktree was laid under ./.claude/worktrees/. Second, under `Commits the run made` the text reads `no commit`. Third, under `Branches after the run` both main and spec/hold-disputed-invoice are listed and no other branch. Fourth, under `Worktrees after the run` the main checkout is the only worktree listed: no `spec-hold-disputed-invoice` worktree."
---
The run stops before integrating anything: no claim file under the consumer's key, no worktree for
its Spec branch, no commit, and its Spec branch still beside `main`.
