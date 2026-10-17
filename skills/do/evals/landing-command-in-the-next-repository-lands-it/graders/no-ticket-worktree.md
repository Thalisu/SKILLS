---
type: tool_used
tool: Bash
input_match: 'worktree\s+add[^;&|]*(worktrees/do-|\sdo/)'
scope: all
min: 0
max: 0
---
The only tree a landing cuts is the Spec branch's own, `spec-hold-disputed-invoice`: no
`do/<slug>` branch and no `do-<slug>` worktree is made for a Ticket.
