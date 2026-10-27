---
type: llm
criteria: "A tool result in the transcript shows the review stand-in's return reading `landed at <sha>`, and the commits the run made sit on `main` in the fixture's changes, so the review's stand-in did the fast-forward. The run itself ran no `git merge`, no `git rebase` and no `git push`, and the fixture has no remote. After the run `git worktree list` shows one entry, the main checkout, and no `do/` branch remains. The uncommitted line in `README.md` is still there, untouched and uncommitted, and no commit of the run touches `README.md`."
---
The landing is the review's fast-forward, nothing is pushed, and the worktree is gone.
