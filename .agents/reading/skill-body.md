# Writing or tuning a SKILL.md body

Read the [prompt core](prompt-core.md) first, then these.

Each row is one section. Open it at its heading (`grep -n -Fx '<heading>' <file>`) and stop at the
next heading of the same or a higher level, unless Read says less.

| File | Section | Read |
|---|---|---|
| `.agents/skill-authoring/best-practices.md` | ### Concise is key | All: add only what the model lacks |
| `.agents/skill-authoring/best-practices.md` | ### Set appropriate degrees of freedom | All: prose, parameterised steps or an exact script, by how fragile the task is |
| `.agents/skill-authoring/best-practices.md` | ### Use workflows for complex tasks | All: numbered steps and a checklist the model copies |
| `.agents/skill-authoring/best-practices.md` | ### Implement feedback loops | All: validate, fix, repeat |
| `.agents/skill-authoring/best-practices.md` | ### Avoid time-sensitive information | All: no instruction that depends on a date |
| `.agents/skill-authoring/best-practices.md` | ### Use consistent terminology | All: one term per concept |
| `.agents/skill-authoring/best-practices.md` | ### Avoid offering too many options | All: one default and an escape hatch |
| `.agents/skill-authoring/best-practices.md` | ### Core quality | All: the pre-ship checklist. Its first two items hold for model-invoked skills only (`.agents/invocation.md`) |
| `.agents/prompting/prompting-best-practices.md` | ### Control the format of responses | All: say what to do, and the prompt's own style leaks into the output |
| `.agents/prompting/prompting-best-practices.md` | ### Tool usage | All: act versus suggest, and why shouted emphasis overtriggers |
| `.agents/prompting/prompting-best-practices.md` | ### Overeagerness | All: the block that keeps a change to what was asked |
| `.agents/claude-code/best-practices.md` | ## Provide specific context in your prompts | Up to the first `###`: scope, sources, existing patterns, what "fixed" looks like |
