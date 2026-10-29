# The conflict loop

What a run does at every stop of a replay, in the order it does it: class the conflicted hunks with
a script, resolve the mechanical ones by the union rule, resolve the contested ones to the
**Target** side with their **Incoming** side written to the **Loss ledger**, then judge that ledger
and bring its reapplies back. Two words hold throughout: the **Target** side is the developer's
branch, the one the replay lands on (index stage 2), and the **Incoming** side is the commit being
replayed (index stage 3).

It is read by the step that reaches a stop, which reads it whole: the integration step of
[mechanics.md](mechanics.md), which the worktree Playbooks run, the rebase of the Spec branch in
the Final integration of that same file, and the operation step of [integrate.md](integrate.md).
That last step builds in no worktree, so it substitutes its own continue, abort, ledger path and
judge's brief for this file's, and runs no **Gate** after the reapplies.

One reader reaches no stop at all and reads one state only: the no-op state of that same integration
step, **A rebase that replays no commit.** of [mechanics.md](mechanics.md), where the ancestor check
excused the rebase and the ledger still carries an entry judged `reapply` with no applied line. It
reads **The reapplies brought back** below and nothing else here. It brings the entry back the way
that state does, through `check-reapply.sh` and never around it: the check binds that block's
`file`, its `blob` and its `with` back to the entry before the session writes anything.

## The conflict loop

The loop runs in two parts, and each state below is one piece of them:

1. At every stop of the rebase: class the hunks, resolve the stop by the route its class names,
   then continue. An all-mechanical stop takes the two blocks of the first state, a stop with a
   `contested` hunk takes the one call of the contested state, and both end in the same continue
   block, the one the empty-commit state prints.
2. After the last stop: judge the **Loss ledger**, bring each entry judged `reapply` back as a
   commit of its own, then run the **Gate** where the run owes one.

The loop ends in one of two ways: the integration finished and its step ticked, or the run stopped
as blocked. Between those two the run keeps going: a resolved stop, a judged ledger and a reapply
commit are each followed by the next command, never by a summary that closes the turn or a question
to the developer.

A blocked stop while the rebase is open always carries these blocker lines above its `Yours:` line,
and each state below names only the reason it quotes: the rebase left open at that commit, the
conflicting files named, `git rebase --abort` named as the command that undoes it, the worktree and
its branch left in place and named, nothing landed and nothing pushed, and, at a `ticket` run's own
integration step only, the Ticket left `claimed`.

**A rebase that stopped.** At every stop of the rebase, before it resolves, stages or writes
anything, the run classes the conflicted hunks: `bash <skill-dir>/scripts/conflict-class.sh`. The
script's verdict is the class, never the session's own reading of the markers. Its lines, one per
conflicted hunk, are quoted in the Run report's Evidence, and the counts, how many hunks were
resolved mechanically and how many took the **Target** side, go on the integration line of its Run
section, both written under `--auto` alone.

A stop the script answers with `no conflicted state, nothing classed` is never continued unasked. A
run that opened the rebase itself meets that stop when git refuses a step no hunk carries, an
untracked file the replay would overwrite for one. The run stops as blocked with git's own message
quoted as it printed it, the rebase left open at that commit and `git rebase --abort` named as its
undo. A resumed run meets the same stop only after the mid-rebase bullet of resume.md continued on
`resume-state.sh`'s `stop=resolved` or `stop=moved` line: on the answer to its question that says
so, or on `moved=continue`, which puts no question.

Where every hunk of the stop is `mechanical`, the run resolves them itself and nothing is asked of
the developer. The two blocks below run as they stand, with nothing pasted into them: a conflicted
path never enters a command line as text. The blocks read the list git left NUL-delimited,
`git diff --name-only --diff-filter=U -z`, and each path reaches git through a shell variable or
through `xargs -0`.

The first block does two things in order. It stages every file the script printed `trusted`, one the
developer resolved by hand and never staged, from the script's own read-only list of them. Then it
takes the three stages of every file still conflicted out of the index and writes their union:

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

The union keeps both sides, the developer's branch (stage 2) above the replayed commit's (stage 3).
The `--diff3` stays, keeping the lines both sides' additions share. Git writes the result and the
session never edits a marker.

The second block reads every union back, as the next state says, and marks the files resolved only
once the read-back returned:

```
git diff --name-only --diff-filter=U -z | bash <skill-dir>/scripts/last-wins.sh "<the ledger>" &&
  git diff --name-only --diff-filter=U -z | GIT_LITERAL_PATHSPECS=1 xargs -0 git add --
```

