# A ticket is sized by a token estimate in three bands, and a fold is judged on the merged estimate

`tickets` sized a ticket as "fits one session" and asked the user whether the edges held and whether
tickets should be merged or split, while ADR 0003 calls judging "small" in the moment drift and ADR
0010 and the glossary had resolved every other size word into structure. A ticket's size is now the
tokens `do` is estimated to spend on it, in three bands: small under 150k, medium up to 200k, large
beyond. A large ticket is split along its steps, a small ticket whose single edge ties it to one
neighbour folds into it when the fold delays no ticket's start and the merged estimate stays medium
at most, a medium ticket is left as cut, and every estimate is stated in the breakdown so a reader
can check the reasoning that the in-the-moment judgement hid. A number beat structure because the
window is the one yardstick that holds across harnesses and models, while "one session" and "one
step" do not; the edge graph still names the pair, since an estimate says which ticket is small but
not which neighbour it folds into. Edges are read off the journey's `## States` or the stories: a
ticket that reads what another writes waits for the writer, and a stub to start it sooner is never
cut. The one question left to the user is approval.

## Considered options

- Structure only, the edge graph plus step count: blind to weight, so a one-step path that touches
  forty call sites folds into its neighbour and the merged ticket no longer fits one run.
- The estimate only: it leaves parallelism unread and cannot say which neighbour to fold into.
- Keep the three quiz questions from the upstream skill: every one of them is a reversible cut
  decision the skill can read off the breakdown, and each round trip stalls the chain on the human.
