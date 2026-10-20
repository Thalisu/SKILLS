---
name: debt
description: "Gather a feature's Pending debt (its Debt files and the Review Findings still open) and judge it into a Debt review beside the Spec"
disable-model-invocation: true
argument-hint: "[--no-fix] <slug>"
---

# Debt

Settle a feature's Pending debt: gather the Debt files and the Review Findings still open, then
judge them. This file holds three steps: the door, the judgment, then the fix.

The developer's argument sits at the end of this file, between the `<arguments>` tags: the feature
slug, optionally preceded by `--no-fix`. `<skill-dir>` below is the directory this file sits in.
The steps run in order, and each stop they name ends the command there.

## 1. The door

Run the gather script on the slug exactly as the developer typed it, before anything else:

```sh
bash <skill-dir>/scripts/gather.sh <slug>
```

When the argument opens with `--no-fix`, the session strips the flag and runs gather.sh on the slug
alone (the word after it), never handing the flag to a script. Under `--no-fix`, gather.sh's exit 5
(nothing is new) stops the run there: no fix, so no `debt/<slug>` and no worktree is cut, and no
`do-code-review` is called.
The stop prints two lines and ends on them: first one line telling the developer to overrule a
Finding by moving it to `Consider` or `Cleared` and never deleting it, because a deleted Finding
comes back as new and is judged again on the next run; then `/debt <slug>` as the run's last line,
`<slug>` being the `slug=` value gather.sh printed.

The session never parses a Debt file or a Review itself: gather.sh reads both. It relays the
`line=` value the script printed and decides on the script's exit code:

| What came back | What this session does |
|---|---|
| exit 3 | The slug names no feature folder. Print the `line=` value as the run's only line and stop: the run ends on that one line, forks no agent and writes nothing. |
| exit 4 | The checkout is on a detached HEAD. Print the `line=` value as the run's only line and stop: the run ends on that one line, forks no agent and writes nothing. |
| exit 1 | The feature owes no debt. Print the `line=` value as the run's only line and stop: the run ends on that one line, forks no agent and writes nothing. |
| exit 2 | Stop, printing the script's stderr line as the one line. |
| exit 0 | Print the `line=` value (`Judging <n> debt items of <folder>`) as the status line, then hand every `item=` record to step 2. |
| exit 5 | A Debt review exists and no gathered item is new. Print nothing, with no status line: fork no evaluator, make no run directory, skip step 2 and never call debt-review.sh. Go straight to step 3 (the fix) with the `review=` value gather.sh printed. |

## 2. The judgment

The judgment runs on the `item=` records the door handed over. The session forks the evaluators and
waits on their return files, and the script does the rest.

Make the run's directory first, and call it `<dir>` below:

```sh
mktemp -d "${TMPDIR:-/tmp}/debt.XXXX"
```

Make one Agent tool call per `item=` record, all in one message, each with
`subagent_type: debt-evaluator`, never a general-purpose agent. Each brief is exactly six keys, one
per line, `<k>` being the item's number among the records:

```
Item: <k>
Source: <the record's source=, byte for byte>
Text: <the record's text=>
Folder: <folder=>
Spec: <spec=>
Return file: <dir>/item-<k>.md
```

The Agent tool may hand back before the evaluators are done, since the harness runs subagents in the
background. The session never ends the turn on that handback. It runs the wait on every return file,
with the Bash tool's `timeout` set to `600000` ms:

```sh
bash <skill-dir>/../../.agents/scripts/returns.sh 240 <dir>/item-1.md ... <dir>/item-<n>.md
```

When it comes back with `missing=` lines, call it again over the `missing=` files only. Run three
windows and no more, then go on.

When the Agent tool is withheld, or does not list `debt-evaluator`, the session forks nothing and goes
straight to the compose call: every item then reads as not returned.

Compose the Debt review:

```sh
bash <skill-dir>/scripts/debt-review.sh <slug> <dir>
```

On exit 0 it prints `review=<path>` and `line=Written to <path>`. The session never reads a return
file itself and never places an item in a Bucket: the script does both.

On a rerun it appends the new Findings to the existing Debt review instead of rewriting it. When
nothing is new beside an existing Debt review, the script's exit 5 prints `review=<path>` and no
`line=`: the session prints nothing and goes straight to step 3 (the fix) with that `review=` value.

