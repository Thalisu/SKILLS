---
type: llm
criteria: "The assistant resolved the bare slug by running .agents/scripts/resolve-feature-folder.sh, reached through the tickets skill's own folder, with the argument archive-notes, and took the spec from the spec= line it printed. It did not list .scratch/ and pick a folder by its own reading of the folder names. Reading the tracker file is expected, since it says whether a slug goes through the resolver at all; the run did not build the spec's path from the undated layout that file spells, .scratch/archive-notes/spec.md."
---
The slug goes through the resolver, never through a rule the run restates.
