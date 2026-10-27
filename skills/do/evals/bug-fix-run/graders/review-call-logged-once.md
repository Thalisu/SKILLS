---
type: file_contains
path: .git/do-code-review-calls.log
pattern: '^do/\S+\s+[0-9a-f]{7,40}\s+main\s+.*command=.*Review token:\s*\S+'
---
The stand-in logged a review call carrying the branch, the fixed point, `main`, the Gate's `command=` line and the review token, in that order.
