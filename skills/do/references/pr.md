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
  owner of the head branch, the only one who may rewrite it.
- Commit in, check out or move anything in the developer's checkout: the round is brought onto the
  head in a worktree of the run's own, cut detached at the commit the checks ran on, so the
  developer's branch, HEAD and uncommitted work read after the run as they did before it.
- Push to any branch but the head, push with `--force`, or merge into the head: the round's one
  push is `HEAD:refs/heads/<head>` by fast-forward only, and git's refusal of anything else stops
  the run (ADR 0086).
- Pick, and so push, a fixer's commit that changes a CI workflow, a secret or a migration file: that
  commit moves the bar the checks hold, so the run stops instead, naming the check and the file.
- Fork a fixer for a check `pr-classify.sh` printed `stale`, or rebase the head to clear one: the
  check stops the run, naming its file, and the rebase is the head owner's.
- Fix a check in the session: each red check is one `do-pr-fixer` fork (ADR 0088).
- Rerun a check unless its `do-pr-fixer` returned `not reproduced` or `not run`, and never rerun it
  because the session read its log as a flake.
- Rerun a check on a round that pushed, or rerun one check twice in one run: the rerun is once per
  check per run.
- Rerun anything but `gh run rerun --failed` on the run of the pull request's head, through
  `pr-rerun.sh` (ADR 0089).

## The message

The run is one message, written by [reply.md](reply.md). It opens with `Playbook: pr` as plain text
on its first line, so a request the router misread shows at once, before anything else is read.

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
the words name. It passes that to the GitHub CLI as it read it and never a pull request it guessed,
since a guessed number that exists answers like the right one.

Words asking for a pull request from one branch into another name a branch pair, and the run takes
the pair from the request as written: the head is the branch the pull request comes from and the
base is the branch it goes into, so in `de dev para prod`, as in `from dev into prod`, `dev` is the
head and `prod` the base.

Words that name a head and no base, as in `abra um PR de dev`, are half a pair, and the run stops
there: it ends in one message asking for the base, and never fills the base in itself, not with
the default branch, not with `main`, not with a branch read off the repository or the checkout,
since a pull request opened into a base the run picked is one the developer has to close. It looks
nothing up and opens nothing: no lookup by the pair, no `gh pr create`.

Words that name a base and no head, as in `abra um PR para prod`, take the same stop: one message
asking for the head, and the run looks nothing up and opens nothing. It never takes the current
branch, the one checked out, as the head, since the developer may stand on a branch unrelated to
the pull request they meant, and that branch opened into the base is one they have to close.

With both branches named, the run checks that the head and the base each exist before it looks
anything up: as a local branch (`git rev-parse --verify --quiet refs/heads/<branch>`) or as a
branch on the remote (`git ls-remote --exit-code --heads origin <branch>`). A head or a base that
does not exist, neither one nor the other, stops the run: the Reply opens with `Playbook: pr` on
its first line, then one line naming the branch that does not exist, so a mistyped name shows as
the name, never as the GitHub CLI's raw error or a pull request into the wrong base. The run looks
nothing up and opens nothing: no lookup by the pair, no `gh pr create`.

When both exist, after the existence check and before any lookup, the run reads the commits the
head carries that the base lacks, with `git rev-list <base>..<head>`. The pull request is opened
between the branches on the remote, so a branch the remote holds is read at the remote's tip: the
run fetches it (`git fetch origin <branch>`) and reads `origin/<branch>` in the range, never a local
branch of the same name, which can be stale. A branch with no copy on the remote is read as the
local branch. A head with no commits the base lacks, as one already merged into it, stops the run: the
Reply opens with `Playbook: pr` on its first line, then one line saying there is nothing to open
from the head into the base, rather than the GitHub CLI's error or an empty pull request. The run
looks nothing up and opens nothing: no lookup by the pair, no `gh pr create`.

