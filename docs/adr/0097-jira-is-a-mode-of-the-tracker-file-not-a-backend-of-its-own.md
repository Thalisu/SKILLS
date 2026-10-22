# Jira is a mode of the tracker file, not a backend of its own

Jira is added as one more mode of `docs/agents/issue-tracker.md`, with one section per operation of
the chain (create the Spec, create a Ticket, link a blocker, claim, close, comment, publish a
Mirror) naming the concrete Jira call, and every skill keeps doing what the file says. A script
layer (`tracker.sh create|comment|transition|link`) was rejected: it would be an adapter with one
real backend, it would split GitHub and Jira into two paths a reader has to know, and the access
path chosen for Jira cannot be called from a script at all.
