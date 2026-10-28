# The Extreme stop of a refactoring run

It is read by [refactoring-design-fork.md](refactoring-design-fork.md) when step 4 or step 6 of
[refactoring.md](refactoring.md) meets a Design fork with a side read as Extreme, when the
`choice-taker` returns `extreme` on that fork, and when the fork goes unruled, the unruled stop that
borrows this stop's message.

The session never overrules either reading: a fork it read as ordinary that the `choice-taker`
returned `extreme` on stops, under `--auto` as without it. The stop is a blocked run, written by
the blocked shape of [reply.md](reply.md), nothing landed, and its blocker lines name the step, both
sides, the guarantee the weaker side would lose with its risk class (or what could not be undone
once landed), the worktree and its branch left in place, and the commits made so far, one line
each, or `none`. The choice between the sides is handed over:
`Yours: direction: choose <side A> or <side B> through the /discuss below, then type the request again to resume in <worktree>`.

There is no Ticket and no Spec, so the reply's last line is a `/discuss` command that names
neither, whole, with nothing after it:

```
/discuss the do refactoring run on "<the reshape read back>" stopped at the <step> step on an Extreme fork, <side A> or <side B>; <the weaker side> would give up <the guarantee> (<the risk class>). Which side does the reshape take?
```

That line is the stdout of `scripts/next-step.sh` on `outcome=extreme-fork`, piped with
`playbook=refactoring`, `subject=` (the reshape read back), `step=`, `side_a=`, `side_b=`, `weaker=`, and
`guarantee=` with `risk_class=`, or `undone=` for a side that cannot be undone once landed.
Copy it whole; never fill the template yourself.

A side that cannot be undone once landed reads `<the weaker side> cannot be undone once landed:
<what could not be undone>` in place of the clause after the semicolon. No sidecar is written: the
next `/do` on the same request is a resume of the branch, which meets the fork again at its step.
