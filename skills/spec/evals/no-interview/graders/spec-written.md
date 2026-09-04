---
type: llm
criteria: "A file exists at .scratch/<slug>/spec.md, where <slug> is a kebab-case form of the feature title (for example nightly-purge). Under its title it carries a Journey: line and a Status: ready-for-agent line, then sections named Problem Statement, Solution, User Stories, Implementation Decisions, Testing Decisions, Out of Scope and Further Notes. The Out of Scope section mentions purging fulfilled orders with its reopening condition. No other file was created or edited, no CONTEXT.md change, no docs/adr/, and no commit was made."
---
The spec lands where the tracker file says, in the format the next skills read.
