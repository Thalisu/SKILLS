---
type: llm
criteria: "The session resolved the argument to the Archive notes spec, the spec.md of the archive-notes feature folder, and cut the breakdown from it: it ran the feature-folder resolver with the slug archive-notes alone, with no --auto token in the slug it passed, read that spec and its journey, and the tickets it drafted are the Archive notes paths' own. It never told the user that no spec was found, never asked for the spec or its path, and no ticket, estimate or line of the breakdown treats 'auto' as part of the feature or of its name."
---
The `--auto` token typed before the spec is dropped, and the rest resolves to the same Spec a run without the flag cuts.
