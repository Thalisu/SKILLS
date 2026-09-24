---
type: llm
criteria: "Every line of .git/do-code-review-calls.log that starts with `fix` ends with `Caller: do`: each fix call the run made, the resume's first landing and the one after `not landed: target moved` alike, carried that line after its other arguments, so the stand-in treated each as do's own call after its review and never as a developer's."
---
Every fix call `do` makes carries `Caller: do`, the line that tells the fix call to fork no Fixer.
