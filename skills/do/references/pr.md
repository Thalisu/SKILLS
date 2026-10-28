# Playbook: pr

The developer types `/do` with a pull request: its URL, in whatever words sit around it, or words
naming a pull request with its number, a request to fix its CI included, or words asking for a pull
request from one branch into another. The run
follows that one pull request, and the developer reads it afterwards, through the Reply.

## What this run never does

- Merge the pull request: the run never runs `gh pr merge`, not even on a green run. The merge is
  the developer's call, named as the next step.
- Open a pull request when one is already open for the pair: the run runs `gh pr create` only when
  no pull request is open for the branch pair it was asked for, and the create pushes nothing.
- Rebase the head branch, or push to it, on a conflict with the base: the run stops and names the
  owner of the head branch.

## The message

The run is one message, written by [reply.md](reply.md). It opens with `Playbook: pr` as plain text
on its first line.

## Steps

```
pr:
1. pull request: its URL or its number, or a branch pair, taken from the request as written, the GitHub CLI logged in
2. read-back: #<n>, its head into its base, off the GitHub CLI's answer
3. watch: pr-watch.sh in the foreground, called again on every pending verdict until it settles
4. fix: one do-pr-fixer fork per red check, its excerpt quoted in the brief
5. reply: by the reply reference
```

### 1. Pull request

The run takes the pull request from the request as the developer wrote it: the URL, or the number
the words name. It passes that to the GitHub CLI as it read it and never a pull request it guessed.

Words asking for a pull request from one branch into another name a branch pair, and the run takes
the pair from the request as written: the head is the branch the pull request comes from and the
base is the branch it goes into, so in `de dev para prod`, as in `from dev into prod`, `dev` is the
head and `prod` the base.

Words that name a head and no base, as in `abra um PR de dev`, are half a pair, and the run stops
there: it ends in one message asking for the base, and never fills the base in itself, not with
the default branch, not with `main`, not with a branch read off the repository or the checkout. It looks
nothing up and opens nothing: no lookup by the pair, no `gh pr create`.

Words that name a base and no head, as in `abra um PR para prod`, take the same stop: one message
asking for the head, and the run looks nothing up and opens nothing. It never takes the current
branch, the one checked out, as the head.

With both branches named, the run checks that the head and the base each exist before it looks
anything up: as a local branch (`git rev-parse --verify --quiet refs/heads/<branch>`) or as a
branch on the remote (`git ls-remote --exit-code --heads origin <branch>`). A head or a base that
does not exist, neither one nor the other, stops the run: the Reply opens with `Playbook: pr` on
its first line, then one line naming the branch that does not exist, never the GitHub CLI's raw error. The run looks
nothing up and opens nothing: no lookup by the pair, no `gh pr create`.

When both exist, after the existence check and before any lookup, the run reads the commits the
head carries that the base lacks, with `git rev-list <base>..<head>`. A branch the remote holds is read at the remote's tip: the
run fetches it (`git fetch origin <branch>`) and reads `origin/<branch>` in the range, never a local
branch of the same name. A branch with no copy on the remote is read as the
local branch. A head with no commits the base lacks, as one already merged into it, stops the run: the
Reply opens with `Playbook: pr` on its first line, then one line saying there is nothing to open
from the head into the base, rather than the GitHub CLI's error or an empty pull request. The run
looks nothing up and opens nothing: no lookup by the pair, no `gh pr create`.

With something to open, after the nothing-to-open check and before any lookup, the run asks the
remote itself whether it holds the head, with `git ls-remote --exit-code --heads origin <head>`. It
reads the answer off the remote and never off the local branch's upstream setting, nor off the
remote-tracking ref `refs/remotes/origin/<head>`. A
head the remote holds under the same name goes on to the lookup and is opened like any other. That holds
with or without an upstream on the local branch. A head that exists locally and has no branch on the remote, one never published, stops the run. The run pushes
nothing, no `git push`, and looks nothing up and opens nothing: no lookup by the pair, no
`gh pr create`. The Reply opens with `Playbook: pr` on its first line and carries exactly one
`Yours:` line, under the `outward` class, handing the push over with the head's name in both
places:
`Yours: outward: push <head> to the remote (git push -u origin <head>), then /do the request again`.

Before it reads the pull request, the run asks the GitHub CLI whether it is logged in, with
`gh auth status`. When that check fails, the run stops: the Reply opens with `Playbook: pr` on its
first line, then one line saying the GitHub CLI is not logged in and naming `gh auth login`, with no
`Yours:` line. A `gh` that is not installed, not on the `PATH`, takes the same stop with the same line. The run follows nothing: no read-back, no watch, no
worktree, no push, no file written. The check comes before the read-back.

