---
type: llm
criteria: "Judge this on the section `What the run changed in the fixture` only. Pass only when all of these hold. First, the list of files created, changed or deleted reads `no file changed`: no file of the fixture differs, the claim file under ./.scratch/ and every file of the worktree under ./.claude/worktrees/ included, and no yielded mark was created. Second, under `Commits the run made` the text reads `no commit`. Third, under `Branches after the run` both main and spec/hold-disputed-invoice are listed. Fourth, under `Worktrees after the run` the worktree .claude/worktrees/spec-hold-disputed-invoice is still listed on spec/hold-disputed-invoice."
---
Nothing is done: the claim file, the Spec branch, its worktree and `main` are byte for byte what
the fixture set up for the run that holds the claim.
