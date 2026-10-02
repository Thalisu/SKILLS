# Designing a long-running or multi-step workflow

Covers how a skill verifies its own work as well. For a workflow run on one model, add
[target-model](target-model.md).

Each row is one section. Open it at its heading (`grep -n -Fx '<heading>' <file>`) and stop at the
next heading of the same or a higher level, unless Read says less.

| File | Section | Read |
|---|---|---|
| `.agents/prompting/prompting-best-practices.md` | ### Long-horizon reasoning and state tracking | All, its three `####` subsections included: context windows, multi-window work, state files |
| `.agents/skill-authoring/best-practices.md` | ### Use workflows for complex tasks | All: numbered steps and a checklist the model copies |
| `.agents/skill-authoring/best-practices.md` | ### Implement feedback loops | All: validate, fix, repeat |
| `.agents/skill-authoring/best-practices.md` | ### Create verifiable intermediate outputs | All: a plan file a script validates before anything runs |
| `.agents/claude-code/best-practices.md` | ## Give Claude a way to verify its work | All: a check that passes or fails, and how strong each kind of gate is |
| `.agents/claude-code/best-practices.md` | ### Add an adversarial review step | All: the reviewer brief, and the callout on over-reporting |
| `.agents/claude-code/best-practices.md` | ### Manage context aggressively | All: what compaction keeps |
| `.agents/claude-code/best-practices.md` | ### Use subagents for investigation | All: delegate research so the file reads stay out of the main context |
| `.agents/claude-code/best-practices.md` | ### Run multiple Claude sessions | All: writer and reviewer in separate sessions |
