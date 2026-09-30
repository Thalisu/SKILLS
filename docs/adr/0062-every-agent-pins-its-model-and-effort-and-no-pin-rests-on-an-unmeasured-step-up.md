# Every agent pins its model and effort, and no pin rests on an unmeasured step-up

Five agents are re-pinned against the prompting guidelines in `.agents/prompting/`. The
`choice-taker` moves from `fable · high` to `opus · high`: the models overview starts with Opus
5.5 for most workloads and keeps Fable 5.1 for "when your evals on Claude Opus 5.5 at higher effort
still fall short", no such eval was run, and ADR 0036 names the pin without a reason. It stays off
Sonnet because a `settled` Ruling becomes a norm later runs read. The technical and security
reviewers move from `opus · xhigh` to `opus · high`, on the line ADR 0059 already applied: "Reserve
`xhigh` and `max` for work where you've measured a quality gain", and none was measured. The two
global test authors, which inherited the session's model and effort, carry the pairs
`testing-policy` recommends for the authors it installs, `opus · medium` for the unit author and
`opus · high` for the E2E one, for the reasons of ADR 0052: a wrong test is paid twice under
red-first. `comment-sicko` keeps `sonnet` and gains `effort: medium`, since an agent with no
`effort:` line runs at whatever level the session happens to hold.

## Considered options

- **Move the reviewers to `sonnet`**: rejected. The review runs once (ADR 0033), so a Finding it
  misses ships, and the Sonnet 5.5 announcement keeps Opus 5.5 "clearly stronger at complex,
  open-ended work requiring sustained judgment". Sonnet's `cyber` classifier would also put a
  refusal risk on the security reviewer.
- **Pin full model IDs instead of aliases**: rejected, as in ADR 0052, because the aliases follow
  the releases. The cost is that `sonnet` resolves to the session's model when the session runs a
  Sonnet, and to an older Sonnet on Bedrock, Vertex and Foundry.

## Consequences

An eval that shows a gain at `xhigh` for a reviewer, or for Fable on the `choice-taker`, is the
trigger to revisit that pin, in a record of its own. The `do-builder` stays on `opus · medium`: it
is the largest spender, and `sonnet · high` is the candidate to measure there first.
