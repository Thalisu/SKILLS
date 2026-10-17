---
type: llm
criteria: "Judge this on the section `What the run changed in the fixture` only. Pass only when all of these hold. First, the list of files created, changed or deleted reads `no file changed`: no file of the fixture differs, so no claim file, no Review, no Digest and no Plan was written under ./.scratch/ and no worktree was laid under ./.claude/worktrees/. Second, under `Commits the run made` the text reads `no commit`. Third, under `Branches after the run` main is the only branch listed. Fourth, under `Worktrees after the run` the main checkout is the only worktree listed."
---
Nothing is done in the repository that already landed: no file written, no commit, no branch and
no worktree beside what the fixture set up.
