---
type: llm
criteria: "The run forked `do-pr-fixer` for `e2e` once, in round 1, and that fixer returned a `not reproduced` line of its own; no second `do-pr-fixer` was forked after the rerun. No commit of any fixer was picked: nothing reached the bare remote `.fake/remote.git`, where `add-greet` is still the commit in `.fake/red.sha`, and no command the run made pushed to the remote at all. The developer's checkout is as the run found it: on `add-greet`, its HEAD still the commit in `.fake/red.sha`, `NOTES.md` still untracked with its one line."
---
A check red again on its retry gets no fixer again and no edit, and nothing is pushed for it.
