# Handoff: `do` lands by pull request instead of fast-forward

A `discuss` session in progress, paused by the developer. The next agent resumes the interview at
the first open branch below, under the `discuss` skill's rules (one question per message, ADRs
only at the close), and never re-asks a decided branch.

## The plan

The `do` landing stops fast-forwarding the reviewed branch into the developer's branch. Once the
review's fixes and the gates are green, a pull request is opened from the reviewed branch into the
developer's branch instead. The next step after the pull request opens is `/do <PR>`.

## Grounding

- Today the Final integration (`skills/do/references/mechanics.md`, section "The final
  integration") claims the Spec, rebases `spec/<slug>` onto `spec_upstream` in its own worktree,
  runs the Post-feature gate and flows, then calls `do-code-review`, which fixes the `Act on`
  Findings and, on a Green Review, fast-forwards the landing target itself through
  `skills/do-code-review/scripts/land.sh` (ADRs 0013, 0015, 0043, 0061).
- The release (`final-claim.sh release`) removes the Spec branch only when its tip is on its
  upstream.
- `skills/do/scripts/landing-order.sh` reads a repository as `landed` when its Spec branch is gone
  or its tip is on its upstream; it orders a provider before its consumer (ADR 0084).
- A push is the `outward` Handover class (ADR 0057); the `pr` Playbook is the only one that pushes,
  and only to its pull request's head (ADR 0086). `skills/do/references/pr.md` already runs
  `gh pr create --head <head> --base <base>` when no pull request is open for a pair.
- Playbooks that land on the developer's branch today: `bug-fix` and `refactoring` (review with the
  run's starting branch as landing target), a Ticket with no Spec (review), the Final integration.
  `trivial` commits directly on the developer's branch with no worktree and no review. A Ticket of
  a Spec lands on `spec/<slug>` through `land-spec.sh`, no review.

## Tree

1. **[decided] Scope.** The pull request replaces the fast-forward in every run that reviews a
   branch and fast-forwards it into the developer's branch: `bug-fix`, `refactoring`, a Ticket
   with no Spec, and the Final integration. `trivial` keeps committing directly; a Ticket of a Spec
   keeps its fast-forward onto the Spec branch; `integrate` and `pr` are unchanged. Beat: one pull
   request per Ticket into the Spec branch (each Ticket would wait on a human merge before the
   next could build on it).
2. **[decided] No fallback.** Without a GitHub remote or a logged-in `gh`, the run stops after the
   review's fixes and the gate are green, the reviewed branch intact, and its Reply hands over a
   `Yours: outward` line carrying `git push -u origin <branch>` and
   `gh pr create --head <branch> --base <developer's branch>`. The fast-forward path leaves the
   landing whole (`land.sh` and the ADR 0043 lock with it). Beat: falling back to the fast-forward,
   which makes the same `/do` land two ways on machine state the Reply never shows.
3. **[decided] The run pushes.** When the remote and `gh` are ready, the run pushes only the branch
   it reviewed (`do/<slug>` or `spec/<slug>`), `git push -u origin <branch>`, never `--force`, and
   opens only that pull request: a second authorised exception to the `outward` class, beside ADR
   0086. The developer's branch is never pushed. Beat: a `Yours: outward` stop before every push,
   which makes every run a handover.
4. **[decided] `do-code-review` opens the pull request.** It keeps owning the landing (ADRs 0005,
   0013): `land.sh` becomes the script that pushes and runs `gh pr create`, and the return line
   reads `proposed <url>` in place of `landed at <sha>`, for every caller, a developer calling
   `/do-code-review` with a landing target included. `do` only learns to read the new line. Beat:
   the review returning `ready at <sha>` and `do` opening the pull request, which splits the landing
   across two owners and adds an intermediate state the resume and `not-landed.md` would read.
5. **[decided] Landed means opened.** A Spec is landed, and done, once its Landing pull request is
   open and mergeable without conflict; merging it is the developer's, outside the chain. Across
   repositories the order of ADR 0084 becomes a merge order: the consumer's Reply carries one line
   `merge <provider PR url> before <this PR url>`, and the consumer's pull request body links the
   provider's. Beat: reading `MERGED` off `gh pr view`, and a consumer waiting for its provider's
   pull request to be merged, which stalls the feature on a human click.
6. **[decided] Release on open.** Once the pull request is open, the run removes the worktree,
   deletes the local branch (it lives on the remote as the pull request's head) and releases the
   claim. `landing-order.sh` keeps reading "Spec branch gone" as landed, with no new record. The
   release deletes the branch only after the push confirmed the remote holds the same tip, which
   replaces "tip on upstream" as the proof. The URL rides the Reply and the Review. Beat: keeping
   the local branch and a record file holding the URL, a second record of "landed" ADR 0084 already
   ruled out.
7. **[decided] The run ends on the URL.** It does not follow the pull request's checks; the Reply's
   next step is `/do <PR>`.
8. **[open] What the integration rebases onto.** Today it rebases onto the developer's local
   branch, but the pull request's base is `origin/<branch>`. A local branch ahead of the remote puts
   the developer's unpublished commits in the pull request; a remote ahead of the local branch can
   open it conflicting. Recommendation put to the developer, not yet answered: `git fetch` and
   rebase onto `origin/<branch>`, the review's fixed point being that merge base, so the Review
   reviews exactly the diff the pull request shows and it opens mergeable by construction; the
   developer's local branch is never touched; after `gh pr create` the run reads
   `gh pr view --json mergeable`, and `CONFLICTING` stops the run as blocked with the pull request
   left open. Tell: the pull request showing a diff other than the one the Review reviewed.
   Lenses: boundary-discipline, prove-it-works.
9. **[default] Title and body.** The title is the Spec's title (the branch's intent outside the
   chain); the body carries the Review's summary and its path. Cheap to change.
10. **[default] Developer's branch not on the remote.** The run stops with `Yours: outward` naming
    the push, as `pr.md` does for an unpublished head.
11. **[default] The target moving after the pull request opened.** It is the pull request's
    concern (a conflict on GitHub, then `/do <PR>`); no local re-integration. Today's
    `not landed: target moved` loop (ADR 0044) still covers a target that moved before the push.

Branches still to walk after 8, which the developer has not seen yet:

- Idempotency of the push and the create on a resume: a run stopped between the push and
  `gh pr create`, or after the create and before the release, must find the open pull request for
  the pair and reuse it, as `pr.md` already does, never open a second one
  (make-operations-idempotent).
- Which ADRs this supersedes or amends: 0013, 0015, 0043 (the lock may die with the fast-forward),
  0044, 0057, 0060, 0061, 0084, 0086 (migrate-callers-then-delete-legacy-apis).
- The Jira status a Spec takes when its pull request opens (ADR 0100: `resolved` is not Done).
- The first verifiable unit and its check (sequence-verifiable-units): likely the review's new
  `proposed <url>` return against a fixture remote, before any Playbook reads it.

## Written so far

`CONTEXT.md`, uncommitted:

- New term **Landing pull request**.
- **Spec branch** and **Final integration** reworded: proposed back by the Landing pull request,
  the local branch deleted once it opens, the Spec landed and done once it is open and mergeable.
- The relationship line on `do-code-review` landing now reads that it opens the Landing pull
  request when the Review is Green.

No ADR is written yet: they are written at the close, from the decided branches above, under
`.agents/formats/adr-format.md`. Decisions 2 to 6 are the likely candidates.

## Next step

Resume with `/discuss` on this file, starting at branch 8, then the branches still to walk, then
the close (ADRs, then the summary for `spec`).
