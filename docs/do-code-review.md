# do-code-review

## What it does

`do-code-review` reviews the diff of the branch you are on since a fixed point and writes one file,
the **Review**, with everything it found. It forks its own orchestrator, which forks a technical
reviewer that puts five **Axes** to the diff (correctness, spec fidelity, repo standards, this
repo's principles, blast radius), proves what it can by running the code from a temporary
directory, and returns **Findings**; the orchestrator groups them by **Bucket** and writes the
Review in the scratch reviews folder, named after the branch. The sixth Axis, security, has its
own reviewer and ships separately; until then its line reads `not run`.

Every Finding carries a **Rung**, how far the review climbed to back it, and nothing at Rung 1 or
2 reaches `Act on`, whatever it looks like: a claim the review could not walk or run stays a
judgment call in `Consider`, so nothing is fixed on a hunch. The reviewer never edits code: it has
no write and no edit tool, its shell is for reading and running, and the orchestrator compares
`git status` before and after it, so a path it changed would be named in the Review. The
orchestrator's one write is the Review.

## When to reach for it

Type `/do-code-review`, with a ref or without, or the agent reaches for it automatically when a
task fits: a request to review this branch, to review since a ref, to check the diff before a
push, in English or in Portuguese ("revisa esse diff").

| Ask | Use |
|---|---|
| review the branch I am on, against where it left the base branch | `/do-code-review` |
| review since a commit, a branch or a tag | `/do-code-review <ref>` |
| a pull request you want reviewed and posted on GitHub | the bundled `/code-review`, which this skill leaves untouched |
| the Ticket `do` just built | `/do-code-review` on its worktree's branch: [do](../skills/do/SKILL.md) does not call the review yet |

The session shows nothing while the run is in flight, as [prototype](prototype.md) does; the
Review's text lands in the thread when it is written, with its location. The prose comes back in
the language of the words you typed; with a bare ref it is English.

## Prerequisites

- **The agent links.** The skill forks the `do-code-review` agent, which forks
  `do-code-review-technical-reviewer`, so both definitions have to be linked into
  `~/.claude/agents/` beside the skill link: the `AGENT.md` beside the skill file under the
  orchestrator's name, and every markdown file in the skill's `agents/` folder under its own name;
  see [the top-level README](../README.md).
- **Somewhere to write.** The Review goes to `.scratch/reviews/<branch>.md` in the project, slashes
  in the branch name turned into dashes. The run's last line says which way the project has it: with
  `.scratch` ignored the file stays out of `git status`, without it the file shows up there for you
  to keep or drop.
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
| Security | the attacker's seat, read by a second reviewer that ships separately; `not run` until then |

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

## What the run leaves behind

The Review, and nothing else. Proof scripts run in a temporary directory outside every
repository; nothing is installed, committed or pushed. The report's section names and labels are
fixed and in English, so a caller reads the Buckets off it by name.

## Common questions

**Why not `code-review`?**
Because a user skill named `code-review` would replace the bundled `/code-review` on every machine
that installs this repo. The `do-` prefix keeps both: this skill for a branch on the machine,
judged against the spec the chain wrote and this repo's principles, with each Finding proven to a
Rung; the bundled one for a pull request you want posted on GitHub.

**The Security line says `not run`. Did something fail?**
No. Security is a sixth Axis with its own reviewer, which ships separately; until it does, the
line says so rather than `0 findings`, so a review that never asked the question is never read as
a pass on it.

## It's working if

- The run ends with the Review's text, one `Written to` line and one line saying whether `.scratch`
  is ignored by git, or with one refusal line and no file.
- Nothing under `## Act on` reads `Rung: 1` or `Rung: 2`, and every `Act on` Finding names a
  behaviour to prove and where.
- `## Axes` has six lines every time, and a `not run` or `no spec` line stands where a reviewer or
  a spec was missing.
- `git status` after a run agrees with that last line: the Review and nothing else when `.scratch`
  is not ignored, nothing new when it is.

## Where it fits

`do-code-review` is a reach-for-it-anytime standalone: you type it on any branch, at any point in
the work, as often as you like. It is also the review [do](../skills/do/SKILL.md) is built around,
and that step is not wired yet: `do` stops after its gate, its review step reads
`skip: do-code-review not listed`, and its reply names the review and the landing as what you run
next. So a Ticket `do` just built is reviewed by typing the skill on the worktree's branch it left
behind.

- [discuss](discuss.md), [spec](spec.md) and [tickets](tickets.md), because the spec and the
  Ticket they produce are what the Spec Axis reads.
- The principles under [`.agents/principles/`](../.agents/principles/README.md), because the
  Principles Axis turns them into lenses with a tell.

The grouped list of every skill is in [the top-level README](../README.md).
