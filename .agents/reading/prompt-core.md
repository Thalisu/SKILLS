# Prompt core

The four sections every prompt leans on, whatever it is for: a `SKILL.md` body, an agent
definition, a brief, a prompt inside a script, a grader prompt. The cases that write a prompt link
here instead of repeating these rows.

Each row is one section. Open it at its heading (`grep -n -Fx '<heading>' <file>`) and stop at the
next heading of the same or a higher level, unless Read says less.

| File | Section | Read |
|---|---|---|
| `.agents/prompting/prompting-best-practices.md` | ### Be clear and direct | All: be explicit, the colleague test, numbered steps when the order matters |
| `.agents/prompting/prompting-best-practices.md` | ### Add context to improve performance | All: state the reason behind a rule so the model generalizes from it |
| `.agents/prompting/prompting-best-practices.md` | ### Use examples effectively | All: three to five relevant, varied examples, wrapped in tags |
| `.agents/prompting/prompting-best-practices.md` | ### Structure prompts with XML tags | All: consistent tags that keep instructions, context and inputs apart |
