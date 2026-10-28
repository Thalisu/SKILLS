# Work for another repository

Read by two steps of the `ticket` Playbook of [ticket.md](ticket.md), only when a run meets work
for another repository: the Plan step, when the verified Plan's `## Behaviours` carry an
`Elsewhere:` item, and the build step, when the Builder's return carries a
`stopped: work for another repository:` line.

## At the Plan step

An `Elsewhere:` item, the shape [plan.md](plan.md) fixes, is a behaviour of the Ticket the Map
shows has no place in the repository this run builds in. The run reads the Plan's
`## Behaviours` for it where it already reads a Design fork item, once the `## Sources` check reads
`verdict=match`. One such item stops the run here, as blocked, whatever the other items of the list
are, before the claim, the worktree and the Spec branch: nothing is claimed, cut or committed, no
Builder is forked, no behaviour of the list is built, and the Ticket keeps the status the door
printed as `status=`. The Plan stays where it was written.

Before it writes anything, the run reads the item against the Ticket's criteria and the Digest:

- **A move**: the criterion or the story the item traces to still reads true as written once it is
  built in the repository the item names. The rest of this section is that finding.
- **A change of direction**: that criterion or story would have to be rewritten before anything
  could be built, there or anywhere, because what it asks for does not exist as it reads, or
  building it there would contradict another story, criterion or decision. Then
  `spec-finding.sh` is not run, nothing is written into the Spec and no `/tickets` command is
  handed over. The run stops as blocked the same way, under the `direction` Handover class, and
  its Reply ends on the `/discuss` command the change-of-direction stop of [forks.md](forks.md)
  fixes, naming the Ticket, the Spec and what the run found.

Before it stops on a move, the run writes the finding into the Spec, by script and never by hand,
once per `Elsewhere:` item, with the item's own values, `<n>` its number among the `Elsewhere:`
items, from 1:

```sh
bash <skill-dir>/scripts/spec-finding.sh <the Ticket's path> '<Belongs to>' '<the behaviour>' '<Location>' | tee <state>/finding.<n>
```

Each value goes in single quotes, a single quote inside one written as `'\''`, and never in double
quotes. The script refuses a value that carries a line break, a control character or a Unicode
line separator, a name that could not stand as one entry's name (empty, or carrying `: `, the Home
repository mark, the `Location not known` mark or a backtick), and a location that is not a bare
absolute path, each as `failed <reason>` with nothing written.

The script owns whether the Spec's `## Repositories` list already holds that repository; the
session never reads the Spec for it. It adds the entry when the list lacks it, creating the section
with the Home repository's own entry first on a Spec that has none, and appends the finding line to
the Spec's Implementation Decisions in the form
[spec-format.md](../../../.agents/formats/spec-format.md) fixes, marked with this Ticket. It prints
`spec=`, `repository=`, `listed=`, `list=`, `line=`, `home=`, `home_name=` and `here=`, saved in
`<state>` for the Reply. `line=present` is a finding an earlier run on this Ticket already wrote,
never written twice. No `choice-taker` is forked over a finding. An exit of 3 prints
`failed <reason>` and writes nothing, and the run stops on that reason in the finding's place.

The fourth argument is left out when the item's `Location:` reads `not known`, and never guessed
from a sibling folder's name or filled with a placeholder. For a repository the list already holds
the script prints `list=unchanged`. For one it does not hold, it prints `list=no-location`, writes
the finding line with the repository named and ` Location not known.` at its end, and adds no entry
to the list. The developer types the location with the `tickets` command the Reply ends on: the run
asks nobody for it, edits no file to hold it, and under `--auto` forks no `choice-taker` over it.

The stop is the `outward` Handover class, keyed on the `Elsewhere:` item and never on the session's
own reading of the tree. The Reply is the first line, then the lines this call printed, copied as
they stand, one finding file and its item's `Elsewhere:` behaviour per item, in the items' order:

```sh
bash <skill-dir>/scripts/reply-lines.sh elsewhere --door <state>/door <state>/finding.1 '<the behaviour>' [<state>/finding.2 '<the behaviour>' ...]
```

The message carries no `Plan:` line, no other part and no other command, neither `/do` nor
`/discuss` nor a shell line, and its last line is the `/tickets` line the script printed. On exit 3
the run copies nothing and stops as blocked on the `failed <reason>` line. The run asks nothing
before it: under `--auto` the stop is the same lines, with no `choice-taker` forked.

## At the build step

The Builder's `stopped:` line opens `work for another repository:` in the shape
[builder.md](builder.md) fixes. The Builder is not forked again and nobody builds around the
behaviour. The run takes the stop of `## At the Plan step` with these differences:

- The line's behaviour, repository and location stand where the item's `Elsewhere:`,
  `Belongs to:` and `Location:` stand.
- `spec-finding.sh` is run once with them and with `--step build` ahead of the Ticket's path, so
  the finding line names the build step it was met at.
- The Reply is the lines `reply-lines.sh elsewhere` prints with `--build <the run's worktree>` after
  `--door <state>/door`, the line's behaviour beside its finding file. Those lines stand as the
  blocker, the `Yours:` line and the Next step of a run stopped after work exists.
- The worktree, its branch and the commits already on it are kept, as any blocked build leaves
  them, for the next `/do` on the Ticket to resume from.

The move is told from a change of direction here too, on the line's behaviour, and a change of
direction ends on the same `/discuss` command, with the Ticket, worktree, branch and commits kept
and named.