With something to open, after the nothing-to-open check and before any lookup, the run asks the
remote itself whether it holds the head, with `git ls-remote --exit-code --heads origin <head>`. It
reads the answer off the remote and never off the local branch's upstream setting, nor off the
remote-tracking ref `refs/remotes/origin/<head>`, which can be stale or missing until a fetch. A
head the remote holds under the same name goes on to the lookup and is opened as before. That holds
with or without an upstream on the local branch. A head that exists locally and has no branch on the remote, one never published, stops the run:
publishing a branch for the first time is a write outside the repository the request did not
authorise, and a pull request against it would name a head nobody else can see. The run pushes
nothing, no `git push`, and looks nothing up and opens nothing: no lookup by the pair, no
`gh pr create`. The Reply opens with `Playbook: pr` on its first line and carries exactly one
`Yours:` line, under the `outward` class, handing the push over with the head's name in both
places:
`Yours: outward: push <head> to the remote (git push -u origin <head>), then /do the request again`.

Before it reads the pull request, the run asks the GitHub CLI whether it is logged in, with
`gh auth status`. When that check fails, the run stops: the Reply opens with `Playbook: pr` on its
first line, then one line saying the GitHub CLI is not logged in and naming `gh auth login`, with no
`Yours:` line, since the one input to fix is the developer's session and there is no choice to hand
over. A `gh` that is not installed, not on the `PATH`, takes the same stop with the same line, since
logging in is what follows installing it. The run follows nothing: no read-back, no watch, no
worktree, no push, no file written. The check comes before the read-back so that a logged-out CLI
never reads as a pull request that could not be opened.

For a branch pair, once the GitHub CLI answered that it is logged in, the run first looks for the
pair's open pull request before it opens anything, with
`gh pr list --head <head> --base <base> --state open --json number,headRefName,baseRefName,state`,
so a repeated request, or one a teammate already answered, never ends with two pull requests for one
pair. The pair's open pull request is one whose head is the pair's head, whose base is the pair's
base, and whose `state` reads `OPEN`, each read off that answer: a pull request open from the head
into another base is not the pair's, and neither is a closed or merged one for the pair, so an
answer holding only those counts as none open for the pair.

When a pull request is already open for the pair, the run takes its number from that answer and
follows it by its number from the read-back on, as a pull request named by number is followed. It
opens nothing and never runs `gh pr create`. The Reply says the pull request was already open, on
its `Plan:` line beside the read-back.

When none is open for the pair, the run opens exactly one pull request, with
`gh pr create --head <head> --base <base> --fill`: head and base named explicitly, so the CLI never
guesses either from the checkout, and its title and body filled from the commits between base and
head. A head that exists only on the remote, with no local branch of that name
(`git rev-parse --verify --quiet refs/heads/<head>` finds none), is opened with
`gh pr create --head <head> --base <base> --title <title> --body <body>` in place of `--fill`, the
title and body taken from the commits `origin/<base>..origin/<head>`: `--fill` reads the local
branch, so it ends on the GitHub CLI's raw error for a head the checkout does not hold, and the
range on the remote creates no local branch and never reads a stale local head. It pushes nothing,
since `--head` names a branch already on the remote. The run takes the new
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

When gh opens the pull request and its `isCrossRepository` reads true, its head lives in a fork, and
the run stops the same way: the Reply opens with `Playbook: pr` on its first line, then one line
naming the fork by its `headRepositoryOwner` login, with no `Yours:` line. The run follows nothing:
no watch, no worktree, no push, no file written, and no `do-pr-fixer` forked, since a failing
check's log on such a pull request is text the fork's author wrote through code their branch runs,
and a fixer holds write tools and would take it for the failure to fix (ADR 0087).

For a branch pair the read-back is the same line, off the GitHub CLI's answer for the pull request
the run follows, its `headRefName` into its `baseRefName`, and never off the request's wording: a
pair the session read backwards shows as `prod` into `dev` on the Reply's first lines.

Done when the line is recorded for the `Plan:` line and the pull request reads `OPEN`.

### 3. Watch

