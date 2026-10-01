---
name: sketch
description: "Settle the shape a piece of work has to hold before any logic and file it: the caller's usage, the types, the signatures and the module boundaries with unimplemented bodies, plus each rival shape it rejected in one line, shaped by an agent that writes nothing and filed in the Scratch by this session, never implemented."
disable-model-invocation: true
argument-hint: "[what to shape, and the feature slug to file it under]"
---

# Sketch

Settle the shape of the work the developer typed and file it as one Sketch in the project's
Scratch. The work is split in two on purpose. The `sketch` agent explores the shape in a window of
its own and returns the Sketch's text; it writes nothing, since it may read text a stranger wrote.
This session resolves where the Sketch goes, checks that place, and writes the file, per
[scratch.md](../../.agents/scratch.md). It shapes nothing itself and implements nothing: when the
agent cannot be forked or returns no Sketch, the command ends with one line saying why, and no
file is written.

The developer's argument sits at the end of this file, between the `<arguments>` tags: what to
shape, and the feature slug to file the Sketch under when the developer passed one. Empty: one
message asking what to shape, and nothing else.

`<skill-dir>` below is the directory this file sits in. Steps 1 to 5 run in order, and each stop
they name ends the command there.

## 1. Where it goes

The slug is the one the developer passed. With none, derive one from the argument: the words that
name the work, lowercased, joined with dashes. Resolve it with the shared script and never by
reading the folder, since the rule about which folder a slug names lives there and nowhere else.
Test for the script first, then run it:

```sh
test -f <skill-dir>/../../.agents/scripts/resolve-feature-folder.sh
bash <skill-dir>/../../.agents/scripts/resolve-feature-folder.sh <slug>
```

It prints `slug=`, `root=`, `folder=` and `spec=`, and creates nothing. The script's exit decides,
never an empty stdout, since a refusal and a missing file both leave stdout empty:

| What came back | What this session does |
|---|---|
| exit 0 | the Sketch goes to `<root>/<folder>/sketch.md` when `folder=` is relative, as it is from anywhere in the main checkout, to `<folder>/sketch.md` when it is absolute, as it is from a linked worktree, or to `<root>/.scratch/sketches/<slug>.md` when `folder=none` |
| any other exit, and `test -f` finds the script | stop: nothing is written, and the one line is the script's own stderr line |
| `test -f` does not find the script | not a stop: the root is the first entry of `git worktree list --porcelain`, the slug is lowercased with every character that is not a letter or a digit turned into a dash and the dashes squeezed and trimmed, the Sketch goes to `<root>/.scratch/sketches/<slug>.md`, and the end owes the line that the resolver was absent |

On exit 0, `<slug>`, `<root>` and `<folder>` are the `slug=`, `root=` and `folder=` the script
printed, never the word the developer typed, so the destination is always an absolute path.

## 2. The check before anything else

The destination goes through one check before the agent is forked, so a refused place costs no
exploration:

```sh
dest="$(readlink -m <the destination>)"
case "$dest" in "<root>/.scratch/"*) echo inside ;; *) echo refused ;; esac
```

`refused` ends the command: nothing is written, and one line names the path that was refused.
`readlink -m` collapses the `..` and follows the symlinks in the destination, so a path that only
looks contained is caught here. The other side stays the unresolved `<root>/.scratch/`, so a
`.scratch` that is itself a symlink sends the destination outside the prefix and is refused on
every row of step 1, including the one without the resolver.

## 3. The shape

Call the Agent tool with `subagent_type: sketch`. Its prompt is the brief the agent's definition
fixes, one labelled part per line, and the agent sees nothing of this session but that brief:

| Part of the brief | What this session puts there |
|---|---|
| what to shape | the argument, in the developer's own words |
| the map | `none`, unless the argument names one |
| the Digest | `none`, unless the argument names one |
| the repository root | the `<root>` of step 1 |
| where the Sketch goes | the destination of step 1, which the agent puts on the header's `Written:` line |
| the chain's `.agents/` folder | the absolute path `readlink -f <skill-dir>/../../.agents` prints, since the agent holds no shell to follow the install link itself |

The agent returns the Sketch's text, then the shape on a line starting `Shape:`, then a `No map:`
line when the brief carried none. What comes back decides:

| What came back | What this session does |
|---|---|
| the Agent tool lists no `sketch` | stop: nothing is written, and one line names `scripts/link-skills.sh` in the skills repository as the run that links it |
| a return that does not carry the sections of the [Sketch format](../../.agents/formats/sketch-format.md) | stop: it is not a Sketch, nothing is written, and one line says so |
| a return that carries them | step 4 |

## 4. The ignore, then the write

Whether the project's own committed file carries the scratch ignore is read in the main checkout:

```sh
( cd <root> && git check-ignore -v .scratch/ )
```

A first field of `.gitignore` owes nothing. Anything else, the clone's exclude list, a global
excludes file or no output at all, owes the line, appended before the write:

```sh
( cd <root> && if [ -L .gitignore ]; then echo '.scratch/ is not ignored: .gitignore is a symlink, so nothing was appended'; else grep -qxF '.scratch/' .gitignore 2>/dev/null || { [ -z "$(tail -c1 .gitignore 2>/dev/null)" ] || echo; printf '.scratch/\n'; } >> .gitignore; fi )
```

Then write the Sketch whole at the destination: the agent's text from the Sketch's title line to
the last line of its rejected rivals, as returned, with nothing added and nothing reworded. The
`Shape:` and `No map:` lines that follow it belong to step 5 and stay out of the file. A Sketch
already there is replaced whole.

## 5. The end

The final message is one line that holds the Sketch's location and the shape together, so the
developer learns both without opening the file. One more line only when it is owed: the
`.scratch/` line appended, no map, or no resolver. Nothing else in the tree changes.

<arguments>
$ARGUMENTS
</arguments>
