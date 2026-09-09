---
type: llm
criteria: "`.git/do-code-review-landings.log` holds one `landed at <sha>` line and `main` points at that commit, so the review's stand-in did the fast-forward. The run itself ran no `git merge`, no `git rebase` and no `git push`, and the fixture has no remote. After the run `git worktree list` shows one entry, the main checkout, and no `do/` branch remains. The uncommitted line in `README.md` is still there, untouched and uncommitted, and no commit of the run touches `README.md`."
---
The landing is the review's fast-forward, nothing is pushed, and the worktree is gone.