For a branch pair, once the GitHub CLI answered that it is logged in, the run first looks for the
pair's open pull request before it opens anything, with
`gh pr list --head <head> --base <base> --state open --json number,headRefName,baseRefName,state`. The pair's open pull request is one whose head is the pair's head, whose base is the pair's
base, and whose `state` reads `OPEN`, each read off that answer: a pull request open from the head
into another base is not the pair's, and neither is a closed or merged one for the pair, so an
answer holding only those counts as none open for the pair.

When a pull request is already open for the pair, the run takes its number from that answer and
follows it by its number from the read-back on, as a pull request named by number is followed. It
opens nothing and never runs `gh pr create`. The Reply says the pull request was already open, on
its `Plan:` line beside the read-back.

When none is open for the pair, the run opens exactly one pull request, with
`gh pr create --head <head> --base <base> --fill`: head and base named explicitly, and its title and body filled from the commits between base and
head. A head that exists only on the remote, with no local branch of that name
(`git rev-parse --verify --quiet refs/heads/<head>` finds none), is opened with
`gh pr create --head <head> --base <base> --title <title> --body <body>` in place of `--fill`, the
title and body taken from the commits `origin/<base>..origin/<head>`, creating no local branch and never reading a stale local head. It
pushes nothing. The run takes the new
pull request's number from the URL `gh pr create` prints, and follows it by that number from the
read-back on, as an open one is followed: the watch runs on that number and the Reply reads on as
for a pull request named by its number. The Reply says the pull request was opened by the run, on
its `Plan:` line beside the read-back.

Done when the run holds the URL or the number, for a branch pair the number of the pull request it
found already open or opened for the pair, and the GitHub CLI answered that it is logged in.

### 2. Read-back

The read-back line, off the GitHub CLI's answer for that pull request and never the session's
wording: `gh pr view <the URL or the number> --json number,headRefName,baseRefName,state,isCrossRepository,headRepositoryOwner`,
read as `#<n>`, `<head>` into `<base>`, from its `number`, `headRefName` and `baseRefName`. It is the
Reply's `Plan:` line.

When `gh pr view` fails, the GitHub CLI cannot open the pull request (a wrong number, or a
repository the CLI cannot reach), and the run stops: the Reply opens with `Playbook: pr` on its
first line, then one line saying the pull request could not be opened, with no `Yours:` line, as
the router answers an issue reference its CLI cannot open. The run follows nothing: no watch, no
worktree, no push, no file written. A failure whose cause is the CLI itself, its error saying it is
not logged in, as on a pull request's host the CLI holds no login for, takes the step 1 stop and its
line naming `gh auth login` instead, never this line.

When gh opens the pull request and its `state` reads `CLOSED` or `MERGED`, the run stops the same
way: the Reply opens with `Playbook: pr` on its first line, then one line saying the pull request is
closed or merged, with no `Yours:` line. The run follows nothing: no watch, no worktree, no push, no file written.

When gh opens the pull request and its `isCrossRepository` reads true, its head lives in a fork, and
the run stops the same way: the Reply opens with `Playbook: pr` on its first line, then one line
naming the fork by its `headRepositoryOwner` login, with no `Yours:` line. The run follows nothing:
no watch, no worktree, no push, no file written, and no `do-pr-fixer` forked.

For a branch pair the read-back is the same line, off the GitHub CLI's answer for the pull request
the run follows, its `headRefName` into its `baseRefName`, and never off the request's wording.

Done when the line is recorded for the `Plan:` line and the pull request reads `OPEN`.

### 3. Watch

The run watches the pull request's checks with the watch script, in the foreground, with the Bash
tool's timeout at its 600000 ms maximum:

```
bash <skill-dir>/scripts/pr-watch.sh <pr> [<since> <state>] [<expected-sha>]
```

`<pr>` is the URL or the number step 1 took, passed as it stands, and the first call passes `<pr>`
alone. The script blocks on the checks for about nine minutes at most, and its first line is its
verdict. The run routes on that line alone and never on its own reading of `gh pr checks` or `gh pr view`, which it never runs to judge
the checks.

- `verdict=pending`: the checks are still running. The run runs the line again at once, in the
  foreground, without ending its turn: never in the background, never after a sleep of its own, and
  goes on calling it until it reads `verdict=green` or another settled verdict. On that next call it
  passes the verdict's `since=` and `state=` values as `<since>` and `<state>`, copied as they
  stand: the run never reads, never compares and never computes them.
- `verdict=green`: every check passed and the pull request is mergeable. The run goes on to step 5,
  the Reply.
