# Eval cases

Prepared for `claude plugin eval` (`<case>/case.yaml` + `prompt.md` + `graders/*.md`, the layout its
`--help` describes). The command is gated server-side per organization (early access), so the cases
have been authored, not executed; the `case.yaml` keys and grader types beyond `tool_used` follow
the runner's help text and may need adjusting once it runs.

`tickets` is user-invoked, so every prompt types the skill; there is no trigger case. A run ends
either at a stop, or at the quiz, the first message that asks the user anything, since no user is
there to approve the breakdown. Both are the moments the cases inspect: nothing is published in
either.

Every fixture is synthetic: a small notes module, a local-markdown tracker file, a spec in the
format `spec` writes with its `Journey:` verdict under the title and, where the case needs one, a
journey in the sections `tickets` reads.

| case | checks |
|---|---|
| `journey-paths-become-slices` | with a journey, the breakdown has one ticket per path, names the path, draws the blocking edge from `## States`, and lists the cut story as left out; nothing is published before approval |
| `not-needed-cuts-from-stories` | a verdict of `not needed` is cut from the User Stories, and the run says so in one line |
| `verdict-required-stops` | a verdict of `required` with no journey ends the run with one message naming `/journey`; nothing is written |
| `journey-pointer-missing-stops` | a verdict naming a missing file ends the run with one message naming the location; nothing is written |
| `reopen-stops` | a journey with a branch under `## Reopen in discuss` ends the run with one message naming the branch and `/discuss`; nothing is written |
| `existing-tickets-stop` | tickets already under `issues/` beside the spec end the run with one message listing them; nothing is written or renumbered |
| `spec-required` | no argument: one message asking for the spec, nothing cut from the conversation, nothing written |

Run from the skill directory, granting the tools the cases need and opting in to their scaffold
scripts:

```
claude plugin eval . --scaffold --allow-tools Bash Read Edit Write Agent
```
