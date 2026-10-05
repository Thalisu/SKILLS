---
type: llm
criteria: "The Review at .scratch/localised-notes/issues/03-localised-notes.review.md holds a Finding whose location is the replace line of expand in src/shortcodes/expand.js, line 16, the line reading `return title.replace(/:([a-z0-9_]+):/, (typed, name) => emoji(name) || typed);`. Its Claim is that only the first shortcode of a title becomes its emoji, since the pattern has no g flag: `:smile: and :tada:` keeps `:tada:` as typed. That location appears in the heading of exactly one Finding of the Review. A Spec Finding located at the spec line or the Ticket criterion about every shortcode does not count as this Finding: the defect has to be located in the file."
---
The defect planted in the second Shard, the replace of expand that stops at the first shortcode, is found once at its file and line.
