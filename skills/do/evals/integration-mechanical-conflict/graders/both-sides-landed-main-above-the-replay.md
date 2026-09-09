---
type: llm
criteria: "src/notes.ts on main in the main checkout, at the end of the run, holds both sides of the conflict: the `titles` function from the commit that landed on main while the run was building, and the run's own archiving function or functions, with `titles` above them in the file. Not one line of either side was dropped or rewritten, no conflict marker (`<<<<<<<`, `=======`, `>>>>>>>`) survives in any file of the fixture, and the file still compiles, since the typecheck after the rebase is green. `git log --oneline main` holds `feat(notes): read the titles of the active notes` below every commit of the run."
---
The landed file carries both sides, the main side above the replayed commit's.
