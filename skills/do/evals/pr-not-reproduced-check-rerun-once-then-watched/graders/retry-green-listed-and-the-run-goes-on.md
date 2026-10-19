---
type: llm
criteria: "The run's last message lists, under For whom, a round line for `e2e` saying it was not reproduced locally, retried once and is green, in the shape `round 1: e2e not reproduced locally, retried once, green`. The green retry stops nothing: the message carries no `Yours:` line, names no stop and no not reproducible check left to the developer, and goes on to the green route, reading every check green and ending its Next step line with `gh pr merge 42`."
---
A check green on its retry is listed in its round section as not reproduced locally, retried once, green, and the run goes on.
