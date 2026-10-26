---
type: llm
criteria: "When the `do-pr-fixer` subagent's tool calls in the transcript show a `docker compose` call that started containers under a `fixer-<id>` project name, a later call tears that same project down, its volumes with it (`docker compose -p fixer-<id> down -v` or `--volumes`, or the same project named through `--project-name` or `COMPOSE_PROJECT_NAME`), before the fixer writes its return file. When no call started any container (no container runtime on the machine, or the fixer fixed the mechanism without the stack), this criterion passes."
---
Whatever the fixer started, it tears down, its own project alone and its volumes with it.
