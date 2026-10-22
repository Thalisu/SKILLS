# On Jira the tracker holds what the team reads, and the Feature folder keeps the rest

In Jira mode the Spec, its Tickets, their status, their Evidence and the Rulings live on Jira, and
everything a run works from stays in the local Feature folder, which records the Spec's issue key:
the Digest, the Plan, the Debt file, the Review, the claims and the Loss ledger. The Review and the
feature's Pending debt are published to Jira as a Mirror, which no skill reads back, so a
teammate's edit there never reaches a fork that holds a write tool (ADR 0032), and a claim stays a
`set -C` create instead of a network call that two runs can both win. Keeping the folder is what
lets a Jira Ticket keep its Spec branch, its Final integration and `/debt`, which a tracker Ticket
outside a feature folder loses today (`spec_branch=none`).
