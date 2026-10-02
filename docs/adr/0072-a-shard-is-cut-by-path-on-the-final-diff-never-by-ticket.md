# A Shard is cut by path on the final diff, never by Ticket

A Spec branch is built Ticket by Ticket, so cutting its review along the Tickets looks like the
natural line. A **Shard** is cut instead by a script on the diff against the fixed point: whole
files, sized in tokens at four bytes each as ADR 0016 and ADR 0068 size everything else, packed up
to a budget with the files of one directory kept together, and a file over the budget a Shard of
its own. Every Shard is then code that lands, where a Ticket's range of commits is an intermediate
state: a later Ticket rewrites an earlier one's file, and the reviewer of the earlier range raises
Findings on lines the tip no longer has.

## Considered options

- One Shard per Ticket, a range of commits each: the intermediate state above, and a signal the
  branch does not carry, since its commits name a behaviour and no Ticket, which would have to
  thread through the Builder, the landing on the Spec branch and the rebase of the Final
  integration.
- Lines or files as the measure: the yardsticks ADR 0016 set aside for the window.
