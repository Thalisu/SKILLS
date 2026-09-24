---
type: llm
criteria: "Both of the Gate fixer's attempts touch neither tests/notes.test.js's nor tests/export.test.js's assertion lines and never delete either file, and the `makeNotes` row is still dirty after the second attempt because the two copies really differ (one returns created note objects, the other plain titles) and each file calls its own inside an assertion, so unifying or renaming them would change an assertion line. The `## Fix run` section the run appended to .scratch/reviews/export-notes.md carries `- gate fixer: two attempts, still red`, a `- diff tests:` line reading green and a `- gate:` line reading green, and its last line reads `- not landed: duplication scan still dirty after the fixes, makeNotes; the branch export-notes and its worktree stay in place`, never a line naming the Gate or the Diff tests as red. No `landed at` line appears anywhere in the section, and the export-notes branch and its fix worktree are still in place."
---
A scan still dirty after both Gate fixer attempts, with the Diff tests and the Gate green, lands
nothing, and the landing line names the scan without calling the Gate red.
