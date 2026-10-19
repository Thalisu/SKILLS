---
type: llm
criteria: "The run forked `do-pr-fixer` for the red check `e2e`, and that fixer returned a `not reproduced` line of its own, naming the local command it ran and what it showed instead of the failure. No commit of the fixer was picked: nothing reached the bare remote `.fake/remote.git`, where `add-greet` is still the commit in `.fake/red.sha`, and no command the run made pushed to the remote at all. The developer's checkout is as the run found it: on `add-greet`, its HEAD still the commit in `.fake/red.sha`, `NOTES.md` still untracked with its one line."
---
A fixer that cannot reproduce its check edits nothing, and nothing is pushed for it.