Show the Debt review file's text, then the `line=` value (`Written to <location>`). The judgment
ends on those lines, and step 3 follows.

Under `--no-fix` the run stops once the Debt review is written, after the Debt review's text and
`Written to <location>` are shown, and likewise stops at once on debt-review.sh's exit 5 (nothing is
new): it calls no `debt-branch.sh`, so no `debt/<slug>` and no worktree is cut, and calls no
`do-code-review` (no fix run).
Either stop prints two lines and ends on them: first one line telling the developer to overrule a
Finding by moving it to `Consider` or `Cleared` and never deleting it, because a deleted Finding
comes back as new and is judged again on the next run; then `/debt <slug>` as the run's last line,
`<slug>` being the `slug=` value gather.sh printed.

## 3. The fix

The fix runs after the Debt review's text and `Written to <location>`. Cut the branch, `<slug>` being
the `slug=` value gather.sh printed and `<review>` the `review=` value gather.sh or debt-review.sh
printed, whichever printed it:

```sh
bash <skill-dir>/scripts/debt-branch.sh <slug> <review>
```

The session runs no git and parses no file itself. It decides on the script's exit code:

- exit 4: the main checkout has uncommitted changes. Print the `line=` value (`working tree has
  uncommitted changes; commit or stash before fix`) as the run's last line, after
  `Written to <location>`, and stop, with no `cd` and no Skill call, so no fix run is called and no
  Fixer is forked.
- exit 3: print the `line=` value as the run's last line and stop, calling no fix run. This covers
  the refusals of a resume or a recut too (a landed `debt/<slug>` whose worktree has uncommitted
  changes, or that git would not remove, or whose Debt review's Fixed point could not be moved; a
  `debt/<slug>` checked out at another path), all handled the same way.
- exit 2: print the script's stderr line and stop.
- exit 0: a first cut, a resume of a `debt/<slug>` a run left in place without landing (its
  worktree, its commits and the Debt review's Fixed point kept), or a recut of one that landed
  (removed and cut again from the developer's current tip, which becomes the Fixed point). The
  session does the same thing on all three: it goes on with the `worktree=`, `main=`, `call=` and
  `tickets=` values (the last when the script printed one), and does not read or relay the line the
  script prints first.

On exit 0, enter the worktree with a bare `cd <worktree>` (the `worktree=` value) in a shell call of its
own, nothing before or after it, per `.agents/worktrees.md`: never the harness's worktree tool.

```sh
cd <worktree>
```

Then call the Skill tool with `do-code-review` and the `call=` value as its arguments, as printed: no
Gate and no `Caller:` line, so it is a developer's fix run that forks the Fixers on `debt/<slug>` and
lands on the developer's branch. The call is made whatever `Act on` holds: the run never skips it
and never writes the `## Fix run` section itself.

Then return with a bare `cd <main>` (the `main=` value) in a shell call of its own:

```sh
cd <main>
```

The run ends with the fix run's reply as it returned: one fix line per `Act on` Finding, then
`landed at <sha>`, then the `push command` as the run's last line.

With nothing in `Act on`, the fix run forks no Fixer and the Debt review's `## Fix run` section reads
`nothing remained`, written by the fix run, which still runs its Gate and ends on its landing line and
the push command.

When the Debt review is not Green, the fix run's reply ends on its `not landed:` landing line instead
of `landed at <sha>`, for example `not landed: Finding <n> not fixed or not verified; the branch
debt/<slug> and its worktree stay in place`, naming the Findings it did not fix. The run relays that
line as the fix run returned it, never rewritten, and removes neither `debt/<slug>` nor its worktree,
which stay in place. The reply still follows that line with the push command, so the push command
stays the run's last line, as it does after `landed at <sha>`.

The script prints a `tickets=` value when a `## Consider` Finding is marked `too big for a Fixer`.
When it did, the run puts that `tickets=` value (the `/tickets <spec>` line) on its own line just
before the push command, the fix run's reply's last line, so the push command stays the run's last
line. When the script printed no `tickets=`, nothing is inserted.

When the session does not list `do-code-review`, the run checks that before the cut, so nothing is cut:
it prints `skip: do-code-review not listed` as its last line and stops.

<arguments>
$ARGUMENTS
</arguments>