Then the continue block, the one every stop of this step ends in, carries the rebase to the next
commit, and every further stop is classed and resolved the same way. The Run report names every hunk
it resolved with its file and location, and every `trusted` file as taken on trust, kept as the
developer wrote it and out of the ledger. A `trusted` file is never among the paths the read-back is
handed, and nothing of this step rewrites it.

**A union that defines the same key twice.** Where both sides added a definition of one key at the
same anchor of a file whose reader takes the last definition it meets (JSON, YAML, TOML, an INI or a
`.env` file), the union keeps both lines. The second block above reads every union back before it
marks a file resolved, and the read-back is `last-wins.sh`'s and never the session's.

What the read-back does, by what it finds, with nobody asked anything in any of the four:

- A key defined twice in one scope of one of those files: the file keeps the **Target**'s
  definition, and the **Incoming**'s is dropped from the file and goes to the **Loss ledger** as an
  entry of its own, shaped `last-wins-duplicate` and keyed by the file and the key path; a rerun at
  the same stop rewrites it where it stands.
- Two definitions written byte for byte alike: they come out as one with no entry.
- A key the base itself already defined twice: left as it stands.
- A file whose format the script does not know: left untouched.

The script prints `kept <file> <key path>` and `deduped <file> <key path>`, then
`read-back files=<n> kept=<n> deduped=<n>`, and those lines are quoted in the Run report's Evidence
beside the hunks the union resolved. A read-back that exits non-zero, a refused ledger or a file it
could not rewrite, leaves the staging beside it unrun, and the continue then meets a stop git
refuses, which the last state of this section handles.

**A stop carrying a contested hunk.** A hunk classed `contested` is resolved by a script to the
**Target** side, and nobody is asked anything: neither the developer nor the session writes a hunk
of their own, and a headless run resolves the stop the same way. The two blocks above are the
all-mechanical stop's alone and never run here. Here one call resolves the whole stop:

```
bash <skill-dir>/scripts/contested.sh "<the ledger>"
```

The script takes the order, the class and the locations from `conflict-class.sh` and the sides from
the index stages, and the session reads no marker here either. What it writes, by file:

- A file whose hunks are all `mechanical`: written by the union rule.
- A file carrying a `contested` hunk: written once from its three stages, its `mechanical` hunks by
  the same rule and its `contested` hunks from the **Target** stage.
