---
type: llm
criteria: "The proposed breakdown has more than one ticket for the single path 'Import a file of notes', each one a demoable piece of the path's steps (for example preview and mapping, duplicates and tags, the background import with progress, the report and undo), each naming the path, each stating an estimate in tokens with its band and what drives the number, and none in the large band. Every later piece is blocked by an earlier one, and its Blocked by line says what it reads (the preview, the mapping, the imported notes with their import id) and which ticket writes it. Under the splits taken, the assistant names the rule: a large path is split along its steps. The run ended at the approval message, whose only question was whether the breakdown goes out. No file was created under .scratch/import-notes/issues/ and no git commit was made."
---
A large path is split along its steps into demoable pieces, and the split is stated, never asked.
