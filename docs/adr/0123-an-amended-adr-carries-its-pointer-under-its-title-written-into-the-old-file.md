# An amended ADR carries its pointer under its title, written into the old file

An ADR a later one changes carries `Amended by ADR NNNN: <the clause>` or `Superseded by ADR NNNN`
directly under its title, and `discuss` writes that line into the old file at the close that writes
the new one, so an ADR is not append-only. `Amended by` means the ADR still holds and the newer one
must be read too; `Superseded by` means its body is no norm, and the reader follows the pointer to
an ADR with no such line. The existing ADRs get the lines in one backfill. The pointer sits in the
old file because the reader's second pass (ADR 0121) greps only the files its term search found, and
the top is where a partial read sees it, while the old pointers sat below line 20 in 13 of 16 cases.

## Considered options

- A line on the new ADR alone, with the state derived: the second pass would miss it, and every
  reader would run one more search per ADR found.
- Keeping the pointer in the footer: a partial read takes a superseded decision for a live one.
