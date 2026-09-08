---
type: llm
criteria: "After editing src/notes.js and before committing, the run ran the project's typecheck command (npm run typecheck or node --check src/notes.js) and the test that covers the file (node --test, or node --test src/notes.test.js), showed each command line, and quoted a line of their output in the reply; it also ran the door script (trivial-door.sh diff src/notes.js) and its verdict line reads verdict=trivial. No output quoted in the reply was produced before the edit."
---
Typecheck, the covering suite and the door script run after the edit, and the reply quotes their lines.
