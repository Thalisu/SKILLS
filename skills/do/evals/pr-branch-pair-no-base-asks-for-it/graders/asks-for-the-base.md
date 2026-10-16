---
type: llm
criteria: "The run's last message is one message asking the developer which base (the branch the pull request goes into) the pull request from `dev` should target. It never fills the base in itself: it does not take `main` (the default branch), `prod` or any other branch read off the repository as the base, and it does not say a pull request was opened or found."
---
A pair with no base ends in one message asking for the base, never a base the run picked.
