# The ticket run forks a planner, then a builder, and the session stops writing code

`do`'s ticket Playbook held the grounding, the behaviours list and the whole build loop in the
session's own window: `estimate-load.sh` reads 13.4k of ground on a fixed load of 91.5k, with 17k
to 18k more per criterion, so the part that grows with the Ticket is the part the session carried
itself. The run now forks a planner that grounds the Ticket and writes the Plan, then a builder
that runs the build loop in the worktree from that Plan and dispatches its own test authors. The
two are siblings one layer below the session, never a chain, so the test authors stay two layers
below and no step depends on a third. This supersedes, for the ticket Playbook, ADR 0009's rule
that the session writes the production code; the rest of that ADR stands, nesting depth included.

## Considered options

- A planner that forks the builder itself, as one reading of the idea had it: the test authors then
  sit three layers below the session, at the harness default's limit, where the Agent tool is
  withheld whatever the frontmatter says, so the tightest machine is the one that loses the
  delegation.
- A delegate per behaviour, which ADR 0009 weighed and rejected: one round trip per unit for a
  separation the policy loop already gives. The unit here is the Ticket, not the behaviour.
- Keeping the session as the writer and trimming what the loop reads into the window: it caps the
  per-criterion cost and leaves the ground and the reference chain where they are, so the session
  still grows with the Ticket.

## Consequences

The session reads the builder's diff and runs the Gate, the integration, the review and the close,
so nothing reaches the developer's branch that the session did not gate and the review did not
read. Total tokens rise by each fork's own baseline, about 32k, against a session window that no
longer grows with the criteria; ADR 0016 keeps the session's peak as the band a Ticket is sized by,
and the band is now read against the planner's window as well. With the Agent tool withheld, or
with neither agent listed, the session does that work itself, as it already does for the reader.

Amended: per ADR 0113, the reasons `plan.md` and `builder.md` gave beside their rules live here. The
Planner and the Builder are dispatched with their brief's keys and nothing else, since each opens
what it needs itself. `Criteria:`, `Rulings:` and `Built:` are quoted between tags that carry one
random id, since a Ticket or a Spec on a remote tracker holds whatever anyone who can comment on the
issue appended and `Built:` lines are read off commit bodies; the Builder's own `Bash` hook narrows
its shell for the same reason. The keys are written in `builder.md` and `plan.md` alone, since a
list copied into two files drifts and a key moved in one of them is a fork dispatched without it,
and the Builder's brief is the same on every re-fork but `Rulings:`, since a key that differed would
be a second record of the position beside the branch, and the two would drift. The Builder picks up
off the `Behaviour:` lines on the branch rather than off a run-state file somebody has to keep in
step with the commits. A returned `behaviour:` line carries the Plan's line verbatim, and a Plan's
item keeps the criterion's own words, since the session and `resume-tick.sh tick` match the two
texts exactly and a reworded item reads as unbuilt and is built and paid for twice. The fork report
carries both sides, the losing criterion and where the build stopped, since the session forks the
`choice-taker` against a Spec the Builder never read; neither that report nor a
work-for-another-repository line says whether the Spec lists a repository, since the fork opens no
Spec. The return carries no diff, test output, file contents, branch or worktree line, since the
session named both in the brief and nothing downstream would catch a Builder that pasted its build
back: the run still builds, gates and lands, and only the window the fork exists to keep empty is
lost. The Plan's `## Map` is never handed to the review, since each reviewer builds its own map
after the diff and a map of the tree as it was would read the work under review as code already
there (ADR 0025). The Plan's six headings are exact, since the session and the Builder find each
section by its heading, and the Sketch sits wholly inside its section, since the build is held to
that section alone. A behaviour is never read off the implementation, since the test written from it
stays green when the code is wrong, and an item that traces to no criterion and no quote is one the
fork invented. A Plan's name ends in `.plan.md`, since the Planner's own `PreToolUse` hook matches a
write against that suffix; a stale Plan is removed before the Planner is forked again, since that
hook refuses a write over a Plan already there; and a Plan is replaced whole and never edited, since
the fork that writes it holds one path and there is no second writer to merge with. The Plan's path
is the Home repository's, since a run inside a worktree has no scratch of its own
(`.agents/scratch.md`).

Amended: per ADR 0113, the reasons `ticket.md` and `stand-in.md` gave beside the Planner's and the
Builder's steps live here. The reading that grounds the Ticket happens in the Planner's window, per
guard-the-context-window, so the session opens no `CONTEXT.md`, ADR or source file of its own. The
Plan step comes before the claim and the worktree because it is the step that refuses. The Planner's
key is the main checkout, since the worktree the build runs in does not exist yet and the fork
grounds against HEAD, which is what step 2 cuts the worktree from. The Plan's path ends in
`.plan.md`, which is what the Planner's own hook lets its one write through on. The guard probe is
taken once, before the run's first fork of either agent, since a harness does not change within a
session and a resume is a new session that takes it again; it is never taken on a run that forks
neither agent, since no pattern guard can hold where no agent runs, and either verdict lets the run
go on, since the verdict only says which mechanism held. The brief's keys are read from `plan.md`
and never copied into `ticket.md`, since a copy drifts from the brief the fork is actually handed. A
held Ruling's `Now reads:` pair reaches the Planner through its `Rulings:` key, since the Digest
carries no Implementation Decisions section and the fork opens no Spec, and a Design fork is walked
by the session and never the fork, since the Ruling is written to the Spec and the fork holds no
tool that writes one. A defect whose cause is unknown is diagnosed by the session before the Planner
is forked, since the diagnosis needs a running program and the fork holds no tool that runs one, and
in step 2's worktree, since it instruments files to get its runtime evidence and the developer's
checkout is not the place for that. A session standing in for the Planner asks for neither the tool
nor the agent, since the developer cannot hand one over mid-run and the grounding is what the run
needs, not the window it was read in, and it forks no other agent in the Planner's place, since a
fork under any other name could still write where `do-planner`'s own definition binds it not to. A
return that names no Plan hands the session nothing to check, and a return naming a path other than
the destination is refused, since the run named that destination itself and every step below the
grounding opens it, so a Plan the fork wrote elsewhere is one the build never sees. The Map is never
handed to the review, since each reviewer builds its own map after the diff, and the context figure
is the session's to take, since no fork can read this session's figure from inside its own window.
The Builder's return is checked against the branch under the slug step 2 cut, since a probe that
refused to read the branch would drop every `built` return an issue-backed run ever made. On a run
whose Plan step recorded `Planner/Builder: none`, the session standing in for the Builder adds no
second line, since that one line already said the session did the Builder's work too.
