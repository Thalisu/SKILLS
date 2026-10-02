---
type: llm
criteria: "The session showed the user the whole breakdown in its own message text, not only inside a tool call, a brief handed to an agent or a file it wrote: a numbered list of the tickets, each with its title, the path it realises, its estimate with the band, what blocks it or none, and what it delivers; then the splits, folds and placements taken or none; then what was left out, which names story 4 (archive several notes at once) and the deferred undo. A run that published tickets or handed the approval to an agent without that breakdown appearing in a message to the user fails."
---
Showing the breakdown is not a question, so `--auto` does not remove it: the flag replaces the answer, never the display.