- A file the script cannot splice (a delete against an edit, a rename against an edit, a binary
  file, a file too large to merge, a file git's merge cannot line up with the index): taken whole
  from the **Target** stage, or removed where the **Target** deleted it.
- A file the conflict class printed `trusted`: staged as it stands.

Each file is staged and named on a `wrote`, `removed` or `trusted` line, and the last line is
`resolved mechanical=<n> contested=<n>`.

The **Incoming** side of every `contested` hunk goes to the run's **Loss ledger**, whose shape
[loss-ledger-format.md](../../../.agents/formats/loss-ledger-format.md) fixes, one entry per hunk
keyed by its hunk id, written before any file of the stop: the file, the location, the shape, the
replayed commit, the commit the branch was on before the rebase, the **Target** side quoted and the
**Incoming** side whole. A file taken whole leaves one entry holding both sides whole, and a binary
or too-large side is named by its size, its blob and the commit recorded before the rebase, from
which the blob stays reachable. A rerun at the same stop rewrites each entry where it stands.

The ledger is one file per run, in the main checkout unless the Ticket lives in another repository,
and its path is fixed before the rebase starts:

- in `ticket`, beside the Ticket, the path the door printed as `ticket=` with `.ledger` before the
  extension, `01-x.ledger.md` beside `01-x.md`, which on a Ticket run from its Build repository is
  in the Home repository and reached by its absolute path; for a Ticket that is not a local file, the issue's
  reference under `.scratch/ledgers/` there, with `.md` after it;
- in `bug-fix` and `refactoring`, `.scratch/ledgers/<branch>.md` in the main checkout, with every
  `/` of the run's branch written as `-`, the key the Review beside the branch already uses.

The worktree reaches the ledger by that absolute path and never copies it, and every stop of the
same rebase passes the same path. The script refuses a path that does not resolve under the main
checkout's `.scratch/`, or under the `.scratch/` at the root of another main checkout, the Home
repository's on a Ticket run from its Build repository, with nothing written.

What the script prints and the code it exits with say what the run does next. On exit 2, 3 or 4 the
run stops as blocked, with the blocker lines the top of this section fixes and the reason named
here.

- `resolved` (exit 0): the stop is resolved and staged, each file the script wrote by the union rule
  already read back for a key defined twice on its way through, as the state above says. The run
  ends the stop in the continue block, and the next stop is classed like any other.
- Exit 2: a usage fault, no stopped rebase or merge, no contested hunk at that stop, or the ledger
  refused, with nothing written. The reply quotes the script's reason.
- Exit 3: git refused to write the index for a file, named on the script's `git refused to stage
  <file>` line, with no `wrote`, `removed`, `trusted` or `resolved` line for it and every other file
  of the stop left as it stood. The reply quotes the script's reason.
- Exit 4: the read-back refused a file the union rule wrote, on its own reason line (`blocked
  <file>` when the file defines its duplicated keys more times than the read-back's cap,
  `could not rewrite <file>`, or the ledger refused) followed by `read-back refused <file>`, with no
  `wrote` or `resolved` line for it. The reply quotes both lines, and the run never reads the stop
  as git's refusal.

Once the rebase finishes, the step is ticked with the totals across every stop, the mechanical and
the contested hunks counted from each verdict line, and the ledger's location.

**The Loss ledger judged.** Every entry the rebase left is judged, kept or let go, before the gate
runs again.

Which entries are still waiting is the script's answer and never the session's own reading of the
file: `bash <skill-dir>/scripts/ledger.sh pending "<the ledger>"` prints the id of each entry
carrying no verdict, in file order. It reads a heading outside a fence only: a `## <id>` line one of
the sides quotes is never an entry of its own. No id at all is an empty ledger, a rebase that set
nothing aside, or one whose entries an earlier run already judged: nothing is forked, no verdict is
written and the step goes straight on.

With at least one id, the run calls the Agent tool with `subagent_type: ledger-judge`, the agent
`do` ships in [ledger-judge.md](../agents/ledger-judge.md), once per integration and never once per
entry. The brief carries four things:

- the ledger's location;
- the worktree root, which is the Spec's tree (`tree=`) in the Final integration;
- the ids `pending` named;
- the run's intent, which is the Digest's location at a `ticket` run's own integration step, the
  request's line in `bug-fix`, `refactoring` and `integrate`, and the Spec's location (the `spec=`
  line its claim printed) in the Final integration.

The fork holds reading and search alone, and the session writes what it returns.

It returns one block per entry: the id, `reapply` or `drop`, a one-line reason, and, on a
`reapply`, the edit against the tree as it now stands, which the state below brings back. The
session writes each reading where the ledger keeps it, one block at a time:

1. The id, the verdict word and the reason go into a fresh directory's `id`, `verdict` and `reason`
   files, one line each.
2. The run calls `bash <skill-dir>/scripts/ledger.sh verdict "<the ledger>" "<the entry dir>"`.

The verb takes an entry directory, the shape `put` already takes, never loose arguments. A resumed
run judges only what `pending` named. An id the judge names that `pending` did not, and an id that
already carries a verdict, are both refused by the script with nothing written, and the run records
the refusal rather than retrying it.

No judge can be forked on two branches: the Agent tool is withheld from the session, or the Agent
tool lists no `ledger-judge`, as it does on a machine that never linked the agent `do` ships. On
either branch the session judges the pending entries itself, reading each entry and the file it
names, and writes the same verdicts through the same verb. It says in one line which branch holds,
the Agent tool withheld, or `ledger-judge` not listed, the agent this machine has not linked, which
one run of the skills repository's `scripts/link-skills.sh` links before the next `/do`. The run
neither stops nor asks for the agent, and never forks another agent in its place.

**The reapplies brought back.** Every entry judged `reapply` comes back as one commit per `reapply`
on top of the finished integration, in the order `pending` printed them. No agent is forked and no
test author is dispatched.

A script binds the block the judge returned to its entry before the session writes anything from it,
and none of its values ever sits inside a command line as text. For each entry, in order:

1. **Write the block down.** Into a fresh directory, one line per file: the block's `id` and `file`
   and the entry's `reason` into its `id`, `file` and `reason` files; only on a block carrying
   `blob:`, that `blob` into its `blob` file; and only on a block carrying `replace` and `with`,
   those two texts whole into its `replace` and `with` files.
2. **Check it.** The run calls
   `bash <skill-dir>/scripts/check-reapply.sh "<the ledger>" "<the worktree root>" "<the block dir>"`.
   The script refuses, exit 1, when:
   - the ledger carries no entry `id`;
   - `file` is not that entry's own `- file:` line;
   - `file` resolves outside the worktree root;
   - `blob` is given and is not the sha the entry's Incoming side names;
   - `with` holds a line that is in neither `replace` nor the entry's Incoming side, text the judge
     wrote rather than the side it brings back.

   On any of those the run writes nothing from the block: the outcome is recorded `none`, the reason
   the script's, through the `ledger.sh applied` call of step 5, and the run goes on to the next
   entry rather than stopping over it. Exit 2 is a fault of the call rather than of the block (no
   ledger at the path, no `realpath` on this machine, a block dir with no `id` or `file` file): the
   run writes nothing from it either, and records it the same way, `none` with the script's stderr
   line as the reason.
3. **Apply the edit.** Only once the script exits 0 does the session apply the edit itself, from the
   block the judge returned, by what the block carries:
   - `replace` and `with`: the `replace` text swapped for the `with` text in the block's file;
   - `take the Incoming blob whole`: the file written back from its `blob:` line by
     `bash <skill-dir>/scripts/write-blob.sh <the file> <the sha>`;
   - `remove the file`: the file removed from the index and the worktree.

   The whole-side write goes through `write-blob.sh` and the index, never a redirect into the path.
4. **Commit that file alone.** The block below runs as it stands, with `$dir` the block dir and
   nothing pasted into it, the way the all-mechanical state's blocks run. The file's path, the
   entry's id and the judge's reason are read into shell variables: `git add -- "$file"` stages only
   that file (`write-blob.sh` already staged and checked out the whole-side write the same way), and
   the message is written to a fresh file and committed with `git commit -F`, never as the
   command-line string a `-m` flag would carry. Its title line reads `reapply: <the file>` and its
   body names the entry's id, `Loss ledger entry <id>: <the reason>`:

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

   An edit whose `replace` text is no longer in the file, or that leaves the staged tree equal to
   `HEAD`, makes no commit: the entry did not come back, and the run goes on to the next one rather
   than stopping over it.
5. **Record the outcome.** The commit's full sha, or `none` when nothing came back (a refused check
   among the reasons `none` carries), and a one-line reason, the commit's title or what kept it
   out, go into a fresh directory's `id`, `commit` and `reason` files, one line each, and the run
   calls `bash <skill-dir>/scripts/ledger.sh applied "<the ledger>" "<the entry dir>"`, one call per
   entry judged `reapply`. The script refuses an entry that already carries an applied line, one
   with no verdict and one judged `drop`, with nothing written, and the run records the refusal
   rather than retrying it, the same way it records a refused verdict.

