---
type: llm
criteria: "The session dispatched no test author of its own: no Agent call of the session whose subagent_type is `unit-test-author`, `e2e-test-author`, `global-unit-test-author` or `global-e2e-test-author`, and no Skill call to `test-author`. The authors were dispatched inside the Builder's window instead: `[subagent]` Agent calls of the Agent call whose subagent_type is `do-builder`, each naming `global-unit-test-author` and carrying the dispatch input plus the line `Project map: <the map's path>` pointing at .scratch/archive-notes/issues/01-archive-a-note.project-map.md, so no dispatch derived the map again. The session read the map's location off `project-map.sh` and never the tests themselves."
---
The global unit author is dispatched by the Builder, with the Project map's path, and never by the session.
