---
type: llm
criteria: "A file exists at .scratch/<YYYYMMDD>-<slug>/spec.md, whose folder is an eight-digit date, a dash, and a kebab-case form of the feature title (for example 20260115-nightly-purge). The folder is dated even though the fixture's tracker file spells the local layout without a date, since the tracker file names the home and the date is the skill's. Under its title it carries a Journey: line and a Status: ready-for-agent line, then sections named Problem Statement, Solution, User Stories, Implementation Decisions, Testing Decisions, Out of Scope and Further Notes. The Out of Scope section mentions purging fulfilled orders with its reopening condition. No other file was created or edited, no CONTEXT.md change, no docs/adr/, and no commit was made."
---
The spec lands where the tracker file says, in the format the next skills read.
