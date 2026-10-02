# Writing an agent definition or a brief handed to a subagent

Read the [prompt core](prompt-core.md) first, then the rows for both, then the group that
matches: a definition is the standing file (`AGENT.md`, `.claude/agents/*.md`), a brief is the
prompt written at dispatch time. For a prompt aimed at one model, add
[target-model](target-model.md).

Each row is one section. Open it at its heading (`grep -n -Fx '<heading>' <file>`) and stop at the
next heading of the same or a higher level, unless Read says less.

Both:

| File | Section | Read |
|---|---|---|
| `.agents/prompting/prompting-best-practices.md` | ### Subagent orchestration | All: when a subagent is warranted |
| `.agents/prompting/prompting-best-practices.md` | ### Balancing autonomy and safety | All: the confirm-before-destructive block |
| `.agents/prompting/prompting-best-practices.md` | ### Overeagerness | All: the block that keeps a change to what was asked |
| `.agents/prompting/prompting-best-practices.md` | ### Minimizing hallucinations in agentic coding | All: read the file before claiming anything about it |
| `.agents/prompting/prompting-best-practices.md` | ### Reduce file creation in agentic coding | All: clean up temporary files |
| `.agents/claude-code/best-practices.md` | ## Provide specific context in your prompts | Up to the first `###`: scope, sources, existing patterns, what "fixed" looks like |

A definition only:

| File | Section | Read |
|---|---|---|
| `.agents/claude-code/best-practices.md` | ### Create custom subagents | All: the minimal agent file |
| `.agents/prompting/prompting-best-practices.md` | ### Give Claude a role | The first paragraph only: a one-sentence role. The rest is SDK samples |

A brief only:

| File | Section | Read |
|---|---|---|
| `.agents/prompting/prompting-best-practices.md` | ### Long context prompting | All: documents on top, the question last, quote before answering |
| `.agents/prompting/prompting-best-practices.md` | ### Research and information gathering | All: success criteria, competing hypotheses, a notes file |
| `.agents/claude-code/best-practices.md` | ### Use subagents for investigation | All: delegate research so the file reads stay out of the main context |

A reviewer agent, definition or brief:

| File | Section | Read |
|---|---|---|
| `.agents/claude-code/best-practices.md` | ### Add an adversarial review step | All: the reviewer brief, and the callout on over-reporting |
| `.agents/prompting/sonnet-5.md` | ## Code review harnesses | All: coverage first, and a concrete bar for what to report. Written for Claude Sonnet 5 |
