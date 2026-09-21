# The conflict loop

What a run does at every stop of a replay: the class read from a script before anything is
resolved, the mechanical hunks resolved by the union rule, the contested hunks resolved to the
**Target** side with their **Incoming** side written to the **Loss ledger**, that ledger judged and
its reapplies brought back, and the states git refuses. It is read by the step that reaches a stop
and by no other: the integration step of [mechanics.md](mechanics.md), which the worktree Playbooks
run, and step 4 of [integrate.md](integrate.md), which builds in no worktree and substitutes its
own continue, abort and ledger path for this file's.

One reader reaches no stop at all and still reads one state of this file: the no-op state of that
same integration step, **A rebase that replays no commit.** of [mechanics.md](mechanics.md), where
the ancestor check excused the rebase and the ledger still carries an entry judged `reapply` with
no applied line. It reads **The reapplies brought back** below and nothing else here, since the
hunks that entry came from were classed, resolved and judged at a stop of the run that wrote the
ledger. It brings the entry back the way that state does, through `check-reapply.sh` and never
around it: the block it applies is a judge's reading of a stranger's diff text like every other
here, so the same check binds that block's `file`, its `blob` and its `with` back to the entry
before the session writes anything.

## The conflict loop

**A rebase that stopped.** At every stop of the rebase, before anything else, the run classes the
conflicted hunks: `bash <skill-dir>/scripts/conflict-class.sh`, whose verdict is the class, never
the session's own reading of the markers, per
[ADR 0028](../../../docs/adr/0028-the-conflict-class-is-a-scripts-verdict-never-the-sessions-reading.md).
The script runs before the run resolves, stages or writes anything at that stop. Its lines, one per
conflicted hunk, are quoted in the Reply's Evidence, and the counts, how many hunks were resolved
mechanically and how many took the **Target** side, go on the integration line of the Run section.

A stop the script answers with `no conflicted state, nothing classed` is never continued unasked:
the rebase stopped with nothing unmerged, so whatever is staged for that commit carries nobody's
recorded answer. A run that opened the rebase itself meets that stop when git refuses a step no hunk
carries, an untracked file the replay would overwrite for one, and a continue there meets the same
refusal. The run stops as blocked with git's own message quoted as it printed it, the
rebase left open at that commit, and `git rebase --abort` named as the command that undoes it. The
worktree and its branch stay in place and are named, the Ticket stays `claimed`, nothing lands
and nothing is pushed. A resumed run meets the same stop only after the Resume of
[ticket.md](ticket.md) continued on `resume-state.sh`'s `stop=resolved` or `stop=moved` line: on
the answer to its question that says so, or on `moved=continue`, which puts no question.

Where every hunk of the stop is `mechanical`, the run resolves them itself and nothing is asked of
the developer. The conflicted files are the list git left, read NUL-delimited so that a path
carrying a space or a newline comes back as one entry and needs no unescaping:
`git diff --name-only --diff-filter=U -z`. A path is a name either side of the rebase chose, so it
never enters a command line as text: pasted in, a single quote in it closes whatever quotes it sits
in, and the `$(...)`, backtick, `;` or `|` after it runs as the run's own command. The two blocks
below run as they stand, with nothing pasted into them, and each path reaches git through a shell
variable, whose value is never evaluated again, or through `xargs -0`, which starts no shell. The
first stages every file the script printed `trusted`, one the developer resolved by hand and never
staged, from the script's own read-only list of them, so git no longer lists it unmerged and nothing
below rewrites it; then it takes the three stages of every file still conflicted out of the index
and writes their union:

```
bash <skill-dir>/scripts/conflict-class.sh --trusted -z | GIT_LITERAL_PATHSPECS=1 xargs -0 -r git add --
stages="$(mktemp -d)"
git diff --name-only --diff-filter=U -z | while IFS= read -r -d '' file; do
  git show ":1:$file" > "$stages/base" && git show ":2:$file" > "$stages/target" &&
    git show ":3:$file" > "$stages/incoming" &&
    git merge-file --union --diff3 -p "$stages/target" "$stages/base" "$stages/incoming" > "$file"
done
rm -rf "$stages"
```

