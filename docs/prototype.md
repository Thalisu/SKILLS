# prototype

## What it does

`prototype` builds one throwaway, runnable artifact to settle a design question that words cannot:
a single HTML file that lets you push a state model through scenarios by clicking buttons, or three
structurally different variants of a screen on its real route, flipped with a floating switcher. It
runs in its own subagent, so the build never lands in your session; what comes back is a six-line
report saying how to open the thing, what to look at, and which files it wrote.

The artifact is throwaway from the first line and never becomes production code: every file it
creates has `prototype` in its name, the only existing file it may touch is the host page, for a
two-line mount, and it commits nothing. The answer is the deliverable; the files are for you to
delete once you have it.

## When to reach for it

You invoke this by typing `/prototype`, and the agent won't reach for it on its own. The one other
door is a [discuss](discuss.md) interview: when a branch of the plan is _runnable_, discuss forks
the same agent with a brief and puts the question to you against the artifact.

| Ask | Use |
|---|---|
| what should this screen look like | `/prototype ui: <question>, on <route or page>` |
| does this state model, flow or data shape hold up once pushed through the awkward cases | `/prototype logic: <question>, beside <module>` |
| a question you can answer from a description | answer it; a prototype is the expensive path |
| settle types, signatures and module boundaries | an architect-style skill |
| a design decision inside a plan you are discussing | let [discuss](discuss.md) mark the branch runnable and fork this |

The brief carries the question, the shape (`ui` or `logic`), where it lives, what it has and
anything already decided. Whatever is missing is inferred, and every inference is named on the
report's last line. The agent cannot ask you anything, so a thin brief buys an assumption, not a
question.

## Prerequisites

- **The agent link.** The skill forks the `prototype` agent, so `skills/prototype/AGENT.md` has to
  be linked at `~/.claude/agents/prototype.md` beside the skill link; see
  [the top-level README](../README.md).
- **A workspace it writes into.** New files beside the page or module the question is about, and,
  for a `ui` prototype on an existing route, one import and one render line in the host page.
  Nothing is committed.
- **For `ui`, a project that runs.** The variants start from the project's existing dev command,
  or open as a file when the project has none; the agent adds no task-runner entry and installs
  nothing.

## Two shapes, one report

The **shape** decides everything, and getting it wrong wastes the whole prototype:

| Shape | You get | Judged by |
|---|---|---|
| `logic` | one self-contained HTML file: the state as a labelled panel, one button per action, and tabbed **scenarios** that walk the awkward cases | double-clicking it, and pressing buttons until something feels wrong |
| `ui` | three **variants** that disagree about structure, on the real route behind `?variant=`, with a switcher that also answers the arrow keys | flipping between them inside the real app, with the real header and real data around them |

Whichever shape, the last message is the **report**: `PROTOTYPE`, then `open:`, `variants:` or
`scenarios:`, `look at:`, `files:` and `assumed:`. It is short on purpose. It is what a discuss
session reads, and it is all you need to open the artifact and decide.

## Common questions

**Why can't the agent reach for it on its own?**
Because a prototype is the expensive answer. Most design questions are settled by talking, and the
skill exists for the ones that are not: a screen you have to see, a model you have to drive.
Leaving the call to you, or to discuss once a branch has proved unanswerable in words, keeps it from
becoming the default.

**What happens to the files afterwards?**
Nothing, until you decide. The report and the discuss summary list every file, each marked
throwaway in its name and its banner. Delete them, or park them on a throwaway branch as the
primary source of the decision. The validated reducer or the winning variant is rewritten properly
when it is folded into the real code; it is never promoted as is.

## It's working if

- Every new file has `prototype` in its name, and `git status` shows nothing else changed apart
  from at most two mounted lines in one host page.
- A `logic` prototype opens by double-click with nothing installed; a `ui` prototype opens from the
  project's own dev command.
- The variants disagree about layout and hierarchy, not just colour.
- The report is the whole last message, and its `assumed:` line tells you what the brief left out.

## Where it fits

`prototype` is a step another skill fires and a standalone when you type it: [discuss](discuss.md)
forks its agent for a runnable branch, and you fork it directly for a question of your own.

- [discuss](discuss.md), because it is the only skill that reaches this one, and only when a branch
  cannot be settled by talking.
- The principles [exhaust-the-design-space](../.agents/principles/exhaust-the-design-space.md) and
  [experience-first](../.agents/principles/experience-first.md), because the three variants are the
  first rule made concrete, and the second says a design decision is cheaper in throwaway HTML than
  in production code.

The grouped list of every skill is in [the top-level README](../README.md).
