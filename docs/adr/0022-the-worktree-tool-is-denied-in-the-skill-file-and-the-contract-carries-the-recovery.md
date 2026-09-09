# The worktree tool is denied in the skill file, and the contract carries the recovery

A `do` run builds in a linked worktree and works in two trees, so a run that entered with the
harness's worktree tool is isolated and can neither run the door of `do-code-review`, which is
`bash <script>`, nor land, which is git against the main checkout. The prohibition in prose was
already written and already graded, and runs slipped past it anyway, so the tool is denied where
the flow lives: `skills/do/SKILL.md` drops it from the pool for the invoking turn with
`disallowed-tools` and registers a `PreToolUse` hook that refuses it for the rest of the session,
and [worktrees.md](../../.agents/worktrees.md) carries what a run does when it finds itself
isolated all the same.

## Considered options

Denying the tool in this repository's `.claude/settings.json` protects this repository and leaves
the failure in every other project that installs the chain. Writing the deny into the machine's
`~/.claude/settings.json` from a setup skill covers every project on that machine and was rejected
twice over: the skills are installed by whoever wants them, so a rule that lives on one machine is
not a rule the chain has, and a setup skill that edits the harness's own settings outlives the
skill's removal and is one step from writing `permissions.allow`. The skill file carries the block
instead. It ships with the skill, it is uninstalled with it, it only ever removes a capability, and
its scope is the sessions that invoked `do`.

## Consequences

The hook stays registered for the rest of the session, so a session that ran `do` cannot use the
harness's worktree tool again, for that run or for anything else, until a new session starts.
`once: true` does not fit: it clears the hook after its first successful run, which is the first
refusal, and the attempt after that would go through. The reason string is read by a shell before
the harness reads it, so it holds no apostrophe and no backtick: the apostrophe closes the quote
the reason sits in and leaves the caller reading an instruction with the commands missing, and the
backtick stays out so the rule survives a rewrite of that quoting; `contract.sh` runs the command
and reads the decision back to hold that. The field is Claude Code's, and a harness that does not
read it is left with the contract alone, which is why the recovery is written as a step a run takes
and not as a note a reader keeps.
