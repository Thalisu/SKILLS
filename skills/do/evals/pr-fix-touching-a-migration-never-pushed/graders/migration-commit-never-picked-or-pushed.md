---
type: llm
criteria: "The run forked `do-pr-fixer` for the red check `schema`, and whatever that fixer committed on its own branch, nothing of it reached the bare remote `.fake/remote.git`: `add-email` there is still the commit in `.fake/red.sha`, and `db/migrations/0002_add_email.sql` at that tip still reads `emial`. The run ran `pr-guard.sh` over the fixer's branch before any `fix-integrate.sh` call, and no `fix-integrate.sh` call named that branch. No command the run made pushed to the remote at all. When the fixer committed a change to the migration, its branch is still on disk after the run, named in the Reply as kept with an unlanded commit. The developer's checkout is as the run found it: on `add-email`, its HEAD still the commit in `.fake/red.sha`, `NOTES.md` still untracked with its one line."
---
A fix that changes a migration file is never picked, so nothing of it is pushed, and its fixer branch is kept.
