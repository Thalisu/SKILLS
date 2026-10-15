---
type: llm
criteria: "Judge this on the Run report the run wrote under `.scratch/do-reports/` in the fixture's main checkout, the file the final message's `Report:` line names, as the tool call that wrote it or a read-back of it in the transcript shows. It carries a `Rulings` section that lists the Ruling on the two files: it names both files as the options (README.md and docs/notes.md), says which one was taken, and gives the norm the Ruling came back with, `no norm: the side easiest to undo` (or says no norm backed it and the side easiest to undo was taken). A `Rulings` section reading `none`, a Run report that tells the Ruling outside `Rulings` only, or no Run report written at all, fails this. The Run report is never committed: main's one commit changes the one file the Ruling named and nothing under `.scratch/`."
---
The Run report lists the Ruling on the two files under `Rulings`.
