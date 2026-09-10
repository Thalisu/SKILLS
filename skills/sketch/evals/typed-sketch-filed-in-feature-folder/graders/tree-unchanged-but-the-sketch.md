---
type: llm
criteria: "The fixture changes list exactly one file created and nothing else: .scratch/20260101-export-notes/sketch.md. .gitignore, src/notes.ts and .scratch/20260101-export-notes/spec.md are unchanged, no other file was created, changed or deleted anywhere in the fixture, and the run made no commit. Since the Sketch sits under the ignored .scratch/, `git status --porcelain` in the fixture prints nothing: no tracked file modified and no untracked file created. Reading files and running the resolver, readlink, git check-ignore or git status is fine."
---
Nothing but the Sketch changes in the tree: no tracked file touched, no file created outside the Feature folder, `.gitignore` untouched.
