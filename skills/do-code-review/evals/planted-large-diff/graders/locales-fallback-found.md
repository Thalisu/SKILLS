---
type: llm
criteria: "The Review at .scratch/localised-notes/issues/03-localised-notes.review.md holds a Finding whose location is the return line of translate in src/locales/index.js, line 10, the line reading `return key in catalog ? catalog[key] : catalogs.en[locale];`. Its Claim is that a label the language's catalog lacks is not answered with the English label: the fallback reads the English catalog by the locale instead of by the key, so translate returns undefined, for example for `notes.archived` in any language but English. That location appears in the heading of exactly one Finding of the Review. A Spec Finding located at the spec line or the Ticket criterion about falling back to English does not count as this Finding: the defect has to be located in the file."
---
The defect planted in the first Shard, the English fallback of translate, is found once at its file and line.