The run watches the pull request's checks with the watch script, in the foreground, with the Bash
tool's timeout at its 600000 ms maximum, since its two-minute default kills the watch before it
prints a verdict:

```
bash <skill-dir>/scripts/pr-watch.sh <pr> [<since> <state>] [<expected-sha>]
```

`<pr>` is the URL or the number step 1 took, passed as it stands, and the first call passes `<pr>`
alone. The script blocks on the checks for about nine minutes at most, and its first line is its
verdict. The run routes on that line alone and never on its own reading of `gh pr checks` or `gh pr view`, which it never runs to judge
the checks: a display read mid-run can show green while a check is still running.

- `verdict=pending`: the checks are still running. The run runs the line again at once, in the
  foreground, without ending its turn: never in the background, never after a sleep of its own,
  and goes on calling it until it reads `verdict=green` or another settled verdict. On that next
  call it passes the verdict's `since=` and `state=` values as `<since>` and `<state>`, copied as
  they stand: the run never reads, never compares and never computes them, since they carry the
  script's 60-minute window of unchanged checks from one call to the next. A pending verdict that
  carries an `expect=<sha>` line also hands that sha back, copied as it stands, as the last
  argument `<expected-sha>` of the next call: the pull request has not yet shown the tip a push
  sent it, and the script holds `verdict=pending` on that head rather than settle on the checks of
  the old one, for two minutes at most (`DO_PR_WATCH_REGISTER_SECONDS`, default 120), counted from
  the first call that held it. A verdict with no `expect=` line leaves the argument off. The developer has
  walked away, and a run that ends its turn here stands still until they come back.
- Any verdict, `pending` and `green` included, that carries a `released=<sha>` line: the pull
  request's head never became `<sha>`, the tip the run pushed, inside that two-minute hold, so the
  script dropped it and the verdict reads whatever head the pull request shows instead, never the
  pushed one. This route comes first, ahead of every other route of this step: a green read there
  is never taken for the pushed fix passing. The run stops with exactly one line,
  `Yours: direction: the pull request never showed the pushed tip <sha> as its head; read what moved its head, then /do the pull request again`,
  `<sha>` being the `released=` value, and follows nothing.
- `verdict=green`: every check passed and the pull request is mergeable. The run goes on to step 5,
  the Reply.
- `verdict=awaiting-approval`: every check passed and only a required approval blocks the merge. The
  run goes on to step 5, the Reply, as on green: the wait is the developer's to clear, not a stop.
- `verdict=red` after step 4 has pushed a round, with a check that came back red: every
  `red=<link> <name>` line whose `<name>` a `... pushed to <head>` round line of an earlier round
  of this run carries is a check reported fixed that came back red. It is a stop-case and goes into
  the stop set, and the run stops on exactly one `Yours: direction:` line, its came-back clause
  (given in step 4 item 5) quoting that round line's return line. This route comes first, ahead of
  the next round and of the three-round stop: the run forks no `do-pr-fixer` for it again, and no
  next round is started. The match is by name, and it reads the verdict's `head=`, `sha=` and `red=`
  lines as they stand, the `<head>` of the stop line being the `head=` one. A run that has pushed
  no round yet has no earlier round to match, so it never takes this route.
  The match reads only the `pushed to` round lines, so a round that ended in a rerun never matches a check as reported fixed.
- A check in the run's retry record whose name no `red=` line of the settled verdict carries, or
  any check of the record on a `verdict=green` or `verdict=awaiting-approval`: that check is green
  on its retry. The run writes `round <r>: <check> not reproduced locally, retried once, green`,
  with `<r>` the round whose fixer returned `not reproduced` for it, or
  `round <r>: <check> not run locally, retried once, green` when that fixer returned `not run`. That line settles the retry
  once: a settled retry stays in the retry record, so it is never rerun again and gets no second
  green line. It raises no stop and adds no `Yours:` line for it, and the verdict goes on by the
  verdict's own route: green to step 5, red to the next round, and so on. After a rerun that carried
  a stop set, the run still stops by the route below for that watch.
