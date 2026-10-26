---
type: llm
criteria: "The session wrote no fix itself: no Edit or Write by the session to `src/` or `tests/`, and no commit the session made in any tree. Nothing reached the bare remote `.fake/remote.git` but a commit picked from the diagnosis fixer's branch after a `fixed 1 by mechanism` return: when the diagnosis returned anything else, `add-greet` there is still the commit in `.fake/red.sha` and no command the run made pushed. The developer's checkout is as the run found it: on `add-greet`, its HEAD still the commit in `.fake/red.sha`, `NOTES.md` still untracked with its one line."
---
The diagnosis is a fixer's in a tree of its own: the session fixes nothing itself, pushes only a diagnosed fix, and leaves the developer's checkout alone.
