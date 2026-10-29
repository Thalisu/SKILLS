# The flows

Read by the Builder of [builder.md](builder.md) once the Plan's last behaviour is committed, by the
`do-impeccable` fork once the screen's last criterion is committed, and by the session that builds
in the Builder's place when no Builder can be forked, only when the Digest's `## Observable
criteria` section names a criterion, reads a `none` the reader marked as read from neither a Path
nor a story, or, for `do-impeccable`, no Digest sits beside the Ticket. A run whose section reads
any other `none` never opens it.

After the feature exists, every criterion a user can observe gets its flow authored or extended,
inside the window that built the feature, like the rest of the loop. Three things are settled per
criterion, in this order: whether it gets a flow, who authors it, and what the author's report
allows.

## Which criteria get a flow

The Digest's `## Observable criteria` section decides, and never the fork's own reading of the
diff. The section is the reading the reader returned from the Path's own steps, or from the stories
it quoted when the Digest carries no Path.

- A criterion the section names gets a flow. One it names with no flow authored stops the fork with
  that reason on its `stopped:` line. The routes below that dispatch no author are not that case:
  each accounts for its criterion on a `fallback:` line.
- A criterion the section leaves out gets no flow, and its `flow:` line states why none is needed.
- A section reading `none` closes the flows with `no criterion a user can observe` on a `fallback:`
  line, naming the section it read that from.
- On a `none` the reader marked as read from neither a Path nor a story, the fork goes through the
  Ticket's criteria one by one instead, each with its flow or the reason it needs none.

## Who authors it

The brief's `Loop:` key decides.

- `Loop: policy`: the surface is the one the project's Testing Policy names on its section marker.
  - On a native or mixed surface the flow is authored by the build loop's E2E test author (Read
    [build-loop.md](build-loop.md) when a flow is authored) with the complete input: the behaviour to prove, who relies on
    it and what a wrong or missing result costs them, the journey or screen, the origin, the
    fixture state, placement when it matters.
  - On a consumer surface the flow lives in the consumer repository: no author is dispatched and
    the `fallback:` line names it as pending debt with the consumers named.
- `Loop: global` or `Loop: fallback`: Read [global-authors.md](global-authors.md) when the brief's
  `Loop:` key reads either.

## Reading the author's report

The report's `Run` section is read before its verdict. An author runs its flow at most twice in one
dispatch, so a report naming a third run broke the fix ceiling, whatever verdict it carried,
`GREEN` included. It is refused whole and the criterion is dispatched again naming the runs the
fork counted.

Then the verdict routes:

- `GREEN`: the flow must return it. The flow is committed, staged by path, on its own or with the
  last behaviour, and reported on a `flow:` line. A flow committed on its own carries no
  `Behaviour:` line.
- `BLOCKED` on a preflight stops the fork with that reason.
- `HANDBACK` takes the route the loop's `HANDBACK` takes (Read [build-loop.md](build-loop.md) when
  a flow comes back `HANDBACK`), read off the Handback's `Diagnosis` line, and a second `HANDBACK` on the same criterion stops the
  fork.
- `REFUSED_INCOMPLETE_INPUT` takes the loop's own route (Read [build-loop.md](build-loop.md) when a
  flow comes back `REFUSED_INCOMPLETE_INPUT`): a
  criterion or a **Relied on by** too vague to become an outcome assertion is sharpened and
  dispatched again, and a refusal because no one relies on the criterion means it is structural, so
  it ships with no flow and its `flow:` line says so.
