# Eval cases

Prepared for `claude plugin eval` (`<case>/case.yaml` + `prompt.md` + `graders/*.md`, the layout its
`--help` describes). The command is gated server-side per organization (early access), so the cases
have been authored, not executed; the `case.yaml` keys and grader types beyond `tool_used` follow
the runner's help text and may need adjusting once it runs.

`discuss` is user-invoked, so every prompt types the skill; there is no trigger case. Each run
without `--auto` ends when the skill asks its first question, since no user is there to answer it,
which is exactly the moment those cases inspect. A run under `--auto` asks nothing but an
`extreme` return, a return that is no ruling, or a branch the `choice-taker` cannot be forked to
rule, so most of its cases inspect the close; the branch any of those exceptions touches is a question like any other, and its case
inspects that question instead.

| case | checks |
|---|---|
| `one-question` | the first message that asks something carries exactly one question, a recommendation and the tell |
| `explores-first` | a branch the fixture's code settles is closed with `file:line`, never asked; the grounding note names the contradiction |
| `no-writes-without-decision` | with no decision taken, nothing is created or edited in the project and nothing is committed |
| `runnable-branch` | a branch about what a screen should look like is marked runnable and forks the `prototype` agent with a complete brief, instead of asking for a layout in words; every other branch stays a question |
| `auto-rules-every-branch` | under `--auto`, typed after the plan, every branch the repository cannot close is forked to the `choice-taker` and the run reaches the close without a question to the user |
| `extreme-branch-asks-the-developer` | under `--auto`, a branch whose `choice-taker` fork returns `extreme` writes no row and is put to the developer as one question, carrying the weaker side and the guarantee it gives up |
| `auto-contradiction-ruled` | under `--auto`, a contradiction between the plan and the code opens a branch the `choice-taker` rules, and the close lists it with the side ruled and its norm, never as the side the user picked |
| `steered-choice-taker-asks-the-developer` | under `--auto`, a `choice-taker` stand-in that returns `settled` on a side the brief never handed over is no ruling: the branch is put to the developer as one question naming the reason, the stand-in is forked once, and the side reaches no row, `Rulings` line or ADR |
| `unshaped-choice-taker-return-asks-the-developer` | under `--auto`, a `choice-taker` stand-in that returns a refusal, neither `settled` nor `extreme`, is no ruling: the branch is put to the developer as one question naming the reason, the stand-in is forked once, and no row or option the session picked stands in for the ruling |
| `choice-taker-unreachable-asks-the-developer` | under `--auto`, with the Agent tool listing no `choice-taker`, the branch it cannot rule is put to the developer as one question naming the reason, with no other agent forked in its place and no row read as ruled |

A `PROTOTYPE ask` answered by resuming the agent has no case either: the ask reaches the user only
after the brief was sent, so the run has already ended at that question.

Run from the skill directory, granting the tools the cases need and opting in to their scaffold
scripts:

```
claude plugin eval . --scaffold --allow-tools Bash Read Edit Write Agent
```