- `verdict=awaiting-approval`: every check passed and only a required approval blocks the merge. The
  run goes on to step 5, the Reply, as on green, not a stop.
- `verdict=red`, when this run has pushed no round yet: a check failed.
  Read [pr-fix.md](pr-fix.md) when the watch prints its first `verdict=red`, then go on to its step
  4, Fix the red checks, carrying the verdict's `head=`, `sha=` and `red=` lines as they stand.
- `verdict=conflict`: the pull request conflicts with its base. The run stops with exactly one line,
  `Yours: direction: <head> conflicts with <base>; the owner of <head> rebases it onto <base>, then /do the pull request again`,
  taking `<head>` and `<base>` from the verdict's `head=` and `base=` lines, never from the
  read-back. The run never rebases and never pushes.
- `verdict=draft`: every check passed on a draft pull request, which cannot merge until it is marked
  ready. The run stops with exactly one line,
  `Yours: direction: the pull request is a draft and every check passed; mark it ready for review, then /do the pull request again`.
  The run never marks it ready itself.
- `verdict=behind`: every check passed and the head branch lacks commits of its base. The run stops
  with exactly one line,
  `Yours: direction: <head> is behind <base>; update <head> from <base>, then /do the pull request again`,
  taking `<head>` and `<base>` from the verdict's `head=` and `base=` lines. The run never updates
  the branch and never pushes.
- `verdict=changes-requested`: every check passed and a reviewer asked for changes. The run stops
  with exactly one line,
  `Yours: direction: a reviewer requested changes on <head>; address them or ask the reviewer to dismiss the review, then /do the pull request again`,
  taking `<head>` from the verdict's `head=` line. The run never dismisses the review and never
  pushes.
- `verdict=cancelled`: no check is pending or failed and at least one was cancelled. The run stops
  with exactly one line,
  `Yours: direction: <the cancelled checks> were cancelled; re-run them, then /do the pull request again`,
  where `<the cancelled checks>` is the names on the verdict's `cancelled=` lines (the name after
  the link, never the link), in the order printed, joined with `, `. The run reruns nothing and forks
  no `do-pr-fixer` for a cancelled check.
- `verdict=stalled`: a check is still pending and no check changed state for about 60 minutes of
  consecutive watches. The run stops with exactly one line,
  `Yours: direction: <the pending checks>; re-run or unblock the runner, then /do the pull request again`,
  where `<the pending checks>` is the verdict's `pending=` values, in the order printed, joined with
  `, `. The stop is keyed on the script's verdict alone, never on a count of watches the run keeps.
- Any other verdict word: the run stops with one line quoting that verdict as printed, then
  exactly one
  `Yours: direction: pr-watch.sh printed a verdict this run does not follow; read what it printed, then /do the pull request again`,
  and follows nothing.
- A non-zero exit of the script: the run stops with one line quoting the script's stderr line, then
  exactly one
  `Yours: direction: pr-watch.sh failed; fix what its stderr line names, then /do the pull request again`,
  and follows nothing.

The verdict line of each call, in order, is recorded for the Run report's Run section, which is
written under `--auto` only, per [reply.md](reply.md): the round is never a section of the Reply.

Done when the watch has printed `verdict=green`, `verdict=awaiting-approval` or `verdict=red`, after as
many `pending` calls as the checks took.

### 4. Fix the red checks

Read [pr-fix.md](pr-fix.md) when the watch prints its first `verdict=red`.

### 5. Reply

The Reply, by [reply.md](reply.md), its `Plan:` line the read-back of step 2. Read [run-report.md](run-report.md) when the run is under `--auto`, before it writes the Run report. Its five
parts are the whole message, and a green watch adds no part of its own:

- **For whom** says every check is green and the pull request mergeable, ready for the developer
  to merge, with the count off the watch's `checks=<n>` line (`checks=0` reads as no checks
  reported).
- No `Yours:` line: a green run hands nothing over.
- The **Next step** line ends with `gh pr merge <n>`, `<n>` the number step 2 read back. The run
  never runs it and never names it under `outward`, per the Next step item of [reply.md](reply.md).
- On `verdict=awaiting-approval`, **For whom** says every check is green, with the same count, and
  that only a required approval is missing before the pull request can merge; no `Yours:` line; and the
  **Next step** line names the approval, then `gh pr merge <n>` once it is given, which the run
  never runs and never names under `outward`.
- The **Next step** is the stdout of `scripts/next-step.sh`, copied whole: `outcome=pr-green`, or
  `outcome=pr-awaiting-approval` on that verdict, piped with `pr=<n>` and `pushed=no`.
