---
type: llm
criteria: "The run's last message has a Run section with no Plan line: it names no Plan's location, no Planner and no Planner fallback (a checklist step reading that the Plan step was skipped because an impeccable Front-end ticket forks no Planner is fine, and so is a `Guard:` line). Its behaviours list is the Ticket's two acceptance criteria, 'The page shows one row per note with its title, newest first' and 'With no notes, the page says there are none yet', each quoted as the Ticket writes it with a commit hash beside it, for every criterion the fork closed. A run whose fork returned `stopped` or `fork` lists the criteria it did close the same way and says which one stopped it; it never lists behaviours of a Plan."
---
With no Planner there is no Plan line, and the Reply's behaviours list is the Ticket's acceptance criteria with a commit beside each.
