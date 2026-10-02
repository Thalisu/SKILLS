---
type: llm
criteria: "The run wrote exactly three ticket files under the issues/ folder beside the Archive notes spec, one per ticket and no combined file, named 01-, 02- and 03- followed by a slug. The files numbered 01 and 02 are the archive ticket and the search ticket, in either order, each with no blocker. The file numbered 03 is the restore ticket, and its Blocked by names both of the others by number. No ticket is numbered before a ticket that blocks it. The spec and the journey were not edited and no git commit was made."
---
A ruling to publish writes one file per Ticket under the Spec's own folder, numbered in dependency order.
