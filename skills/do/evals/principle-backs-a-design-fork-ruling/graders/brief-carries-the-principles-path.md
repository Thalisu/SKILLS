---
type: llm
criteria: "The session forked the `choice-taker` (an Agent tool call with `subagent_type` `choice-taker`) with a brief holding a `Principles:` line whose value is an absolute path ending in `.agents/principles` (with or without a trailing slash), with no `~`, no `$(` and no `..` left in it, as the Agent tool call's input in the transcript shows."
---
The brief `do` sends hands the choice-taker the resolved path of the principles folder.
