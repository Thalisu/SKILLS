# A shared read-only script resolves a slug to its feature folder

`.agents/scripts/resolve-feature-folder.sh` takes a bare slug and prints the feature folder under
`.scratch/` it names and the spec in it. It only reads: it never creates a folder and never touches
a project's `.gitignore`. It is the one executable form of the rule, and everything that resolves a
slug calls it: `skills/spec/scripts/feature-folder.sh` for its reuse lookup, `journey` and
`tickets` instead of restating the rule in their prose, and `do-code-review`'s door for the
`.scratch/` arm of `spec=`. Before this the rule sat in prose in three places and in bash in two,
and the divergence had already shipped a bug: the door answered with the oldest folder of a slug
where the allocator reuses the newest.

The script lives outside `skills/` because the rule is the shared contract's, not one skill's.
`CLAUDE.md` forbids a skill reaching into another skill's folder, and `.agents/` is already where
what more than one skill reads lives (`formats/`, `principles/`), next to the `.agents/scratch.md`
that carries this contract. Every skill is installed by symlinking its own directory, so a caller
reaches the script at `<skill-dir>/../../.agents/scripts/`, which resolves through the symlink
because the repo is cloned whole, the same hop the skills' prose links already take. Read-only is
the point of the split: the review door writes nothing into a project but its Review, so the script
it calls has to be one that cannot write.

The rule it encodes is exact. A slug names the folder called `<slug>` or `<YYYYMMDD>-<slug>` and no
other, the newest of them when a slug carries more than one, and an undated folder from before the
dated rule over every dated one, never renamed. The earlier wording, "ending in `-<slug>`", also
matched `20260909-nightly-purge` for the slug `purge`, which the allocator never did: under it
`/journey purge` opens a neighbouring feature's spec while `spec purge` allocates a folder of its
own, so the two doors answer differently for one slug. The price is that a human who types half a
slug gets a stop instead of a guess, and `spec` prints the slug it allocated at its close.

It resolves in the main checkout, the allocator's root logic moved into it, so a slug names one
folder from whichever tree the caller stands in. A linked worktree holds no scratch of its own, so
from there the paths come back absolute, the way `review=` and `main_checkout=` already do.

What it is not: the door's Ticket lookup. A Ticket is named after its own slug and sits in the
feature folder of the spec it was cut from, so `.scratch/*/issues/<NN>-<core>.md` has to search
every folder, and a slug-to-folder lookup fed a ticket slug would find nothing. The door's
containing scan, which matches a branch name against a folder that contains it, is not this rule
either. Only the exact `.scratch/` arm of `spec=` moves.

## Considered options

- A `--resolve` mode on the allocator, moved to `.agents/scripts/` whole. One file and one root
  logic, and the review door would be calling the script that appends to a project's `.gitignore`,
  with a flag as the only thing keeping the run read-only.
- The resolver kept in `skills/spec/scripts/`, called by the other three by path. The smallest
  diff, and it makes `spec` the owner of a door two other skills depend on, which `CLAUDE.md` rules
  out.
- One copy per skill. The divergence this change removes, reintroduced with four chances to drift
  instead of two.
- The root `scripts/` folder. It is documented as dev-only tooling for maintainers of this repo, so
  a door the installed skills run on a user's project would be filed with the things no installed
  skill runs.
- Resolving in the tree the caller stands in, with a `--root` the door passes as its own top.
  Today's answers preserved to the letter, and a run in a linked worktree keeps finding no spec at
  all, which is the hole `review=` already had to work around.

## Consequences

This amends [ADR 0030](0030-the-feature-folder-is-dated-and-a-script-allocates-it.md), which said
the allocator is called by `spec` and by nobody else. It still is: what is shared is the lookup
inside it, not the allocation. `.agents/scratch.md` names the resolver as the one implementation
and stops spelling the rule out, `journey` and `tickets` call it instead of restating it, and the
door keeps both of its own rules.

The door's `spec=` can now come back as an absolute path from a linked worktree, and can name a
spec where today it answers `none`. Its consumer already reads that key as a path, so nothing
downstream changes shape.

A caller that cannot find the script degrades in one line: `journey` and `tickets` ask for the
spec's path, the stop they already have for an argument that reads as nothing, and the door answers
`spec=none`. The script is there whenever the repo is cloned whole, which is how every skill here
is installed.

The resolver owns the slug normalisation and the refusal on a `.scratch` that is not a plain
directory of the checkout, so the allocator inherits both and one test suite covers them once.