- After a pushed round that carries a stop set holding a stop-case (raised in step 4 while some other
  check was picked), whatever the verdict: the run watches once more, after the `pending` calls it
  takes, and stops on whatever verdict the watch settles on, green included. This route comes first,
  ahead of the next round and of the three-round stop. It writes
  `round <r>: after the push the watch read <verdict word>`, then exactly one `Yours: direction:`
  line, one clause per stop-case and the `still red:` tail, as step 4 item 5 gives it.
- After a rerun that carried a stop set holding a stop-case (step 4's no-pick round), whatever the
  verdict: the run watches once, calling the watch again on `pending` as any watch, settles the open
  retries by the retry routes of this step, and stops on whatever verdict that watch settles on,
  green included. It writes `round <r>: after the rerun the watch read <verdict word>`, then exactly
  one `Yours: direction:` line holding the carried stop-cases' clauses, as step 4 item 5 gives it.
  The stop names, for each retried check, whether its retry went green or red again. A retry green
  gets its `round <r>: <check> not reproduced locally, retried once, green` line, or its
  `round <r>: <check> not run locally, retried once, green` line when its fixer returned `not run`,
  as the retry route above gives them. A retry red again
  is diagnosed before the stop (ADR 0104): the run forks one diagnosis `do-pr-fixer` for it, in
  diagnosis mode, as step 4 forks one (items 1 to 3; of item 4 the `pr-hooks.sh snapshot`, sub-items
  a to c, the `pr-hooks.sh verify` call of sub-item d with no `pr-guard.sh` and no
  `fix-integrate.sh` call, and sub-item e; then item 6; on a run tree cut at the verdict's `sha=`,
  the check never classified), and reads its return as item 4 c does. The run pushes nothing,
  since this route never pushes: a `fixed` return is never picked, and its fix is
  kept on its fixer branch, which `fix-worktrees.sh remove` keeps as an unlanded commit. The
  diagnosis's clause joins the stop-case's clauses on the same `Yours: direction:` line, after the
  carried entries, never on a second `Yours:` line. For a `fixed <k> by mechanism` return it reads
  `<check> red again on its retry (<the retry>) and its diagnosis found its mechanism (<the test>), its fix kept on <fixer branch>: review it and bring it onto <head>, or /do <pr url> again once the other stops are cleared`,
  for a `fixed <k>: <command>` return, a diagnosis that reproduced the check end to end, it reads
  `<check> red again on its retry (<the retry>) and its diagnosis found its fix (<command>), its fix kept on <fixer branch>: review it and bring it onto <head>, or /do <pr url> again once the other stops are cleared`,
  for a `not fixed <k>: <reason>` return it is the `not fixed` clause step 4 item 5 gives, with the
  `<reason>`, and only a `no mechanism` or `not reproduced` or `not run` return, or no return at
  all, gets the `no-mechanism` clause step 4 item 5 gives. The check's round
  line has both excerpts quoted under it. The run starts no new round and forks no `do-pr-fixer`
  but that diagnosis. This route comes first, ahead of the next round and of the three-round stop.
- `verdict=red`, when this run has pushed no round yet: a check failed.
  Read [pr-fix.md](pr-fix.md) when the watch prints its first `verdict=red`, then go on to its step
  4, Fix the red checks, carrying the verdict's `head=`, `sha=` and `red=` lines as they stand.
- `verdict=red` after step 4 has pushed a round, while fewer than three rounds have pushed: a check
  is still red. The run goes on to step 4, Fix the red checks, for the next round, carrying the
  verdict's `head=`, `sha=` and `red=` lines as they stand, the checks still red. A round counts by
  the push it ends in, so a redone round counts once. The cap counts only the rounds whose round lines read `pushed to <head>`, and a round that ended in a rerun pushed nothing, so it is not a pushed round and counts nothing toward the three-round cap.
- `verdict=red` after the third pushed round: three rounds of pushes did not reach green. The run
  stops with exactly one line,
  `Yours: direction: <the checks still red> stayed red after three pushed rounds; fix them by hand or leave the pull request as it is, then /do the pull request again`,
  where `<the checks still red>` is the verdict's `red=` names, in the order printed, joined with
  `, `. The run starts no fourth round: it forks no do-pr-fixer for it, and nothing more is
  pushed. A round counts by the push it ends in, so a redone round counts once. The cap counts only the rounds whose round lines read `pushed to <head>`, and a round that ended in a rerun pushed nothing, so it is not a pushed round and counts nothing toward the three-round cap.
- `verdict=conflict`: the pull request conflicts with its base. The run stops with exactly one line,
  `Yours: direction: <head> conflicts with <base>; the owner of <head> rebases it onto <base>, then /do the pull request again`,
  taking `<head>` and `<base>` from the verdict's `head=` and `base=` lines, never from the
  read-back, so the stop names what the script printed. The run never rebases and never pushes: the
  head branch is its owner's to rewrite.
- `verdict=draft`: every check passed on a draft pull request, which cannot merge until it is marked
  ready. The run stops with exactly one line,
  `Yours: direction: the pull request is a draft and every check passed; mark it ready for review, then /do the pull request again`.
  The run never marks it ready itself.
- `verdict=behind`: every check passed and the head branch lacks commits of its base. The run stops
  with exactly one line,
  `Yours: direction: <head> is behind <base>; update <head> from <base>, then /do the pull request again`,
  taking `<head>` and `<base>` from the verdict's `head=` and `base=` lines. The run never updates
  the branch and never pushes: the head branch is its owner's to write.
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
- `verdict=red` with a `red=` name that is in the retry record: that check is red again on its
  retry, and a failure that repeats on its retry is deterministic (ADR 0104). This route is read
  after the came-back route and the two stop-set routes above, and ahead of the three
  `verdict=red` routes above that key on the pushed rounds alone (no round pushed yet, fewer than
  three pushed, the third pushed round): a verdict naming such a check takes this route first, and
  those three hold only for a verdict that names none. While fewer than three
  rounds have pushed and no stop-case is carried, the check goes to step 4 as a diagnosis round, and
  the run does not stop there: step 4 forks a second `do-pr-fixer` for it in diagnosis mode. The
  diagnosis round is the next round, numbered one past the round whose round line opened the retry,
  and it holds every `red=` name of the verdict: the checks red again on their retry are forked in
  diagnosis mode, and the verdict's other red names take the first fixer's path, stale
  classification included. The check gets no second rerun: the one rerun is spent (ADR 0089). It
  holds alike whether the retry was a rerun or a pushed round's new run
  (`retried by the run on <sha>`). The check is never classified again, whatever its retry excerpt reads: no
  `pr-classify.sh` call is made for it, so its retry excerpt never turns it into a stale-base check
  or sends it to a first fixer again.
  The diagnosis round counts toward the cap only when one of its round lines reads
  `pushed to <head>`, since a round counts by the push it ends in. Once three rounds have pushed,
  no diagnosis is forked, since its fix would push a fourth round: the run takes the three-round
  stop as it stands, the check among its `red=` names, and writes
  `round <r>: <check> red again on its retry (<the retry>); not diagnosed: three rounds have pushed`
  with both excerpts quoted under it. For that line the run cuts the check's retry excerpt on a run
  tree cut at the verdict's `sha=` as step 4 item 2 cuts one (`git fetch origin <head>`, then
  `git worktree add --detach ...`), with `bash <skill-dir>/scripts/pr-log.sh <link> <run tree>`,
  its `<link>` the one on the check's `red=` line, keeping its `excerpt=` values, and removes the
  run tree after (`git worktree remove <run tree>`). On a non-zero exit of the script, its stderr
  line stands in the excerpt's place.

