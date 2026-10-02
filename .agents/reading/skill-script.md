# Writing a script a skill ships

Each row is one section. Open it at its heading (`grep -n -Fx '<heading>' <file>`) and stop at the
next heading of the same or a higher level, unless Read says less.

| File | Section | Read |
|---|---|---|
| `.agents/skill-authoring/best-practices.md` | ### Set appropriate degrees of freedom | All: when a step is fragile enough to be an exact script |
| `.agents/skill-authoring/best-practices.md` | ### Solve, don't defer | All: the script handles its own errors, and every constant is justified |
| `.agents/skill-authoring/best-practices.md` | ### Provide utility scripts | All: why to ship one, and saying whether it is run or read |
| `.agents/skill-authoring/best-practices.md` | ### Create verifiable intermediate outputs | All: a plan file a script validates before anything runs |
| `.agents/skill-authoring/best-practices.md` | ### Avoid assuming tools are installed | All: name the install command |
| `.agents/skill-authoring/best-practices.md` | ### Code and scripts | All: the pre-ship checklist for scripts |
