# Eval cases

Prepared for `claude plugin eval` (`<case>/case.yaml` + `prompt.md` + `graders/*.md`, the layout its
`--help` describes). The command is gated server-side per organization (early access), so the cases
have been authored, not executed; the `case.yaml` keys and grader types beyond `tool_used` follow
the runner's help text and may need adjusting once it runs.

`tickets` is user-invoked, so every prompt types the skill; there is no trigger case. Every fixture
is small, so nearly every ticket the run cuts is in the small band: a fixture that must not fold
makes every neighbour of a single-edge ticket wait on a second blocker, so the fold would delay it,
and a fixture that must split carries a path long enough to be judged large. No fixture but the
calibration one holds a resolved ticket, so every other breakdown estimates on the defaults and says
so. A run ends either at a
stop, or at the approval message, the only message that asks the user anything, since no user is
there to say the breakdown goes out. Both are the moments the cases inspect: nothing is published in
either.

Every fixture is synthetic: a small notes module, a local-markdown tracker file, a spec in the
format `spec` writes with its `Journey:` verdict under the title and, where the case needs one, a
journey in the sections `tickets` reads. The idempotency case also plants one published ticket, in
the local shape of the ticket format `tickets` links.

| case | checks |
|---|---|
| `journey-paths-become-slices` | with a journey, the breakdown has one ticket per path, names the path, draws the blocking edges from `## States` with what each ticket reads and who writes it, states every estimate and band, folds nothing, and lists the cut story as left out; the one question is approval and nothing is published before it |
| `small-folds-into-neighbour` | two one-step paths on a single edge fold into one ticket that names both paths, with the fold rule stated; nothing is asked but approval |
| `calibrates-from-resolved-tickets` | a resolved ticket of an earlier feature carries a `Context:` line, so the breakdown states the fixed load and the per-criterion cost read from it and every estimate is calibrated, not on the defaults |
| `large-splits-along-steps` | one long path across every module is split along its steps into several demoable tickets, none in the large band, later pieces blocked by earlier ones; the split rule is stated. This case leans on the run's own estimate: a fixture the run judges medium needs more weight, not a looser grader |
| `not-needed-cuts-from-stories` | a verdict of `not needed` is cut from the User Stories, and the run says so in one line |
| `verdict-required-stops` | a verdict of `required` with no journey ends the run with one message naming `/journey`; nothing is written |
| `journey-pointer-missing-stops` | a verdict naming a missing file ends the run with one message naming the location; nothing is written |
| `reopen-stops` | a journey with a branch under `## Reopen in discuss` ends the run with one message naming the branch and `/discuss`; nothing is written |
| `existing-tickets-stop` | tickets already under `issues/` beside the spec end the run with one message listing them; nothing is written or renumbered |
| `spec-required` | no argument: one message asking for the spec, nothing cut from the conversation, nothing written |
| `dated-slug` | a bare slug goes through the resolver to its dated feature folder, `20260901-archive-notes`, and the breakdown is cut from that spec, never from the newer `20260905-bulk-archive-notes` a tail match would have taken; the one question is approval |

Run from the skill directory, granting the tools the cases need and opting in to their scaffold
scripts:

```
claude plugin eval . --scaffold --allow-tools Bash Read Edit Write Agent
```
