# Writing a skill's frontmatter and description

Read `.agents/invocation.md` whole and first: it is the rule here and it wins over the upstream
page wherever the two differ. Upstream asks for two frontmatter fields; the contract adds the
invocation choice, recorded in both harnesses.

Each row is one section. Open it at its heading (`grep -n -Fx '<heading>' <file>`) and stop at the
next heading of the same or a higher level, unless Read says less.

| File | Section | Read |
|---|---|---|
| `.agents/skill-authoring/best-practices.md` | ## Skill structure | The Note directly under the heading only: the hard limits on `name` and `description` |
| `.agents/skill-authoring/best-practices.md` | ### Naming conventions | All. Only the rules against vague, generic and reserved names bind here: bare verbs and nouns are fine |
| `.agents/skill-authoring/best-practices.md` | ### Writing effective descriptions | All, for a model-invoked skill only. A user-invoked description is a one-line summary for a person |
| `.agents/skill-authoring/best-practices.md` | ### Observe how Claude navigates Skills | All: four symptoms and the fix each implies. Its last paragraph, on the description as trigger, holds for model-invoked skills only |
| `.agents/prompting/prompting-best-practices.md` | ### Tool usage | The last paragraph only: dial back aggressive trigger wording, which overtriggers |
