# Jira is reached through the Atlassian MCP server alone

The tracker file's Jira mode names the Atlassian MCP server as its only access path, checked by the
setup through `getAccessibleAtlassianResources`, and a skill that finds it missing stops with one
line instead of trying another way. `acli` was rejected: no issue-link command could be confirmed
in its reference and it takes plain text or ADF where the Spec's headings are markdown, while its
one advantage, a stub on the PATH for bash tests, buys nothing once no script calls Jira. As a
consequence every script of the chain stays offline: the session reads a key from Jira and hands
it to the script.
