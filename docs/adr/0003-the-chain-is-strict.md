# The chain is strict: each skill takes only its predecessor's artifact

`spec` takes the conversation, `journey` takes a spec, `tickets` takes a spec whose verdict is met
(`Journey: not needed`, or `required` with the journey written beside it), and `do` takes one
ticket. No skill accepts the artifact of a step further back: `tickets` refuses a spec that requires
a journey and has none, and `do` never runs on a spec or on a session summary. The alternative,
`discuss` straight to `do` for work that fits one session, was dropped: judging "small" in the
moment is the same drift ADR 0001 removes from the journey verdict, and one input per skill keeps
every step checkable from its artifact.
