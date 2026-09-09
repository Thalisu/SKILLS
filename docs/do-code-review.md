# do-code-review

## What it does

`do-code-review` reviews the diff of the branch you are on since a fixed point and writes one file,
the **Review**, with everything it found. It forks its own orchestrator, which forks two reviewers
in parallel with the same brief: a technical reviewer that puts five **Axes** to the diff
(correctness, spec fidelity, repo standards, this repo's principles, blast radius), and a security
reviewer that puts the sixth to it from the attacker's seat, mapping the attack surface before it
opens any checklist. Both prove what they can by running the code from a temporary directory and
return **Findings**; the orchestrator groups them by **Bucket** and writes the Review where its
Ticket is, beside the Ticket file when a caller hands one over and in the scratch reviews folder
named after the branch when nobody does.

Then it fixes what it found. When the Review carries an `Act on` Finding, the orchestrator forks
the **Fixer** with that list, one commit per Finding under the project's Testing Policy, re-runs
each Finding's own check and the project's suite itself, appends a `## Fix run` section to the same
Review, and fast-forwards your branch onto the fixed one when the Review is **Green**. Nothing is
pushed: the run ends with the `git push` command for you to type.

Every Finding carries a **Rung**, how far the review climbed to back it, and nothing at Rung 1 or
2 reaches `Act on`, whatever it looks like: a claim the review could not walk or run stays a
judgment call in `Consider`, so nothing is fixed on a hunch. A Security Finding is the one that
never lands in `Noted`: it is `Act on`, `Consider` or `Cleared`, so nothing on that Axis is set
aside without you seeing it. Neither reviewer edits code: neither has a write or an edit tool,
their shell is for reading and running, and the orchestrator compares `git status` before and after
them, so a path one of them changed would be named in the Review. The orchestrator's one write is
the Review.

A reviewer that does not return, or returns in a shape the Review cannot take, is forked once more
with the same brief. When it fails a second time the Review is still written, from what the other
reviewer returned: its Axis lines read `not run` with the reason, and the safety fact names the
Axis nobody answered. A partial review reaches you instead of nothing, and a pass never hides a
reviewer that never ran.

## When to reach for it

Type `/do-code-review`, with a ref or without, or the agent reaches for it automatically when a
task fits: a request to review this branch, to review since a ref, to check the diff before a
push, in English or in Portuguese ("revisa esse diff").

| Ask | Use |
|---|---|
| review the branch I am on, against where it left the base branch | `/do-code-review` |
| review since a commit, a branch or a tag | `/do-code-review <ref>` |
| a pull request you want reviewed and posted on GitHub | the bundled `/code-review`, which this skill leaves untouched |
| the Ticket `do` just built | `/do-code-review <the Ticket's path>` on its worktree's branch, which puts the Review beside the Ticket |
| read the Review before any agent touches the branch | `/do-code-review --no-fix`, which writes the file and stops |
| fix a Review you have edited by hand | `/do-code-review fix <the Review's path>` |

The session shows nothing while the run is in flight, as [prototype](prototype.md) does; the
Review's text lands in the thread when it is written, with its location. The prose comes back in
the language of the words you typed; with a bare ref it is English.

## Prerequisites

- **The agent links.** The skill forks the `do-code-review` agent, which forks
  `do-code-review-technical-reviewer` and `do-code-review-security-reviewer`, so all three
  definitions have to be linked into `~/.claude/agents/` beside the skill link: the `AGENT.md`
  beside the skill file under the orchestrator's name, and every markdown file in the skill's
  `agents/` folder under its own name; see [the top-level README](../README.md). A reviewer whose
  link is missing is forked twice and then reported `not run` on its Axis.
- **Somewhere to write.** Hand a Ticket's location over and the Review goes beside the Ticket
  file, taking its name with `.review` before the extension: `02-export-notes.review.md` beside
  `02-export-notes.md`. Otherwise it goes to `.scratch/reviews/<branch>.md` in the repository's
  main checkout, slashes in the branch name turned into dashes: a run inside a linked worktree
  still writes there, since the worktree has no scratch folder of its own and is removed with
  everything in it. The run's last line says whether that file shows up in `git status`: a Review
  beside a Ticket the project tracks does, one written under an ignored `.scratch` does not.
- **A base branch or a ref.** Without a ref, the fixed point is the merge-base with the remote's
  HEAD branch, else `main`, else `master`; a repository with none of those needs a ref.

## Six Axes, four Buckets, one Rung

An **Axis** is one question put to the diff, reported apart from the others so a pass on one never
hides a fail on another. The Review ends with one line per Axis, all six, with the count and the
worst Finding.

| Axis | Cites |
|---|---|
| Correctness | a bug with its failure scenario: the input, the state, the wrong output |
| Spec | a requirement missing or partial, quoting the spec line; `no spec` in one line when the branch has none |
| Standards | the file and the rule the project documents, or one of twelve smells as a labelled judgment call; anything a linter enforces is skipped |
| Principles | a principle of this repo whose tell the diff shows, named only beside a Finding at a location |
| Blast radius | breakage outside the diff: callers, wire shapes, timing, flags; `unproven` when a check could not run |
| Security | the attack surface, then STRIDE and an OWASP cross-check on web surfaces, every Finding at a location with its exploit path (the input, the missing or present gate, the sink) and a risk class |

A **Finding** lands in one **Bucket**: `Act on` (fix before landing), `Consider` (a judgment call,
yours), `Noted` (an observation), `Cleared` (suspected, then refuted, shown with what refuted it
so you can overrule). The **Rung** decides which of the first two a Finding can reach:

| Rung | The review |
|---|---|
| 1 | said so |
| 2 | pointed at `file:line` |
| 3 | walked the failure |
| 4 | ran it |
| 5 | reproduced it in the app |

`Act on` takes only Rung 3 or above, with the fix named as a behaviour to prove and its target.
The spec the run judges against is found, never asked for: an issue through the project's tracker
file, else a spec file matching the branch in the usual spec homes, else `no spec`.

## The fix, and the hand-off

The Review on disk is the hand-off. Open it, and the `## Act on` section is the list the Fixer
works from: delete a Finding you overrule, move a `Consider` you want fixed up into `Act on`, and
the file is what the run reads next. With a clean tree, type `/do-code-review fix` with its path
and the run does the same fixing, proving and landing the default run does, from the list as you
left it. It touches nothing in `Consider`, `Noted` or `Cleared`, so the judgment calls stay yours.

A `fix` call stops in one line, before anything is written, when the Review is not there, when its
fixed point no longer resolves, or when your working tree has uncommitted changes. The tree has to
be clean because the Review judged a diff, and a Fixer let loose on a tree nobody reviewed would
commit work nobody read. An `Act on` location you changed since the review comes back `stale`, left
alone.

## What the run leaves behind

The Review, the Fixer's commits on the branch it reviewed, and your branch fast-forwarded onto
them. Nothing is pushed, on any path, and the last line of the run is the `git push` you type
yourself. Proof scripts run in a temporary directory outside every repository, and nothing is
installed. The report's section names and labels are fixed and in English, so a caller reads the
Buckets off it by name.

## Common questions

**Why not `code-review`?**
Because a user skill named `code-review` would replace the bundled `/code-review` on every machine
that installs this repo. The `do-` prefix keeps both: this skill for a branch on the machine,
judged against the spec the chain wrote and this repo's principles, with each Finding proven to a
Rung; the bundled one for a pull request you want posted on GitHub.

**Why does the review fix and land, and not `do`?**
Because one fixer for every caller is cheaper than one per caller. A Review that stopped at the
document cost a human read, or a second full review, before a branch with an `Act on` Finding
could land. The Fixer touches only `Act on`, which is Rung 3 or above with its check named, works
in a worktree, and lands by fast-forward with nothing pushed, so the blast radius of letting it
write is bounded. `/do-code-review --no-fix` is there for when you want to read first.

**Why is security its own agent?**
Because a security pass reads the same diff with a different question and a different knowledge
base, and one agent holding both postures does neither well. The technical reviewer reads the diff
as code; the security reviewer reads it as surface, and asks who can reach each entry point before
it asks anything else. That split is also why the two never negotiate: a Finding both make at the
same location is the security reviewer's, and the technical one is dropped, so you never read the
same defect twice under two Axes.

**The Security line says `not run`. Did something fail?**
Its reviewer did, twice: it never returned, or returned in a shape the Review could not take, and
the second fork went the same way. The rest of the Review is real and was written from the other
reviewer's return. The line says `not run` with the reason rather than `0 findings`, so a question
nobody asked is never read as a pass, and the safety fact names the Axis too.

**The run says the session is isolated in a worktree. What happened?**
The worktree was entered with the harness's worktree tool instead of a bare `cd`, which puts the
session under an isolation guard, and this skill's door is a script the guard refuses to run. So
nothing was reviewed and nothing was written, and the landing, git against the main checkout, would
have been refused next. Leave the isolation with the harness's exit tool and `keep`, never
`remove`, which takes the branch and the commits on it, then `cd` back into the same worktree and
call the review again. `/do` denies that tool in its own skill file, so its runs meet it as a
refusal instead of as a rule to remember, per
[ADR 0022](adr/0022-the-worktree-tool-is-denied-in-the-skill-file-and-the-contract-carries-the-recovery.md).

## It's working if

- The run ends with the Review's text, one `Written to` line and one line saying whether that file
  shows up in `git status`, or with one refusal line and no file.
- Nothing under `## Act on` reads `Rung: 1` or `Rung: 2`, and every `Act on` Finding names a
  behaviour to prove and where.
- `## Axes` has six lines every time, and a `not run` or `no spec` line stands where a reviewer or
  a spec was missing.
- Nothing under `## Noted` carries the Security Axis, and every Security Finding names an exploit
  path and a risk class rather than a checklist item.
- `git status` after a run agrees with that last line:
  the Review and nothing else when git does not ignore the file, nothing new when it does.
- A Review that fixed anything carries a `## Fix run` section naming each Finding by number, the
  suite, and either `landed at <sha>` or `not landed` with its reason and the branch left behind.
- `git log` on your branch shows the Fixer's commits after a landing, and `git status` shows
  nothing to push that you did not push yourself.

## Where it fits

`do-code-review` is a reach-for-it-anytime standalone: you type it on any branch, at any point in
the work, as often as you like. [do](../skills/do/SKILL.md) is its second caller and the only
other one: at its review step it hands over the Ticket it built together with the branch's fixed
point, so the Review lands beside that Ticket and names it in its header. `do` reads the outcome
off the return and never opens the file, and it never fixes a Finding itself. On a machine where
the skill is not installed, `do` says so, lands nothing and names the review as your next step.

- [discuss](discuss.md), [spec](spec.md) and [tickets](tickets.md), because the spec and the
  Ticket they produce are what the Spec Axis reads.
- The principles under [`.agents/principles/`](../.agents/principles/README.md), because the
  Principles Axis turns them into lenses with a tell.

The grouped list of every skill is in [the top-level README](../README.md).