Stage 2 is the developer's branch and stage 3 the commit being replayed, so the union in that order
keeps both sides with the developer's branch above the replayed commit's, which is the base order
this step owes. The `--diff3` stays: without it git trims the lines both sides' additions share, so
two functions appended at the same place keep one closing brace between them and the file no
longer parses. Git writes the result and the session never edits a marker. The second block reads
every union back, as the next state says, and marks the files resolved once the read-back returned:

```
git diff --name-only --diff-filter=U -z | bash <skill-dir>/scripts/last-wins.sh "<the ledger>" &&
  git diff --name-only --diff-filter=U -z | GIT_LITERAL_PATHSPECS=1 xargs -0 git add --
```

Then the continue block below, the one every stop of this step ends in, carries the rebase to the
next commit, and every further stop is classed and resolved the same way. The reply names every
hunk it resolved with its file and location, and every `trusted` file as taken on trust, kept as the
developer wrote it and out of the ledger. The first block stages it before the second one runs, so
git no longer lists it unmerged and it is never among the paths the read-back is handed: a key the
developer's own resolution defines twice is theirs, and nothing of this step rewrites it.

**A union that defines the same key twice.** A hunk classed `mechanical` says the two sides only
added lines, never that the two additions mean the same thing. Where both sides added a definition
of one key at the same anchor of a file whose reader takes the last definition it meets (JSON, YAML,
TOML, an INI or a `.env` file), the union keeps both lines and the reader keeps one value: a `deny`
list the developer's branch just added and an empty one from the replayed commit both land, and
whatever reads the landed commit gets the empty one, a control of theirs undone with nothing asked.
So the second block above reads every union back before it marks a file resolved, and the read-back
is `last-wins.sh`'s and never the session's, for the reason the class itself is a script's, per
[ADR 0028](../../../docs/adr/0028-the-conflict-class-is-a-scripts-verdict-never-the-sessions-reading.md).
A key defined twice in one scope of one of those files keeps the **Target**'s definition, the
**Incoming**'s is dropped from the file, and it goes to the **Loss ledger** as an entry of its own,
shaped `last-wins-duplicate` and keyed by the file and the key path, so a rerun at the same stop
rewrites it where it stands. Two definitions written byte for byte alike come out as one with no
entry, since the reader loses nothing, and a key the base itself already defined twice is older than
the union and is left as it stands. Nobody is asked anything, and the step of a file whose format
the script does not know is to leave it untouched.

The script prints `kept <file> <key path>` and `deduped <file> <key path>`, then
`read-back files=<n> kept=<n> deduped=<n>`, and those lines are quoted in the Reply's Evidence
beside the hunks the union resolved. A read-back that exits non-zero, a refused ledger or a file it
could not rewrite, leaves the staging beside it unrun, since the block runs that only on the
read-back's success, and the continue then meets a stop git refuses, which the state below fixes.

**A stop carrying a contested hunk.** A hunk classed `contested` is resolved by a script to the
**Target** side, and nobody is asked anything, per
[ADR 0034](../../../docs/adr/0034-a-contested-hunk-takes-the-target-side-and-what-it-sets-aside-is-reapplied-after-the-integration.md):
neither the developer nor the session writes a hunk of their own, and a headless run resolves the
stop the same way. The two blocks above are the all-mechanical stop's alone, since the union above
takes every conflicted file, contested ones included. Here one call resolves the whole stop:

```
bash <skill-dir>/scripts/contested.sh "<the ledger>"
```

The script takes the order, the class and the locations from `conflict-class.sh` and the sides from
the index stages, so the session reads no marker here either. It writes every file whose hunks are
all `mechanical` by the union rule, and every file carrying a `contested` hunk once from its three
stages, its `mechanical` hunks by the same rule and its `contested` hunks from the **Target** stage.
A file the script cannot splice is taken whole from the **Target** stage, or removed where the
**Target** deleted it: a delete against an edit, a rename against an edit, a binary file, a file too
large to merge, and a file git's merge cannot line up with the index. Each file is staged and named
on a `wrote` or `removed` line, and each file the conflict class printed `trusted` is staged as it
stands and named on a `trusted` line. The last line is `resolved mechanical=<n> contested=<n>`.

The **Incoming** side of every `contested` hunk goes to the run's **Loss ledger**, whose shape
[loss-ledger-format.md](../../../.agents/formats/loss-ledger-format.md) fixes, one entry per hunk
keyed by its hunk id, written before any file of the stop: the file, the location, the shape, the
replayed commit, the commit the branch was on before the rebase, the **Target** side quoted and
the **Incoming** side whole. A file taken whole leaves one entry holding both sides whole, and a
binary or too-large side is named by its size, its blob and the commit recorded before the rebase,
from which the blob stays reachable. A rerun at the same stop rewrites each entry where it stands,
so the ledger never holds a hunk twice.

