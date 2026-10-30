# Each chain state maps to a named Jira status, and resolved is not Done

The tracker file maps `claimed` and `resolved` to a named status and transition of the project's
own workflow, which the setup proposes and the developer confirms, and `ready-for-agent` stays a
label. Using Jira's three status categories alone was rejected: `resolved` means landed on the Spec
branch (ADR 0060), and in a team where Done means in production the board would show as delivered a
Ticket no integration has reached. A Ticket a person moved past the mapped status, still in the
Done category, reads as resolved, so a team's extra step never blocks a blocker check.

Amended by ADR 0119: a Spec's own status walk maps to named statuses the same way.
