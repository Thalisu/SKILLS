# Writing docs pages

Every skill under `skills/` has a human-facing **docs page** at `docs/<skill-name>.md`. The docs
tree mirrors `skills/`: one page per skill, flat, named after the skill. The page is not the skill
and not a copy of `SKILL.md`. It is read on GitHub, inside this repo; nothing publishes it anywhere
else.

The top-level `README.md` carries one entry per skill: the name and one line, grouped by invocation.
Everything a person needs beyond that line (the problem, what the skill does, when to reach for it,
where it fits) lives in the docs page, not in the README.

A user-invoked skill is never fired for you: _you_ are the index that has to remember it exists and
when to reach for it. That memory is **cognitive load**. The job of a docs page is to relieve it: to
orient one reader around one skill so they can hold it in their head, know when to reach for it, and
see where it sits in the set. The pages are collectively a distributed router; each is a node. A
model-invoked skill gets the same page: it still has to be recognised in a trace, and typed on
purpose when the trigger did not fire.

Act whenever a skill is added, renamed, removed, or has its behaviour changed: create, move, delete
or re-sync its page in the same change. A rename moves the file too (`docs/<old>.md` to
`docs/<new>.md`), and every link that pointed at the old name follows. A removed skill loses its
page.

Every link is **repo-relative** and must resolve from `docs/` on GitHub: a sibling page is
`<name>.md`, the skill itself is `../skills/<name>/SKILL.md`, the README is `../README.md`. Never an
absolute `github.com` URL into this repo (it breaks on a fork or a rename) and never a bare
`/skill-name` path.

The page opens with an H1 that is the skill's name (`# test-triage`) and nothing else on that line.

## Page structure

Fill the template below, keeping its order. The **fixed frame** (`## What it does`,
`## When to reach for it`, `## Where it fits`) appears on every page. `## Prerequisites` and the
free-form substance sections carry only what this particular skill needs; delete the rest.

Four sections make a page worth reading: `What it does`, `When to reach for it`,
`Common questions`, `It's working if`. The first two orient the reader; the last two are where the
page stops summarising the skill and starts answering the reader's own situation. Each of the last
two has a bar to clear, below, but treat a page that clears neither as unfinished, not as
finished-and-short.

**A page carries no install commands.** Installing is the same for every skill (clone the repo, link
the skill into the harness skill directory) and the top-level `README.md` says it once, with the
`discover-setup` variant beside it. A page that repeats it shows the reader a second copy, and the
two copies drift. Where a page has to point at installing, it links `../README.md`.

<page-template>

## What it does

One or two plain-language paragraphs. Lead with the skill's one-sentence job, then state the
**defining constraint**: the single fact that makes this skill behave differently from the obvious
default (for `test-triage`: it never changes what a test verifies, so a fix that would touch a result
assertion becomes a dossier instead; for `testing-policy`: nothing in the rendered section is
invented, every slot is filled from something that exists in the repo). Write it as a plain
declarative sentence, never a labelled aside like "The defining constraint:" or "The key thing:"; the
formula reads as filler. This line is the most valuable on the page; never omit it.

## When to reach for it

How and when you reach for the skill, in two beats that are both effectively always present:

- **Invocation mode.** State whether you type it or the agent fires it. A user-invoked skill: "You
  invoke this by typing `/<name>`, and the agent won't reach for it on its own." A model-invoked
  skill: "Type `/<name>`, or the agent reaches for it automatically when a task fits."
- **Trigger boundary.** The index entry: "reach for this when ...". Where the skill is confusable
  with a sibling or with a plain tool, add the other half: "for a single name you already have, a
  direct `rg -w` is the whole check; see [discover](discover.md) for what counts as a batch."

## Prerequisites

Optional: include only when the skill needs something in place to be functional; omit the heading
entirely otherwise. Covers: a **workspace it writes into** (`test-triage` writes `docs/tests/`;
`testing-policy` writes `.claude/agents/`, `.claude/skills/test-author/`, `.claude/testing-policy/`
and a marked section of `CLAUDE.md`, so say what it writes and where), **prior setup** (`discover`
needs `/discover-setup` to have linked the agent and installed the Discovery section), or
**tooling on the machine** (`discover` needs `rg`, `ast-grep` and `jq`). A stateless skill that runs
anywhere has no prerequisites, so drop the section.

## <free-form middle>

One to three short sections, in the skill's _own vocabulary_, that make it click. Choose whatever
headings fit the skill: the loop it runs, the artifact it produces, the fork it makes, the one
anti-pattern it kills. There is no prescribed heading; the skills are too heterogeneous for one.

The single non-negotiable: **surface the skill's leading word / defining idea** (the _batch_ and its
five states, the _dossier_ and the small-fix line, the rendered _Definition of Done_ and the
_Project map_, the _surface_ a repo has). It pays off twice: the reader learns what the skill _is_,
and learns the word they'll later think with to _reach for_ it.

## Common questions

The questions readers really ask about this skill, each in bold with the answer in the lines
beneath it. No sub-headings.

An observed question always beats an invented one, so go and find them before you write any:

- **This repo's issues.** `gh issue list --repo Thalisu/SKILLS --search "<skill-name>" --state all`.
  A question filed twice is a question the page owes an answer to.
