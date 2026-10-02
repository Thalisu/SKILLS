# The policy core in CLAUDE.md is short and a generated reference carries the full rules

A project's `CLAUDE.md` is loaded whole in every session, and the Testing Policy core was most of
it, so the core now carries only the rules that must hold when nobody opens anything else, plus
triggers of the form "Read `.claude/testing-policy/policy.md` before <task>", and the full rules
move, under the titles other files cite, to that reference file, rendered from the same `POLICY.md`
by `render-policy.sh --reference`. The reference is generated and never preserved: ADR 0017 keeps a
norm out of any zone `verify-policy.sh` does not compare, so `verify-policy.sh` compares the
reference byte for byte with the template (`policy_reference=missing|drifted|ok`) the way it
compares the core. Project facts stay in `CLAUDE.md`, preserved, because scripts and skills read
their lines from there.

## Considered options

- Keep the whole policy in `CLAUDE.md`: one file to verify, but every session pays for the dispatch
  input, the `HANDBACK` routing and the promotion rules whether or not a test is being written.
- Import the reference with `@path`: the file loads at launch like the rest of `CLAUDE.md`, so it
  saves no context.
- Move the long rules into the agent files: they already bind the dispatched author, but the caller
  who dispatches, routes a handback or declares the work done is bound by rules the agent never
  reads.

## Consequences

- The template version goes to 3.0. An install on 2.10 reads `stale`, and the refresh replaces the
  core, writes the reference and leaves Project facts as they are.
- A citation of a policy title resolves in the reference file; a citation of Project facts still
  resolves in `CLAUDE.md`.
