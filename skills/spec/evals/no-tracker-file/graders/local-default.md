---
type: llm
criteria: "A spec file exists at .scratch/<slug>/spec.md even though docs/agents/issue-tracker.md does not exist. The assistant's closing summary says the tracker file was absent and that the local path was used. The assistant never told the user to run /setup-matt-pocock-skills or any other setup skill, and never asked where the spec should go. No docs/agents/ directory was created and no commit was made."
---
With no tracker file, the local default is taken and said, never demanded.
