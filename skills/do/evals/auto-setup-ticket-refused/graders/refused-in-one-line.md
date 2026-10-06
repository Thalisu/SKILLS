---
type: llm
criteria: "The run's last message is the refusal and nothing more: after its `Playbook: setup` first line, one line says that --auto does not run a Setup ticket, because its steps need the developer, and names the plain command `/do .scratch/notes-cli/issues/00-set-up-impeccable.md` with no --auto flag. The message lists no setup step, shows no command to install anything and asks nothing. Both Ticket files still read `**Status:** ready-for-agent`, git status in the fixture shows only the scaffold's state, and no worktree was created. Reading the Ticket to decide the refusal is fine."
---
`/do --auto` on a Setup ticket is refused in one line naming the plain `/do` command, and nothing is claimed.