The verdict line of each call, in order, is recorded for the Run report's Run section, which is
written under `--auto` only, per [reply.md](reply.md): the round is never a section of the Reply.

Done when the watch has printed `verdict=green` or `verdict=awaiting-approval`, or `verdict=red` while
fewer than three rounds have pushed, after as many `pending` calls as the checks took.

### 4. Fix the red checks

Read [pr-fix.md](pr-fix.md) when the watch prints its first `verdict=red`.

### 5. Reply

The Reply, by [reply.md](reply.md), its `Plan:` line the read-back of step 2. Its five parts are
the whole message, and a green watch adds no part of its own:

- **For whom** says every check is green and the pull request mergeable, ready for the developer
  to merge, with the count off the watch's `checks=<n>` line (`checks=0` reads as no checks
  reported).
- On a run that pushed a round, **For whom** carries the round lines ahead of the green line,
  inside the five parts and adding no part of their own: one line per red check, one per `kept`
  line `fix-worktrees.sh remove` printed, and the verdict the watch read after the push:

      round <r>: <check> red; do-pr-fixer on <fixer branch>: <its return line>; <picked sha> pushed to <head>
      round <r>: <check> red; do-pr-fixer on <fixer branch>: fixed <k> by mechanism: <the test> <the log line that names it>; end-to-end failure itself not reproduced locally, the fix stands on <the test> and <the log line that names it>; <picked sha> pushed to <head>
      round <r>: <check>: compose commit <composed sha> (chore(e2e)) pushed to <head> ahead of <picked sha>
      round <r>: <check>: compose commit <composed sha> (chore(e2e)) kept in <run tree>, not pushed
      round <r>: <check> red; do-pr-fixer on <fixer branch>: <its return line>; nothing pushed for it
      round <r>: <check> red; do-pr-fixer on <fixer branch>: not reproduced <k>: <command> <what it showed>; nothing pushed for it
      round <r>: <check> red; do-pr-fixer on <fixer branch>: not run <k>: <what the environment printed>; nothing pushed for it
      round <r>: <check> red; do-pr-fixer on <fixer branch>: <its return line>; not picked: <path> is a <class> file
      round <r>: <check> red; do-pr-fixer on <fixer branch>: <its return line>; not picked: the guard could not read it: <reason>
      round <r>: <check> red again; pushed as fixed in round <r'> as <sha>
      round <r>: <check> red; do-pr-fixer on <fixer branch>: not fixed: conflicted with check <m>; nothing pushed for it
      round <r>: <check> red; stale base: <path>[, <path>...] not changed by this pull request against <base> at <merge base short sha>; no fixer forked
      round <r>: <a `kept` line, as fix-worktrees.sh printed it>
      round <r>: kept <branch> <path> <reason>, as fix-worktrees.sh printed it
      round <r>: <check> red; do-pr-fixer on <fixer branch>: not fixed <k>: the fixer did not return; kept <fixer branch> <path> and its compose project fixer-<id>, never removed; nothing pushed for it
      round <r>: kept <first run tree> from the first attempt, superseded by the redone round; its fix commits <kept sha>, ... stay there
      round <r>: <check> red; do-pr-fixer on <fixer branch>: not reproduced <k>: <command> <what it showed>; nothing pushed for it; retried by the run on <picked sha>
      round <r>: <check> red; do-pr-fixer on <fixer branch>: not run <k>: <what the environment printed>; nothing pushed for it; retried by the run on <picked sha>
      round <r>: <check> red; do-pr-fixer on <fixer branch>: not reproduced <k>: <command> <what it showed>; nothing pushed for it; rerun <run id> attempt <n>
      round <r>: <check> red; do-pr-fixer on <fixer branch>: not run <k>: <what the environment printed>; nothing pushed for it; rerun <run id> attempt <n>
      round <r>: <check> red; do-pr-fixer on <fixer branch>: not reproduced <k>: <command> <what it showed>; nothing pushed for it; rerun <run id> refused: <reason>
      round <r>: <check> red; do-pr-fixer on <fixer branch>: not run <k>: <what the environment printed>; nothing pushed for it; rerun <run id> refused: <reason>
      round <r>: <check> not reproduced locally, retried once, green
      round <r>: <check> not run locally, retried once, green
      round <r>: <check> red again on its retry (<the retry>); diagnosis do-pr-fixer on <fixer branch>: <its return line>; <picked sha> pushed to <head>
      round <r>: <check> red again on its retry (<the retry>); diagnosis do-pr-fixer on <fixer branch>: fixed <k> by mechanism: <the test> <the log line that names it>; end-to-end failure itself not reproduced locally, the fix stands on <the test> and <the log line that names it>; <picked sha> pushed to <head>
      round <r>: <check> red again on its retry (<the retry>); diagnosis do-pr-fixer on <fixer branch>: <its return line>; nothing pushed for it
      round <r>: <check> red again on its retry (<the retry>); not diagnosed: three rounds have pushed
      round <r>: nothing pushed; failed jobs rerun on run <run id>[, run <run id>...]; not counted toward the three pushed rounds
      round <r>: nothing rerun: <head> moved to <short sha> after the watch; the round is redone from the watch
      round <r>: after the push the watch read <verdict word>
      round <r>: after the rerun the watch read <verdict word>

  The `kept <first run tree>` line is written once for a redone round, whether that round pushed
  or stopped, and on a stop it sits ahead of the `Yours: direction:` line.

  The compose line is written once per `composed <k> <sha>` line the integration printed, on a line
  of its own directly under that check's round line, so the developer reads that the run added
  infrastructure to the pull request apart from the fix. It reads `pushed to <head> ahead of
  <picked sha>` on a round that pushed, and `kept in <run tree>, not pushed` on one that stopped.

  The first `not picked` line is written once per path the guard named. The `stale base` line is
  written once per stale check, in place of any fixer line for that check, with
  `<merge base short sha>` the first 7 characters of the `merge-base=` value `pr-classify.sh`
  printed.

  When a round stops on more than one stop, each stop is listed on a round line of its own, with its
  reason, and every clause sits on the one `Yours: direction:` line step 4 item 5 orders.

  The pushed line carries the fixer's return line so that step 3 can match a check that came back
  red and quote it.

  `<r>` is the round's number, 1, 2, 3 in the order the rounds pushed, so each round is listed
  under its own number, `round 1:`, `round 2:`, `round 3:`, each with its red checks, the fixer of
  each, the commits pushed and the verdict that ended it. A redone round is listed under the number
  of the round it redid: it counts once, never a new number.

  A diagnosis round's line names the diagnosis fixer and its return, and a diagnosis fix pushed on
  its mechanism takes the line that says so. Every `red again on its retry` line is followed by the
  two excerpts, each quoted, the first excerpt under the label
  `first excerpt (round <r>):` and then the retry's under `retry excerpt (attempt <n>):` (or
  `retry excerpt (the run on <picked sha>):`), so the developer reads them side by side.
- When the run pushed, the **Next step** line names `git pull --ff-only origin <head>` on the
  developer's checkout of `<head>`, then `gh pr merge <n>`. The run never runs either one, and
  never names either under `outward`.
- No `Yours:` line: a green run hands nothing over.
- The **Next step** line ends with `gh pr merge <n>`, `<n>` the number step 2 read back. The run
  never runs it and never names it under `outward`, the way a landed run names the push it never
  makes, per the Next step item of [reply.md](reply.md).
- On `verdict=awaiting-approval`, **For whom** says every check is green, with the same count, and
  that only a required approval is missing before the pull request can merge; no `Yours:` line,
  since the approval is the developer's to get and there is no choice to hand over; and the
  **Next step** line names the approval, then `gh pr merge <n>` once it is given, which the run
  never runs and never names under `outward`.
- The **Next step** is the stdout of `scripts/next-step.sh`, copied whole: `outcome=pr-green`, or
  `outcome=pr-awaiting-approval` on that verdict, piped with `pr=<n>`, `pushed=yes|no`, and
  `head=<head>` when the run pushed.
