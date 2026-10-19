---
type: llm
criteria: "The run ran `pr-classify.sh` over the round's red check `greet` and forked no `do-pr-fixer` at all: not for `greet`, which it printed `stale`, and not for any other check. Nothing reached the bare remote `.fake/remote.git`: `add-sum` there is still the commit in `.fake/red.sha`, `main` there is still the commit in `.fake/main-before`, and no command the run made pushed to the remote, rebased any branch, or merged into `add-sum`. The developer's checkout is as the run found it: on `add-sum`, its HEAD still the commit in `.fake/red.sha`, `NOTES.md` still untracked with its one line, and `src/greet.sh` still printing `helo`."
---
A check that fails only in files the pull request never changed gets no fixer, and nothing is pushed or rebased to clear it.
