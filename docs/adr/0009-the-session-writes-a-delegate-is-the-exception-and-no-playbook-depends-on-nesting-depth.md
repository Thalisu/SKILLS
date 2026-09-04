# The session writes; a delegate is the exception, and no playbook depends on nesting depth

Inside every `do` playbook the session writes the production code and commits; the test authors
of the Testing Policy are the only agents dispatched per unit, and a code delegate is forked only
for bulk mechanical work with a closed scope (a script first, per `build-the-lever`) or for
exploration whose output would flood the thread, and never while a test author is running. In both
cases the session reads the delegate's diff and writes its own summary. poteto-mode mandates a
delegate per unit for review separation; here the policy loop already separates the test from the
code, so a delegate per behaviour would add one round trip per unit and no separation. Depth is not
something a playbook relies on: `do` runs inline, so a test author, a reviewer or a delegate sits
one layer below the session, and a delegate that runs the policy loop dispatches its own test
author two layers below, inside the harness default of three. When the Agent tool is withheld from
a delegate it writes nothing and says so, and the session runs the loop itself. A machine or a
project may raise `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`; no playbook in this repo assumes it,
because the Agent tool is withheld at the limit whatever the agent's frontmatter says, the default
changed between Claude Code versions, and Codex has no confirmed equivalent.

## Considered options

- A delegate per unit, as poteto-mode prescribes: one round trip per behaviour and the session
  reviewing a summary of a summary, for a separation the policy loop already gives.
- Raising the depth limit repo-wide so playbooks may nest freely: a harness setting leaking into a
  contract every teammate and harness must honour, and one that changed between Claude Code
  versions.