Then the gate's command lines run again, only before the first review call: the whole **Gate** runs
after the last reapplied commit, all of its checks, once, never between two reapply commits. A run
whose next step is the fix call on a Review it already has skips that **Gate**. A ledger with no
entry judged `reapply` makes no commit, and, where the **Gate** runs at all, the same run of it
follows the judging as after any replay.

The step is ticked with the totals, each reapplied commit and each dropped entry, a `reapply` whose
applied line reads `none` among the dropped, and the ledger's location. The review is called only
once that **Gate** is green, and the fix call on a run the review already read is made with no
**Gate** of the run's own before it.

A red **Gate** after the reapplied commits stops as blocked, never back to the build loop. The run
never edits the branch's code to make the **Gate** pass, never reruns it and never reverts a reapply
commit to chase green. The rebase has finished by then, so this blocker is its own and not the
open-rebase one: it carries the failing check named off its red line, or the infrastructure cause on
`verdict=blocked`, the ledger's location, and the command that undoes the whole integration,
`git reset --hard <the commit recorded before it started>`. The worktree and its branch stay in
place and are named, nothing lands and nothing is pushed, and at a `ticket` run's own integration
step the Ticket stays `claimed`, the clause the open-rebase blocker lines carry and on the same
terms.

**A replayed commit that is empty after the resolution.** The developer's branch already carries
that change, or the resolution took the **Target** side of every hunk the commit brought: the
continue has nothing left to apply. The block below is the continue every stop of this step ends in,
and it reads the staged tree against `HEAD` first, skipping an empty commit instead of continuing
it.

```
if git diff --cached --quiet HEAD; then
  git log -1 --format='skipped %h %s' REBASE_HEAD
  git -c rerere.enabled=false -c rerere.autoupdate=false rebase --skip
else
  git -c rerere.enabled=false -c rerere.autoupdate=false -c core.editor=true rebase --continue
fi
```

The commit it skips is named in the Run report off the `skipped <sha> <subject>` line the block
printed, and the rebase carries on to the next commit, where the stop is classed and resolved like
any other.

**Git refusing to continue for any other reason.** The run stops as blocked with git's own message
quoted and the blocker lines the top of this section fixes, `git rebase --abort` named as its undo.
The blocked stops carry two different undo commands, and each names its own: the abort while the
rebase is open, the reset to the recorded commit once it has finished.
