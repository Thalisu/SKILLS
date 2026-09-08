---
type: llm
criteria: "The fixture's project has no .gitignore. Before writing the spec into .scratch/, the assistant added a .scratch/ line to the project's .gitignore, and its closing summary says so in one line. It never wrote the path into .git/info/exclude instead, never asked whether to add it, and never told the user to commit .scratch/ or offered committing it as a way to keep the spec."
---
A project missing the ignore line gets it, in the project's own .gitignore, before the first write into the scratch.
