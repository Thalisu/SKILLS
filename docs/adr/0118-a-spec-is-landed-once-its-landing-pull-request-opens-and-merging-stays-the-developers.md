# A Spec is landed once its Landing pull request opens, and merging stays the developer's

The chain ends at an open, mergeable **Landing pull request**: merging it is the developer's, outside
the chain, so no run waits on a human click. Once the pull request is open the run removes the
worktree, deletes the local **Spec branch**, which lives on the remote as the pull request's head,
and releases the claim, and the release deletes the branch only after the push confirmed the remote
holds the same tip. `landing-order.sh` keeps reading a **Spec branch** gone from the local refs as
landed, so no record file holds the URL, which rides the **Reply** and the **Review**. Across
repositories the order of ADR 0084 becomes a merge order: the consumer's **Reply** carries
`merge <provider PR url> before <this PR url>` and its pull request body links the provider's. The
run ends on the URL, and its next step is `/do <PR>`.

This amends ADR 0084.

## Considered options

- Reading `MERGED` off `gh pr view` as landed, with a consumer waiting for its provider's merge:
  the feature stalls on a human click.
- Keeping the local branch and a record file holding the URL: a second record of "landed", which
  ADR 0084 rules out.