The ledger is one file per run, in the main checkout, and its path is fixed before the rebase
starts, since the branch the rebase replays is only on record while it runs:

- in `ticket`, beside the Ticket, the Ticket's path in the main checkout with `.ledger` before the
  extension, `01-x.ledger.md` beside `01-x.md`; for a Ticket that is not a local file, the issue's
  reference under `.scratch/ledgers/` there, with `.md` after it;
- in `bug-fix` and `refactoring`, `.scratch/ledgers/<branch>.md` in the main checkout, with every
  `/` of the run's branch written as `-`, the key the Review beside the branch already uses.

The worktree reaches the ledger by that absolute path and never copies it, and every stop of the
same rebase passes the same path. The script refuses a path that does not resolve under the main
checkout's `.scratch/`, with nothing written.

What it prints and the code it exits with say what the run does next.

- `resolved` (exit 0): the stop is resolved and staged, each file the script wrote by the union rule
  already read back for a key defined twice on its way through, as the state above says. The run
  ends the stop in the continue block below, and the next stop is classed like any other.
- Exit 2: a usage fault, no stopped rebase, no contested hunk at that stop, or the ledger refused,
  with nothing written. The run stops as blocked with the script's reason quoted, the rebase left
  open at that commit, the conflicting files named, the command that undoes it,
  `git rebase --abort`, the worktree and its branch left in place and named, the Ticket left
  `claimed`, nothing landed and nothing pushed.
- Exit 3: git refused to write the index for a file, named on the script's `git refused to stage
  <file>` line, with no `wrote`, `removed`, `trusted` or `resolved` line for it and every other file
  of the stop left as it stood. The run stops as blocked the same way as exit 2, the script's reason
  quoted, the rebase left open at that commit, the conflicting files named, `git rebase --abort` as
  the undo, the worktree and its branch left in place and named, the Ticket left `claimed`, nothing
  landed and nothing pushed.
- Exit 4: the read-back refused a file the union rule wrote, on its own reason line (`blocked
  <file>` when the file defines its duplicated keys more times than the read-back's cap,
  `could not rewrite <file>`, or the ledger refused) followed by `read-back refused <file>`, with no
  `wrote` or `resolved` line for it. The run stops as blocked the same way as exit 3, both lines
  quoted, and never reads the stop as git's refusal.

Once the rebase finishes, the step is ticked with the totals across every stop, the mechanical and
the contested hunks counted from each verdict line, and the ledger's location.

**The Loss ledger judged.** Every entry the rebase left is judged before the gate runs again, so
that what a contested hunk set aside is on record as kept or as let go, and never merely set aside.
Which entries are still waiting is the script's answer and never the session's own reading of the
file, per
[ADR 0028](../../../docs/adr/0028-the-conflict-class-is-a-scripts-verdict-never-the-sessions-reading.md):
`bash <skill-dir>/scripts/ledger.sh pending "<the ledger>"` prints the id of each entry carrying no
verdict, in file order, reading a heading outside a fence only, so a `## <id>` line one of the sides
quotes is that side's own text and never an entry of its own. No id at all is an empty ledger, a
rebase that set nothing aside, or one whose entries an earlier run already judged: nothing is
forked, no verdict is written, the step goes straight on, and a rebase with no `contested` hunk
costs what it costs today.

With at least one id, the run calls the Agent tool with `subagent_type: ledger-judge`, the agent
`do` ships in [ledger-judge.md](../agents/ledger-judge.md), once per integration and never once per
entry: one fork reads the whole ledger and the tree around it, where a fork per entry would pay for
that reading again for every hunk, per
[guard-the-context-window](../../../.agents/principles/guard-the-context-window.md). The brief
carries the ledger's location, the worktree root, the ids `pending` named, and the run's intent,
which is the Digest's location in a `ticket` run and the request's line in `bug-fix` and
`refactoring`. The fork holds reading and search alone, per
[ADR 0032](../../../docs/adr/0032-a-fork-that-reads-a-strangers-text-holds-no-write-tool.md), since
a ledger entry is a side of a diff a stranger's commit may have written, and the session writes what
it returns.