- **The skill's history.** `git log --oneline -- skills/<skill-name>`. Anything renamed, moved, or
  behaviourally changed generates a "where did it go?" that the page has to answer. A `-v<N>` tag on
  the skill marks a version boundary worth a question.
- **Runs in real projects.** A question that came up while running the skill in a project counts,
  stated without the project's name, paths, commands or examples. The rule in `CLAUDE.md` holds
  here too: nothing project-derived comes into this repo, and a docs page is in this repo.

Where the hunt comes up thin, the section may also carry a question a reader would plainly ask, but
**the count stays honest to the evidence**. A well-used skill earns six; an obscure one earns one or
two, or none at all. Padding a thin skill out to match a rich one is how the section fills with
questions nobody has, and an invented question teaches the reader nothing.

Order them by how often each comes up, sharpest first, and say the unflattering thing where it is
true: a triage that files a dossier for everything usually means the target was too wide; a refresh
that reports disagreements on every slot usually means the Project map was hand-edited. Omit the
heading where there is nothing worth answering.

## It's working if

A few bullets naming what the reader sees when the skill is doing its job. The bar on each is that
the reader can check it without opening `SKILL.md`: a signal in their own work, or in the trace in
front of them. "The tree is clean after every triage run, green or not" passes; "the dossier
frontmatter matches `dossier-template.md`" is a compliance check on the skill's internals wearing
this section's name. Include it wherever the tells are crisp; omit the heading where they stay
vague.

## Where it fits

Always present. Situate the skill in the set in a sentence or two:

- **Role.** Name it: a **run-once setup** (`discover-setup`), an **install-then-refresh
  maintenance** step (`testing-policy`, re-run when the policy version moves), a **step another rule
  fires** (`discover`, run by the Discovery rule before any new symbol is created), or a
  **reach-for-it-anytime standalone** (`test-triage`). A standalone's map is one honest sentence,
  which is far better than omitting the section.
- **Neighbours.** The one or two siblings that matter, each with a because-clause, linked
  relatively.
- **The map.** Point to the grouped list in [the top-level README](../README.md), the index over the
  whole set, so this page stays a node and never has to redraw the graph.

</page-template>

## Conventions

- Explain the **why**, not the process. The page orients and situates the skill; it never reproduces
  the `SKILL.md` steps or template dumps: a human choosing a tool does not need the runbook.
- **Never name the author.** The page is a technical document, not a record of who said what. "The
  author says", "his position is", a quoted reply: all of it goes. A finding from the question hunt
  is worth keeping; its attribution is not. State the substance as a plain claim about the skill
  ("the fix is a direct instruction: ...", "the split comes down to the surface the repo owns") and
  drop the frame. The reader is deciding whether to use a tool; an opinion carries the same weight
  either way, and an attributed one dates as soon as the position moves. Quoting a _user_ stays
  fine: "one user reported ..." is evidence about the skill in the wild, and stays anonymous.
- **Nothing project-derived.** No page names a repository the skill has run against, private or
  public, by name, path, URL or worked example. Examples are synthetic or come from the skill's own
  fixtures under `skills/<name>/tests/` or `evals/`. This is the repo-wide rule from `CLAUDE.md`,
  restated here because a docs page is the easiest place to break it.
- Use the skill's **leading words** (_batch_, _dossier_, _Project map_, _surface_) so the page and
  the skill speak one language. Where the
  [AI Coding Dictionary](https://www.aihero.dev/ai-coding-dictionary) has a word for a concept
  (_context window_, _subagent_, _harness_), use that word rather than a synonym invented on the
  page.
- **Branches go in a table or a list, never in a paragraph.** Where the page presents a choice (three
  surfaces, five batch states, the small-fix line against the dossier), the reader is scanning for
  the one row that matches their situation. A paragraph makes them read all of it to find out. A
  short markdown table (condition in the left column, what to do in the right) or a bulleted list
  gives it back in one glance. This applies wherever the branch appears, most often in
  `## When to reach for it` and the free-form middle.
- No em-dashes, per `CLAUDE.md`. Where a sentence reaches for one, rewrite the sentence.
- Keep the page itself low-load. It is documentation _about_ low-cognitive-load skills; furniture
  (spare headings, restated links) is the thing it is arguing against.

## Done when

- The page exists at `docs/<name>.md`, and no stale page survives a rename or a removal.
- The page opens with the skill's name as its H1.
- The page writes no install command of its own.
- `## What it does` states the defining constraint, as plain prose rather than a labelled aside.
- The page names no author and quotes no author: every claim stands on its own.
- The page names no repository the skill has run against and quotes nothing taken from one.
- `## When to reach for it` states invocation mode and the trigger boundary.
- `## Where it fits` names the role and links to the top-level README.
- A prerequisite (workspace, prior setup, tooling) is stated where one exists, and the section is
  absent where none does.
- The middle surfaces the leading word.
- Every multi-way branch is a table or a list, not a paragraph the reader has to read in full.
- The hunt for real questions ran (the issues, the history, anonymised project runs), and
  `## Common questions` is sized to what it found, not padded to match a richer skill's page.
- Every `## It's working if` bullet is checkable without opening `SKILL.md`.
- The sections appear in the template's order.
- Every link is repo-relative, and every one resolves from `docs/`.
- The prose carries no em-dash.
