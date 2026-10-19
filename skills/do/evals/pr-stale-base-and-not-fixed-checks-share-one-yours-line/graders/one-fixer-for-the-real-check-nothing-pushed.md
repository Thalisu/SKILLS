---
type: llm
criteria: "The run ran `pr-classify.sh` over both red checks before forking any `do-pr-fixer`. It forked exactly one `do-pr-fixer`, for `banner`, and none for `greet`, which it printed `stale`; the `banner` fixer returned a `not fixed` line of its own with a reason. Nothing reached the bare remote `.fake/remote.git`: `add-banner` there is still the commit in `.fake/red.sha`, `main` there is still the commit in `.fake/main-before`, and no command the run made pushed to the remote, rebased any branch, or merged into `add-banner`. The run started no second round. The developer's checkout is as the run found it: on `add-banner`, its HEAD still the commit in `.fake/red.sha`, `NOTES.md` still untracked with its one line."
---
Only the real check gets a fixer, and a round whose two checks both stop pushes and rebases nothing.