It returns one block per entry: the id, `reapply` or `drop`, a one-line reason, and, on a
`reapply`, the edit against the tree as it now stands, which the state below brings back. The
session writes each reading where the ledger keeps it: the id, the verdict word and the reason go
into a fresh directory's `id`, `verdict` and `reason` files, one line each, and the run calls
`bash <skill-dir>/scripts/ledger.sh verdict "<the ledger>" "<the entry dir>"`, one call per block,
the same shape `put` already takes, an entry directory rather than loose arguments, so the judge's
free-text reason never becomes a shell word a command could hide inside. `contested.sh` writes
entries and this verb writes verdicts, so neither
overwrites the other and a rerun at the same stop carries a verdict over. A resumed run judges only
what `pending` named, so running twice leaves the same ledger. An id the judge names that `pending`
did not, and an id that already carries a verdict, are both refused by the script with nothing
written, and the run records the refusal rather than retrying it: a reading of an entry nobody set
aside is not one the run asked for, and a second reading never writes over the first.

No judge can be forked on two branches: the Agent tool is withheld from the session, or the Agent
tool lists no `ledger-judge`, as it does on a machine that never linked the agent `do` ships. On
either branch the session judges the pending entries itself, reading each entry and the file it
names, and writes the same verdicts through the same verb. It says in one line which branch holds,
the Agent tool withheld, or `ledger-judge` not listed, the agent this machine has not linked, which
one run of the skills repository's `scripts/link-skills.sh` links before the next `/do`. The run
neither stops nor asks for the agent, since the developer cannot hand one over mid-run and the
ledger is what the run needs judged, not the window it was judged in. It never forks another agent
in its place: a fork under any other name could still hold the write tools `ledger-judge`'s own
definition denies it.

