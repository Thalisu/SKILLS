---
type: llm
criteria: "The run's last message is one message asking the developer which head (the branch the pull request comes from) the pull request into `prod` should come from. It never takes `spike-cache`, the branch checked out, or any other branch read off the repository as the head, and it does not say a pull request was opened or found."
---
A pair with no head ends in one message asking for the head, never the branch checked out.
