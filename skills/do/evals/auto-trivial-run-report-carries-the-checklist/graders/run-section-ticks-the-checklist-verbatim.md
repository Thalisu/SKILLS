---
type: llm
criteria: "Judge this on the Run report the run wrote under .scratch/do-reports/, the file the final message's `Report:` line names, as the tool call that wrote it or a read-back of it in the transcript shows. Its first section, under a `## Run` heading, carries the trivial Playbook's checklist with its seven steps in order and worded as the Playbook writes them (door, discover, edit, gate, door on the diff, commit, reply), none dropped, merged or reworded. Every step the run reached reads `done:` or `skip: <reason>`, the discover step reading `skip: no symbol created`, and a step the run never reached is left as it was copied. A Run report with no checklist, or with a step missing, fails."
---
Under --auto the Run report's Run section carries the matched Playbook's checklist verbatim, each step ticked or skipped visibly.
