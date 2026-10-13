---
type: file_contains
path: ".git/claims-at-review.log"
pattern: '^held at the review: spec\.billing-service\.integration\.claim$'
---
The release deletes the claim before the run ends, so the fixture's stand-in review logs every
claim file it finds beside the Spec when it is called: the Final integration was held under the
key of `billing-service` while the Spec branch was reviewed and landed.
