# A Spec is one level above its Tickets, and a Ticket is never a Subtask

On Jira a Spec is an Epic-level issue and its Tickets are standard-level issues under it, linked by
`parent`, with `Blocked by` as the native "Blocks" link and the Pending debt card as one more child.
Where the project already uses Epics for initiatives, the Spec is a Story under that Epic and the
Spec-to-Ticket relation is a link type the tracker file names. Subtasks were rejected, although the
first plan proposed them: a Subtask shares its parent's sprint, cannot have children and hardly
shows on a board, so a feature whose Tickets land on different days would read as one item.
