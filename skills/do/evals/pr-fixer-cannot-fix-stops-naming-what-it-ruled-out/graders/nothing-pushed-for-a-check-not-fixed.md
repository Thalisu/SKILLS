---
type: llm
criteria: "The run forked `do-pr-fixer` for the red check `banner`, and that fixer returned a `not fixed` line of its own with a reason (not `the fixer did not return`). Nothing reached the bare remote `.fake/remote.git`: `add-banner` there is still the commit in `.fake/red.sha`, and `tests/banner.sh` and `src/banner.txt` at that tip are as the scaffold wrote them. No command the run made pushed to the remote at all, and the run started no second round and forked no second `do-pr-fixer` for `banner`. The developer's checkout is as the run found it: on `add-banner`, its HEAD still the commit in `.fake/red.sha`, `NOTES.md` still untracked with its one line."
---
A fixer that reports it cannot fix its check gets nothing pushed, and the run does not churn on it.
