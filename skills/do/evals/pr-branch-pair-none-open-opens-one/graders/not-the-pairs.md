---
type: llm
criteria: "The run took neither pull request #3 (open from `dev` into `main`) nor pull request #5 (closed, from `dev` into `prod`) for the pair's open pull request: it never said either was already open, never watched either (no `pr checks 3` or `pr checks 5` call), and its Reply follows the pull request it opened, #9."
---
A pull request into another base, or a closed one for the pair, is not the pair's open pull request.
