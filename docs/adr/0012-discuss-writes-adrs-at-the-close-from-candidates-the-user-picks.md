# discuss writes ADRs at the close, from candidates the user picks

`discuss` no longer writes an ADR the moment a branch closes. A term still goes to `CONTEXT.md`
as it lands; a decision stays on its branch as one line (the choice, its reason, the alternative it
beat), and at the close every decided branch that passes the three gates of
`.agents/formats/adr-format.md` is listed as a candidate with each gate filled in one clause, put
to the user as one question, and only the picked ones are written, from the branch's line. The rest
reach the spec through the closing summary, whose Implementation Decisions section is the home of a
decision scoped to one feature. Capture as it lands had produced one ADR per decided branch, seven
for one feature, most restating what the spec was about to say, and every later step of the chain
reads `docs/adr/` for the area it touches, so each weak ADR was context spent on every run after
it. The gates are judged better with the whole tree closed, and a gate that cannot be filled in one
clause now drops the candidate before the question, which is the mechanism the as-it-lands rule
lacked.

## Considered options

- Keep capture as it lands and tighten the three gates in prose: the gates were already prose, and
  the drift happened with them in place.
- Move ADRs beside the spec, under `.scratch/<feature>/adr/`: the spec is an issue in GitHub and
  GitLab mode and has no folder, `.scratch` is unversioned in some projects, the chain reads ADRs by
  area and would have to sweep every feature, and numbering would restart per feature.
- Skip the ADR whenever a spec follows: in the chain a spec always follows, and the spec names an
  ADR by title instead of carrying it, so the decision would leave the repository with the feature.

## Consequences

A long session holds its decisions on the tree until the close instead of on disk. The one-line row
per branch is what an ADR is written from, never memory of the interview.

The "candidates the user picks" clause is superseded by ADR 0026: the close writes every candidate
the gates and the tells leave standing and asks nothing. The rest of this ADR stands.
