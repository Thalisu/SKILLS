---
name: sketch
description: "Settle the shape a piece of work has to hold before any logic and file it: the caller's usage, the types, the signatures and the module boundaries with unimplemented bodies, plus each rival shape it rejected in one line, shaped by an agent that writes nothing and filed in the Scratch by this session, never implemented."
disable-model-invocation: true
argument-hint: "[what to shape, and the feature slug to file it under]"
---

# Sketch

The arguments below are what to shape, and the feature slug to file the Sketch under when the
developer passed one. The `sketch` agent explores the shape in a window of its own and returns the
Sketch's text; it writes nothing. This session resolves where the Sketch goes, checks that place,
and writes the file, per [scratch.md](../../.agents/scratch.md).

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
| exit 0 | the Sketch goes to `<root>/<folder>/sketch.md` when `folder=` is relative, as it is from anywhere in the main checkout, to `<folder>/sketch.md` when it is absolute, as it is from a linked worktree, or to `<root>/.scratch/sketches/<slug>.md` when `folder=none`, with `<slug>`, `<root>` and `<folder>` the `slug=`, `root=` and `folder=` it printed, never the word the developer typed, so the destination is always absolute |
| any other exit, and `test -f` finds the script | stop: nothing is written, and the one line is the script's own stderr line |
| `test -f` does not find the script | not a stop: the root is the first entry of `git worktree list --porcelain`, the slug is lowercased with every character that is not a letter or a digit turned into a dash and the dashes squeezed and trimmed, the Sketch goes to `<root>/.scratch/sketches/<slug>.md`, and the end owes the line that the resolver was absent |

## 2. The check before anything else

The destination goes through one check before the agent is forked, so a refused place costs no
exploration:

```sh
dest="$(readlink -m <the destination>)"; scratch="$(readlink -m <root>/.scratch)"
case "$dest" in "$scratch"/*) echo inside ;; *) echo refused ;; esac
```

`refused` ends the command: nothing is written, and one line names the path that was refused.
`readlink -m` collapses the `..` and follows the symlinks, so a path that only looks contained is
caught here.

## 3. The shape

Call the Agent tool with `subagent_type: sketch` and the brief its definition fixes: what to shape,
the argument; the map, `none` unless the argument names one; the Digest, `none` unless the argument
names one; the repository root, the `<root>` above; where the Sketch goes, the destination
above, which the agent puts on the header's `Written:` line; and the chain's `.agents/` folder,
the absolute path `readlink -f <skill-dir>/../../.agents` prints, since the agent holds no shell to
follow the install link itself. It returns the Sketch's text and the
shape in one line. A return that does not carry the sections of the
[Sketch format](../../.agents/formats/sketch-format.md) is not a Sketch: nothing is written, and
one line says so. When the Agent tool lists no `sketch`, nothing is written either, and one line
names `scripts/link-skills.sh` in the skills repository as the run that links it.

## 4. The ignore, then the write

Whether the project's own committed file carries the scratch ignore is read in the main checkout:

```sh
( cd <root> && git check-ignore -v .scratch/ )
```

A first field of `.gitignore` owes nothing. Anything else, the clone's exclude list, a global
excludes file or no output at all, owes the line, appended before the write:

```sh
( cd <root> && { grep -qxF '.scratch/' .gitignore 2>/dev/null || { [ -z "$(tail -c1 .gitignore 2>/dev/null)" ] || echo; printf '.scratch/\n'; } >> .gitignore; } )
```

Then write the Sketch whole at the destination, the text the agent returned and nothing added. A
Sketch already there is replaced whole.

## 5. The end

End with the Sketch's location and the shape in one line. One more line only when it is owed: the
`.scratch/` line appended, no map, or no resolver. Nothing else in the tree changes.

$ARGUMENTS
