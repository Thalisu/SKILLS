# A Ticket lands on its Spec branch, and do lands it there itself

Every Ticket of one Spec now lands on a **Spec branch**, `spec/<feature-slug>`, cut from the
developer's branch by the first `do` run of that Spec and carrying that branch as its local
upstream, and each Ticket's worktree is cut from the Spec branch's tip instead of from HEAD. The
`do` run lands its own Ticket there with a fast-forward under the landing lock of ADR 0043, moved
with `git update-ref`, since the Spec branch is checked out nowhere and `land.sh` only moves the
branch the main checkout is on. This amends ADR 0013 and ADR 0033 for this one branch:
`do-code-review` stays the only lander of the developer's branch, so the reviewer is still the last
thing that reads a diff before it reaches the developer.

## Considered options

- A `land` mode in `do-code-review` with no reviewers, keeping one lander for every branch: the
  mode ADR 0033 already refused as `fix` under a second name, and one fork per Ticket spent on a
  fast-forward.

Amended: per ADR 0113, the reasons `mechanics.md` gave beside the Spec branch live here. A `ticket`
run's worktree starts from the Spec branch, so a Ticket builds on every Ticket that landed before
it, and records it with `--track`, so the close's delete measures the branch against the Spec
branch it landed on. The first run of a Spec is refused while the main checkout is on a protected
branch or on no branch, since that run would cut the Spec branch off the protected branch and record
it as the branch the whole Spec lands on. The landing is a fast-forward of the Spec branch's ref
alone, since the Spec branch is checked out nowhere. A worktree that has it checked out stops the
landing, since a ref moved under a checkout would leave that worktree's index showing the landing as
a reversal, and the run does not switch that checkout itself, since what it holds is the
developer's.

Amended: per ADR 0113, the reasons `ticket.md` and `resume.md` gave beside the claim, the worktree
and the Spec branch live here. A claim already written stands, since the claim is idempotent. A
`claimed` Ticket whose worktree exists is never refused on a protected checkout, since its run was
cut before and the protected checkout is the warning it always was, and a Ticket outside a Spec is
never refused there either, since its worktree comes from HEAD as before. The Digest and the
`.scratch/` line its write needs are the run's first marks on the developer's checkout, so a Ticket
refused before them leaves `git status` in the main checkout as it found it. The claim and the
worktree are made together once the Plan is verified, since the run then has something to build and
they are the two writes that cost the developer cleanup, and the claim goes ahead without asking,
per never-block-on-the-human, since it is a reversible file write and an interrupt costs the
developer one turn. Two first runs at once are settled by git's atomic ref creation. The run never
guesses the branch a whole Spec lands on, so a missing upstream is handed over as the developer's
fix. `--track` is spelled out because git records no upstream by default for a local start point,
and the close's `git branch -d` measures a branch against its upstream, and against the main
checkout's HEAD only when it has none: the main checkout is never on the Spec branch, so without the
upstream the delete refuses a branch that landed. A start-over whose `do/<slug>` branch survived the
worktree's removal enters it without `-b`, since `-b` on a branch that exists fails and that failure
is not one to work around with a second slug. The diagnosis worktree is cut from the checkout's HEAD
on a first run, which is the tip the cut gives the Spec branch. A Ticket whose worktree was cut from
the developer's branch before Spec branches existed keeps its review and its landing on the
developer's branch, since no Spec branch was ever cut for it and nothing migrates it, and
`resume-state.sh` prints that branch as its `base=`, the same key read in both places. The close
names a `.gitignore` the run changed, since it is a file git tracks and the developer reads that
there rather than finding it in `git status`.
