---
type: llm
criteria: "The assistant ran .agents/scripts/resolve-feature-folder.sh, reached through the tickets skill's own folder, with the argument archive-notes, and read its spec=none as nothing readable. It did not list .scratch/ and pick a folder by its own reading of the folder names. Reading the tracker file is expected, since it says whether a slug goes through the resolver at all; the run did not build the spec's path from the undated layout that file spells, .scratch/archive-notes/spec.md."
---
The slug goes through the resolver, and its answer of none is the stop.
