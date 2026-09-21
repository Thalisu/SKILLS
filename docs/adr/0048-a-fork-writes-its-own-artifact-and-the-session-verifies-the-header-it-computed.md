# A fork writes its own artifact, and the session verifies the header it computed

ADR 0032 took the write tool from every fork that reads a stranger's text and had the session write
what the fork returned, which costs the session the whole artifact as output: the one thing a run
that delegates its grounding is trying to keep out of the window. A fork that owns an artifact now
holds `Write` and writes it at the path its brief and the naming convention fix. The session never
reads the text back. It checks, after the return, that the file is at the path it expected and that
the artifact's `## Sources` lines are the hashes the door computed before the fork, and it refuses
the artifact otherwise, the way the door already refuses a return missing a section. The guarantee
moves from the tool list to that check, and it is read in two lines rather than in the whole file.

## Considered options

- A capability allocated by the session before the fork, a one-shot token resolving to the
  destination, reached through an MCP tool the agent holds in place of `Write`. It is the only shape
  that survives the harness having no per-dispatch channel, and it costs a server process per
  machine and per harness in a repository whose install is a clone and one script. Deferred, with
  the condition that reopens it: a second fork of the chain needing to write, or a Plan past about
  8k.
- A script the fork calls with its destination: running a script takes `Bash`, and `Bash` writes
  anywhere, so the constraint would be weaker than the tool list it replaced.
- A `PreToolUse` hook in the agent's own frontmatter, the one mechanism that fires inside a fork. It
  validates a path pattern and refuses an overwrite, and it is kept as a best effort beside the
  check, never as the guarantee: it sees the call and never the brief, so it cannot tell this
  dispatch's Ticket from its sibling.

## Consequences

The public prior art settles the shape and not the guarantee: GSD gives its writing agents `Write`,
`Edit` and `Bash`, derives the destination from a naming convention, tells them in the agent file
that the orchestrator reads the artifact from disk and never from the return, and leaves
containment to a git worktree, with its guards' own headers calling them a defence against a
confused agent rather than against an evader. The header check is what this repository has that
convention alone does not, and it exists here only because the door computes the hashes before the
fork. Where no hook can run, Codex included, the pattern guard is absent and the check is the whole
mechanism; with no Agent tool the session writes the artifact itself, as it does today.
