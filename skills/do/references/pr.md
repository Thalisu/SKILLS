# Playbook: pr

The developer types `/do` with a pull request: its URL, in whatever words sit around it, or words
naming a pull request with its number, a request to fix its CI included. The run
follows that one pull request, and the developer reads it afterwards, through the Reply.

## What this run never does

- Merge the pull request: the run never runs `gh pr merge`, not even on a green run. The merge is
  the developer's call, named as the next step.

## The message

The run is one message, written by [reply.md](reply.md). It opens with `Playbook: pr` as plain text
on its first line, so a request the router misread shows at once, before anything else is read.

## Steps

```
pr:
1. pull request: its URL or its number, taken from the request as written, the GitHub CLI logged in
2. read-back: #<n>, its head into its base, off the GitHub CLI's answer
3. watch: pr-watch.sh in the foreground, called again on every pending verdict until green
4. reply: by the reply reference
```

### 1. Pull request

The run takes the pull request from the request as the developer wrote it: the URL, or the number
the words name. It passes that to the GitHub CLI as it read it and never a pull request it guessed,
since a guessed number that exists answers like the right one.

Before it reads the pull request, the run asks the GitHub CLI whether it is logged in, with
`gh auth status`. When that check fails, the run stops: the Reply opens with `Playbook: pr` on its
first line, then one line saying the GitHub CLI is not logged in and naming `gh auth login`, with no
`Yours:` line, since the one input to fix is the developer's session and there is no choice to hand
over. A `gh` that is not installed, not on the `PATH`, takes the same stop with the same line, since
logging in is what follows installing it. The run follows nothing: no read-back, no watch, no
worktree, no push, no file written. The check comes before the read-back so that a logged-out CLI
never reads as a pull request that could not be opened.

Done when the run holds the URL or the number and the GitHub CLI answered that it is logged in.

### 2. Read-back

The read-back line, off the GitHub CLI's answer for that pull request and never the session's
wording: `gh pr view <the URL or the number> --json number,headRefName,baseRefName,state`, read as
`#<n>`, `<head>` into `<base>`, from its `number`, `headRefName` and `baseRefName`. It is the
Reply's `Plan:` line, so a request the session misread shows on the Reply's first lines, as the
wrong pull request or the wrong branches, before the developer reads anything else.

When `gh pr view` fails, the GitHub CLI cannot open the pull request (a wrong number, or a
repository the CLI cannot reach), and the run stops: the Reply opens with `Playbook: pr` on its
first line, then one line saying the pull request could not be opened, with no `Yours:` line, as
the router answers an issue reference its CLI cannot open. The run follows nothing: no watch, no
worktree, no push, no file written. A failure whose cause is the CLI itself, its error saying it is
not logged in, as on a pull request's host the CLI holds no login for, takes the step 1 stop and its
line naming `gh auth login` instead, never this line.

When gh opens the pull request and its `state` reads `CLOSED` or `MERGED`, the run stops the same
way: the Reply opens with `Playbook: pr` on its first line, then one line saying the pull request is
closed or merged, with no `Yours:` line, since such a pull request has no head left to follow to
green. The run follows nothing: no watch, no worktree, no push, no file written.

Done when the line is recorded for the `Plan:` line and the pull request reads `OPEN`.

### 3. Watch

The run watches the pull request's checks with the watch script, in the foreground, with the Bash
tool's timeout at its 600000 ms maximum, since its two-minute default kills the watch before it
prints a verdict:

```
bash <skill-dir>/scripts/pr-watch.sh <pr>
```

`<pr>` is the URL or the number step 1 took, passed as it stands. The script blocks on the checks
for about nine minutes at most, and its first line is its verdict. The run routes on that line
alone and never on its own reading of `gh pr checks` or `gh pr view`, which it never runs to judge
the checks: a display read mid-run can show green while a check is still running.

- `verdict=pending`: the checks are still running. The run runs the same line again at once, in
  the foreground, without ending its turn: never in the background, never after a sleep of its own,
  and goes on calling it until it reads `verdict=green`. The developer has walked away, and a run
  that ends its turn here stands still until they come back.
- `verdict=green`: every check passed and the pull request is mergeable. The run goes on to step 4,
  the Reply.
- Any other verdict word: the run stops with one line quoting that verdict as printed, and follows
  nothing.
- A non-zero exit of the script: the run stops with one line quoting the script's stderr line, with
  no `Yours:` line, and follows nothing.

The verdict line of each call, in order, is recorded for the Run report's Run section, which is
written under `--auto` only, per [reply.md](reply.md): the round is never a section of the Reply.

Done when the watch has printed `verdict=green`, after as many `pending` calls as the checks took.

### 4. Reply

The Reply, by [reply.md](reply.md), its `Plan:` line the read-back of step 2. Its five parts are
the whole message, and a green watch adds no part of its own:

- **For whom** says every check is green and the pull request mergeable, ready for the developer
  to merge, with the count off the watch's `checks=<n>` line (`checks=0` reads as no checks
  reported).
- No `Yours:` line: a green run hands nothing over.
- The **Next step** line ends with `gh pr merge <n>`, `<n>` the number step 2 read back. The run
  never runs it and never names it under `outward`, the way a landed run names the push it never
  makes, per the Next step item of [reply.md](reply.md).
