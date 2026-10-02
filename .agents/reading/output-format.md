# Controlling output format, tone or verbosity

For a prompt aimed at one model, add [target-model](target-model.md). On Claude Fable 5.1 the
last row wins over `### Control the format of responses`.

Each row is one section. Open it at its heading (`grep -n -Fx '<heading>' <file>`) and stop at the
next heading of the same or a higher level, unless Read says less.

| File | Section | Read |
|---|---|---|
| `.agents/prompting/prompting-best-practices.md` | ### Communication style and verbosity | All: the default terseness, and asking for a summary after tool use |
| `.agents/prompting/prompting-best-practices.md` | ### Control the format of responses | All: say what to do, and the prompt's own style leaks into the output |
| `.agents/skill-authoring/best-practices.md` | ### Template pattern | All: a strict template versus a flexible one |
| `.agents/skill-authoring/best-practices.md` | ### Examples pattern | All: input and output pairs carry a style better than a description |
| `.agents/prompting/fable-5-1.md` | ## Formatting in chat | All, for Claude Fable 5.1 only: drop anti-formatting rules and say when formatting fits |
