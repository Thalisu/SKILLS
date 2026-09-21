# One `choice-taker` rules for every chain skill

The agent `do` forks on a Design fork (ADR 0036) is generalized into the one agent every chain skill
forks under `--auto`, rather than a second agent beside it. Its brief takes a common shape (the
caller, the question, two or more options, the skill's recommendation when it has one, and where the
context lives) and it keeps its two returns, `settled` and `extreme`, so the Extreme-fork test and
the norm rule ADR 0036 settled have a single home. The skill's recommendation is one of the options
to weigh, never a norm, the way a Ticket criterion never is: a picker that followed it would rule
what the session already held, and cost a fork for nothing.

## Considered options

- A second agent for `discuss`, `spec`, `journey` and `tickets`, the `choice-taker` left to `do`:
  two copies of the same test and rule, free to diverge until one kind of question is ruled two
  ways.
- Following the recommendation unless a norm contradicts it: `--auto` becomes "take every
  recommendation", which the session does without an agent.
