# The conflict class is a script's verdict, never the session's reading

Every conflicted hunk is classed by a door script under `skills/do/scripts/`: `mechanical` when
both sides only added lines, neither deleting nor modifying a line the other side kept, and
`contested` for every other shape. The run resolves the mechanical class by keeping both sides in
base order and puts every contested hunk to the human, and it never reads conflict markers to judge
for itself whether both intents survived, because "unsure" is not observable and a resolution that
quietly drops a line is close to invisible in the review that follows it. `do` and
`do-code-review`'s landing read the same script, held together the way `trivial-door.sh` holds its
copy of the protected-branch rule, by a test that fails when the two drift.

## Considered options

- The session classes by reading each hunk and asks when it feels unsure, which is what the
  `resolving-merge-conflicts` skill this borrows from prescribes ("preserve both intents where
  possible", "always resolve, never abort"): a much wider automatic class and far fewer questions,
  with no way to tell a good resolution from a lucky one, and an instruction to never abort that
  the run cannot honour when no human is reachable.

Amended: per ADR 0113, the reasons `conflict-loop.md` gave beside its rules for a stop and its
mechanical class live here. A stop the script answers with `no conflicted state, nothing classed`
is never continued unasked, since the rebase stopped with nothing unmerged and whatever is staged
for that commit carries nobody's recorded answer, and a stop on an untracked file the replay would
overwrite is never continued either, since a continue there meets the same refusal. A conflicted
path never enters a command line as text: it is a name either side of the rebase chose, and pasted
in, a single quote in it closes whatever quotes it sits in, and a `$(...)`, a backtick, a `;` or a
`|` after it runs as the run's own command. The blocks read git's list NUL-delimited, where a path
carrying a space or a newline comes back as one entry and needs no unescaping, and hand each path
to git through a shell variable, whose value is never evaluated again, or through `xargs -0`, which
starts no shell. A file the developer resolved by hand is staged first from the script's own list,
so git no longer lists it unmerged and nothing after rewrites it, and it is never handed to the
read-back, since a key the developer's own resolution defines twice is theirs. The union takes
stage 2 above stage 3 because stage 2 is the developer's branch and stage 3 the commit being
replayed, which is the base order this ADR fixes. The `--diff3` stays, since without it git trims
the lines both sides' additions share, so two functions appended at the same place keep one closing
brace between them and the file no longer parses. A union is read back for a key defined twice,
since a `mechanical` hunk says the two sides only added lines and never that the two additions mean
the same thing: a `deny` list the developer's branch just added and an empty one from the replayed
commit both land, and whatever reads the landed commit gets the empty one, a control undone with
nothing asked. That read-back is `last-wins.sh`'s and never the session's, for the reason the class
itself is a script's. Two definitions written byte for byte alike come out as one with no ledger
entry, since the reader loses nothing, and a key the base already defined twice is left as it
stands, since it is older than the union. A read-back that fails leaves the staging unrun, since
the block stages only on the read-back's success.
