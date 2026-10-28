# A prompt carries instructions, and the why lives in the ADRs alone

The skills, references and agent definitions of this repository explained most rules beside them:
the history of a rule, the alternative it beat, the attack it closes, often a paragraph per
instruction, so the `do` session carried that argument in its window on every run while no step of
its own turned on it, and the same argument already sat in an ADR. A prompt now holds instructions
only, written to the principles and the guidelines, and the reason a rule is shaped as it is lives
in `docs/adr/` and nowhere else. One **Goal clause** may stay beside an instruction that is not a
closed list of cases, naming what the instruction protects, since that is what lets an agent act
right on a case the rule never listed; it never carries history, a rejected alternative or an ADR's
argument. This departs on purpose from the upstream advice to give the model the motivation behind
an instruction (`.agents/prompting/prompting-best-practices.md`, "Add context to improve
performance"), and the repository's contract wins over that copy here.

## Considered options

- No why at all in a prompt: an agent meeting a case outside the rule's list improvises, since
  nothing names what the rule protects.
- The why kept beside every rule, as before: the largest share of the `do` session's references,
  read on every run and spent on no decision.
