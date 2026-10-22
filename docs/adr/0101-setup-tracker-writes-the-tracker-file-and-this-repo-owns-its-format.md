# setup-tracker writes the tracker file, and this repo owns its format

A user-invoked `setup-tracker` writes `docs/agents/issue-tracker.md` in every mode (local, GitHub,
Jira), and the file's format gets a page under `.agents/formats/`, replacing the dependence on the
upstream setup skill that wrote it until now. A Jira-only setup was rejected because the same file
would then have two authors with two formats for the chain to read. On Jira the setup reads the
project and proposes, never applies: it asks before writing any mapping, and what the project
lacks becomes a "Suggested changes" section for a Jira admin, since the MCP server cannot change
issue types, statuses or workflows.
