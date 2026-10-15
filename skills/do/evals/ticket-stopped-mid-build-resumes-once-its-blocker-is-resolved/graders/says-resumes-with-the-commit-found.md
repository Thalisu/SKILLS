---
type: llm
criteria: "The door did not refuse the Ticket, since Ticket 03, its only blocker, reads resolved. The run found Ticket 02 claimed and its do/mark-an-order-disputed-and-tell-the-customer worktree and resumed there: the transcript shows it entering that worktree and running `resume-state.sh`, whose output lists the one commit found on the branch with the behaviour it carries (a disputed Order reads the status disputed through lookup). The run removed the stale Plan beside the Ticket and forked the do-planner agent again. It did not start over, did not ask whether to resume, did not stop at the Plan on work for another repository, and did not look for or write a run-state file. Its final message is the five-part Reply and carries no `## Run` section."
---
A Ticket stopped mid-build is resumed in its worktree once its blocker is resolved, and
`resume-state.sh` lists the commit the stopped run left.