**The reapplies brought back.** Every entry judged `reapply` comes back as one commit per `reapply`
on top of the finished integration, in the order `pending` printed them, so each piece of work a
contested hunk set aside is a diff the developer reads and reverts alone. The block the judge
returned is a reading of a stranger's diff text, per ADR 0032, so before the session writes
anything from it, it writes the block's `id`, `file` and the entry's `reason`, and, only on a block
carrying `blob:`, that `blob`, into a fresh directory's own `id`, `file`, `reason` and `blob` files,
one line each, and, only on a block carrying `replace` and `with`, those two texts whole into the
same directory's `replace` and `with` files, and calls
`bash <skill-dir>/scripts/check-reapply.sh "<the ledger>" "<the worktree root>" "<the block dir>"`.
The script refuses, exit 1, when the ledger carries no entry `id`, when `file` is not that entry's
own `- file:` line, when `file` resolves outside the worktree root, when `blob` is given and is
not the sha the entry's Incoming side names, or when `with` holds a line that is in neither
`replace` nor the entry's Incoming side, text the judge wrote rather than the side it brings back,
and on any of those the run writes nothing from the
block: the outcome is recorded `none`, the reason the script's, off the same call `ledger.sh
applied` below already makes, and the run goes on to the next entry rather than stopping over it.
Only once the script exits 0 does the session apply the edit itself, from the block the judge
returned: the `replace` text swapped for the `with` text in the
block's file, the file written back from its `blob:` line by
`bash <skill-dir>/scripts/write-blob.sh <the file> <the sha>` on a block carrying `take the
Incoming blob whole`, or the file removed from the index and the worktree on a block carrying
`remove the file`. The whole-side write goes through the index rather than a redirect into the
path, since the tree may hold that path as a symlink the Target side left there: a redirect would
follow it and land the run's bytes outside the worktree while the symlink, and so the index, stayed
unchanged, leaving nothing to commit. `write-blob.sh` guards against that the same way
`contested.sh`'s `stage_file` guards a hunk taken whole, and `check-reapply.sh` above already binds
the path it writes to back to the entry, so a block that passed the check but still names a path
outside the tree cannot reach `write-blob.sh` at all. No agent is forked and no test author is
dispatched: the edit is work the branch already carried before the rebase, not a behaviour this run
adds. Only that file is staged, and never by pasting its path into a command line the way the
all-mechanical state above never does either: the block dir's `file` line is read into a
shell variable, and `git add -- "$file"` stages it (`write-blob.sh` above already stages and checks
out the whole-side write the same way), so nothing else rides along. The commit's message is never
built as a command-line string: the run writes a fresh file whose title line reads `reapply: <the
file>` while its body names the entry's id, `Loss ledger entry <id>: <the reason>`, with the file's
path, the entry's id and the judge's reason read the same way, as shell variables, into that file
rather than pasted into the command line a `-m` flag would carry, and commits with `git commit -F
"<the message file>"`, so the ledger and the history point at each other without either value ever
sitting inside a command line as text:

```
file="$(cat "$dir/file")"
id="$(cat "$dir/id")"
reason="$(cat "$dir/reason")"
git add -- "$file"
msg="$(mktemp)"
printf 'reapply: %s\n\nLoss ledger entry %s: %s\n' "$file" "$id" "$reason" >"$msg"
git commit -F "$msg"
rm -f "$msg"
```

An edit whose `replace` text is no longer in the
file, or that leaves the staged tree equal to `HEAD`, makes no commit: the entry did not come back,
and the run goes on to the next one rather than stopping over it, since the reapplies before it are
already commits of their own.

Each outcome goes into the ledger, the commit's full sha, or `none` when nothing came back (a
refused check among the reasons `none` carries), and a
one-line reason, the commit's title or what kept it out, written into a fresh directory's `id`,
`commit` and `reason` files, one line each, and the run calls
`bash <skill-dir>/scripts/ledger.sh applied "<the ledger>" "<the entry dir>"`, one call per entry
judged `reapply`. The script refuses an entry that already carries an applied line, one with no
verdict and one judged `drop`, with nothing written, and the run records the refusal rather than
retrying it, the same way it records a refused verdict.

Then the gate's command lines run again: the whole **Gate** runs after the last reapplied commit,
all of its checks, once, never between two reapply commits, so what came back is held to the same checks as
everything else and the most expensive command of the run is paid once whatever the entry count.
A ledger with no entry judged `reapply` makes no commit, and the same run of the gate follows the
judging as after any replay. Once that **Gate** is green, the step is ticked with the totals, each
reapplied commit and each dropped entry, a `reapply` whose applied line reads `none` among the
dropped, and the ledger's location. The review is called only once that **Gate** is green, or the fix
call on a run the review already read.

A red **Gate** after the reapplied commits stops as blocked, never back to the build loop of
[build-loop.md](build-loop.md): the
branch now holds the developer's code the replay brought in beside the work that came back, and a
run that loops on it edits their work. The run never edits the branch's code to make the **Gate**
pass, never reruns it and never reverts a reapply commit to chase green. The reply carries the
failing check named off its red line, or the infrastructure cause on `verdict=blocked`, the ledger's
location, since the ledger holds what came back and what did not, and the command that undoes the
whole integration, `git reset --hard <the commit recorded before it started>`. The worktree and its
branch stay in place and are named, the Ticket stays `claimed`, nothing lands and nothing is
pushed.

**A replayed commit that is empty after the resolution.** The developer's branch already carries
that change, or the resolution took the **Target** side of every hunk the commit brought, so the
continue has nothing left to apply. Git refuses an empty commit and leaves the rebase where it is,
so the run never reaches that refusal: the block below is the continue every stop of this step ends
in, and it reads the staged tree against `HEAD` first.

```
if git diff --cached --quiet HEAD; then
  git log -1 --format='skipped %h %s' REBASE_HEAD
  git -c rerere.enabled=false -c rerere.autoupdate=false rebase --skip
else
  git -c rerere.enabled=false -c rerere.autoupdate=false rebase --continue
fi
```

The commit it skips is named in the reply off the `skipped <sha> <subject>` line the block printed,
and the rebase carries on to the next commit, where the stop is classed and resolved like any
other. Nothing of the run's work is lost without a trace: the change is either already on the
branch it was going to land on, or it is the **Incoming** side of a `contested` hunk and the
**Loss ledger** holds it whole.

**Git refusing to continue for any other reason.** The run stops as blocked with the rebase left
open at that commit, the conflicting files named, and the command that undoes it,
`git rebase --abort`, since the rebase has not finished and the abort is still there to take. The
worktree and its branch stay in place and are named, the Ticket stays `claimed`, nothing lands and
nothing is pushed. The blocked states carry two different undo commands, and each names its
own: the abort while the rebase is open, the reset to the recorded commit once it has finished.
