---
type: file_contains
path: ".git/billing-service-suite.log"
pattern: '^billing-service suite ran in /'
---
`npm test` is the Gate command of `billing-service` alone, and it leaves a line under the
repository's `.git` on every run. The other two repositories run `node --test`, and so does the
stand-in review, none of which writes that line: it is there only when the run checked this
repository under this project's own rules.
