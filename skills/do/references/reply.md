# The reply

Every Playbook reads this file last and writes its reply by it: five parts, and every other line a
step names goes to the Run report, written under `--auto` alone.

Every line a step names is recorded for the Reply or the Run report. A status note in passing
replaces neither.

## The message

One short message, in the language the session opened in, read by a developer who wants to know
what was done for whom, what is left and what to type next, and nothing more. It is built from
these parts, in this order:

1. **Plan.** `Playbook: <name>` as plain text on the first line, with no code formatting around
   it, then a `Plan:` line on the next line naming the plan the run built from: in `ticket` the
   Plan's file name, or `Plan: none, <reason>` when the run opened no Plan (a resume whose only
   work left was the landing); in every other Playbook the request read back in a few words. Under
   `--auto` a `Report:` line follows, naming the Run report's absolute location.
2. **For whom.** The [For whom](#sections) section, under a `## For whom` heading.
3. **Pending debt.** The [Pending debt](#sections) section, under a `## Pending debt` heading.
4. **Yours.** The `Yours: <class>: <the choice>` line, only when the run hands the developer
   something, with the blocker it stopped on and its reason on the lines right above it. A run that
   hands over nothing writes no such line and no heading for it.
   Read [blocked-reply.md](blocked-reply.md) when the run ends blocked or refused.
5. **Next step.** The [Next step](#sections) section, under a `## Next step` heading, last: the
   stdout of `next-step.sh`, copied whole. Piped `yours=yes` when a `Yours:` line stands, it opens
   on one line saying to do what that line names first, and the command comes after it.

Three rules hold across all of it:

- **`none`.** For whom and Pending debt with nothing to say read `none` on one line.
- **Quotes.** Everything quoted was produced in this run, after the last edit. Nothing is a link, a
  sha or a transcript reference the run did not see.
- **Nothing added.** The five parts are the whole message: no `## Summary` and no `## Test plan`
  joins them, and nothing comes after the Next step, neither a recap nor an offer to carry on.

Every other line the run's steps name makes up the Run report, which is never part of the message
and is written to a file under `--auto` alone. Read [run-report.md](run-report.md) when the run is
under `--auto`, before it writes the Run report.

Every run on a Ticket, with or without `--auto`, writes the Reply's Pending debt part, and nothing
else of the Reply, to the Debt file beside the Ticket: the Ticket's file name with `.debt` before
the extension (`<ticket stem>.debt.md`), in the Home repository's main checkout, in the shape of
[debt-format.md](../../../.agents/formats/debt-format.md). For a tracker Ticket it sits beside the
Plan, with `.debt.md` in place of `.plan.md`, the way the Run report sits beside it. Each run adds
one section to that file, headed by the run's date and time as one `## <date and time>` heading.
Under it goes the Pending debt part's text verbatim, one `- ` bullet per Pending debt line, and no
`## Pending debt` heading of its own. A run that owes nothing still writes its section, which reads
plain `none` and not a `- none` bullet. A later run on the same Ticket appends its section below
the earlier ones, and never replaces or edits one, be it a resume after a stop or a run again. The
Reply itself carries no line naming the Debt file: no `Debt:` line beside the `Report:` line in
the Plan block, and the Next step says nothing about it.

A run that ends early writes a shorter message.
Read [blocked-reply.md](blocked-reply.md) when the run ends blocked or refused.
[Whole replies](#whole-replies) shows the shape of a run that landed.

## Voice

The Reply reports and never narrates: each line states a fact a step recorded, for a reader who
was not there.

- Short declarative sentences. Where a long dash or a connecting colon would join two of them, end
  the first with a period. The Reply carries no long dash anywhere, the checklist's done lines
  included, and no colon as a mid-sentence connector.
- A colon stays where it is a line's own label: `Playbook:`, `Loop:`, `Yours:`, and a tick, which
  reads `done:` after the step.
- Call the Skill tool with `unslop` on the drafted reply when the session lists it; write it by
  this file alone otherwise.

## Sections

Three sections, in this order, each a part of the message.

1. **For whom.** Who the work is for and what changes for them: the end user, the colleague who
   imports the module, the reader of the doc. A `pr` run that pushed a round carries its round
   lines here, listed per round, each round under its own number (`round <r>:`), then one line per
   red check naming the check, its fixer (`do-pr-fixer` and its branch), the commit pushed for it
   or what its fixer returned, then the verdict the watch read after the push.
2. **Pending debt.** Waivers, consumer coverage not run, an equivalence gap, a second thing found
   on the way and not done. It lists every `Risk:` line of the review's return, on every run, with
   or without `--auto`. It lists every
   `Axis not run:` line of the review's return too, with its reason, with or without `--auto`. It lists
   every `drop` of an integration that ran after the review, each marked as coming after the review,
   with or without `--auto`. The Run report
   still carries all three under `--auto`, and the message stays five parts. A `bug-fix` or
   `refactoring` Design fork's Ruling is listed here on every run, in the line its Forks section
   fixes. A held Ruling the close did not post, with its
   whole Spec line and its `Criterion:` and `Now reads:` lines. When
   `guard-reply.sh` exits 1, on a `guard=header-only` probe or one that failed and printed no
   verdict, its `Guard:` line is listed here too, as printed, with the `disabled_by=` file when the
   probe named one, in the message, with or without `--auto`. On exit 0, a `pattern-and-header`
   verdict, nothing is added here. The line for
   consumer flows not run opens `consumer flows not run:` and names the Ticket that carries them,
   off the Completion check's `consumer=` lines: each `consumer=<NN> <name>` line is a Ticket of
   another repository blocked by the one this run built, the one whose criteria cross the two
   services, and is named as `Ticket <NN> (built in <name>)`, as
   `consumer flows not run: the hold on the Order's page, carried by Ticket 04 (built in orders-service)`.
   The number is copied from those lines and never read off a Ticket or the Spec. With
   `consumer=none`, or on a run whose close ran no check, the line names the consumers alone.
3. **Next step.** One line, the Reply's last, or the lines `next-step.sh` prints in its place.
    Pipe `outcome=` with the route below, `yours=yes` when the Reply carries a `Yours:` line or
    `yours=no` otherwise, and what the row names into `bash <skill-dir>/scripts/next-step.sh`, then
    copy its stdout whole under `## Next step`. Never compose the line yourself. Pipe a script's
    output whole: keys no route reads are ignored. On exit 2 nothing is printed and stderr names the
    key the route lacks: add it and pipe again.

    | The run | `outcome=` | Piped with it |
    |---|---|---|
    | landed on the developer's branch: `trivial`, `bug-fix`, `refactoring` | `landed` | `branch=<the developer's branch>` |
    | a `ticket` run that landed on its Spec branch | `spec-landed` | `completion-check.sh`'s output |
    | a `setup` run that resolved its Ticket | `setup-resolved` | `completion-check.sh`'s output |
    | a Final integration that landed, or a resume of one that finished | `final-landed` | `branch=<the developer's branch>`, and on a feature of more than one repository `landing-order.sh`'s output, read after the release |
    | a landing record that read `verdict=wait` | `landing-wait` | `branch=<the developer's branch>` and `landing-order.sh`'s output |
    | a Final integration claim that read `taken`, on a run that is not a resume | `claim-taken` | `final-claim.sh`'s output |
    | a Final integration that stopped, a resume that stopped again, or a resume on a claim nobody yielded | `final-stopped` | `ticket=<the /do argument the run was started with, as typed>` |
    | a `pr` run whose watch read green | `pr-green` | `pr=<n>`, `pushed=yes\|no`, and `head=<head>` when it pushed |
    | a `pr` run whose watch read `awaiting-approval` | `pr-awaiting-approval` | `pr=<n>`, `pushed=yes\|no`, and `head=<head>` when it pushed |
    | an `integrate` run that finished its operation | `integrated` | `op=rebase\|merge`, `upstream=yes\|no` |
    | an `integrate` run blocked mid-operation | `integrate-blocked` | `integrate-door.sh`'s output |
    | a run that landed nothing, the review not callable or not landing | `unlanded` | `worktree=<the run's worktree>`, `run_branch=<its branch>` |

    A refused or blocked run takes its route from the stop it made, and a run stopped on an
    Extreme fork from its Playbook's Extreme stop.
    Read [blocked-reply.md](blocked-reply.md) when the run ends blocked or refused, for the `outcome=` each stop names.

    A stopped Final integration says on its `Yours: direction:` line that a `do` on any Ticket of
    the Spec resumes it too, and what to fix first there or above it, never after the command. A
    landed run whose close finished is not a stop: the push stays on this line, the run
    never pushes, and its Reply carries no `Yours:` line. A landed run that then stopped at the
    close's `destroy` stop carries exactly one `Yours: destroy:` line; the push still stays on
    this Next step line and is never named under `outward`.
    Read [blocked-reply.md](blocked-reply.md) when the close stops at its `destroy` stop. A `pr` run whose
    watch read green, every check passed and the pull request mergeable, ends its line with
    `gh pr merge <n>`, its pull request's number, under that same rule as a landed run's push: the
    run never runs it, its Reply carries no `Yours:` line, and the merge is never named under
    `outward`. A `pr` run whose watch read `awaiting-approval` follows the same rule. A `pr` run
    that pushed a round reports its push on For whom's round lines, never an `outward`
    hand-over.

## Final integration lines

The lines `bash <skill-dir>/scripts/reply-lines.sh final` and
`bash <skill-dir>/scripts/reply-lines.sh repositories` printed, on a run that ran the Final
integration or entered on the door's `verdict=resume-final`, are copied as they stand. The session
composes none of them.

- A `Final integration: stopped`, `stopped again` or `not resumed` line is the blocker above the
  `Yours:` line. The `Yours:` line names the Spec branch and its worktree, both left in place, and
  that the claim stays beside the Spec, yielded for the `do` that resumes it. On `not resumed` it
  quotes the claim's `yield_command=` line whole.
- The `Push:` line and the lines `repositories` printed stand under `## Next step`, before its last
  line.
- A run that built no Ticket and took no claim writes a message of the first line, the lines
  `final` printed, then the lines `repositories` printed, and no other part. That message carries
  no `Yours:` line and no shell line. Under `--auto` it is the same lines, with no `choice-taker`
  forked.
- On exit 3 the session copies nothing and reports the `failed <reason>` line as it reports any
  script that failed.

## Whole replies

<example>

```md
Playbook: trivial
Plan: fix the typo "recieve" in the comment above exportNote

## For whom

The colleague who reads export.ts. The comment above exportNote now spells "receive" correctly.

## Pending debt

none

## Next step

git push origin notes-export
```

</example>
