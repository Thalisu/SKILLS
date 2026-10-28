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
- A `none` the reader marked as read from neither a Path nor a story has nothing behind it. The
  fork goes through the Ticket's criteria one by one instead, each with its flow or the reason it
  needs none.

## Who authors it

The brief's `Loop:` key decides.

- `Loop: policy`: the surface is the one the project's Testing Policy names on its section marker.
  - On a native or mixed surface the flow is authored by the E2E test author of
    [build-loop.md](build-loop.md) with the complete input: the behaviour to prove, who relies on
    it and what a wrong or missing result costs them, the journey or screen, the origin, the
    fixture state, placement when it matters.
  - On a consumer surface the flow lives in the consumer repository: no author is dispatched and
    the `fallback:` line names it as pending debt with the consumers named.
- `Loop: global`: the project has no Testing Policy and so no section marker naming a surface, and
  the Project map the brief names stands in for it.
  - When the map's single-flow command is filled, each criterion the Digest marks observable gets
    its flow from `global-e2e-test-author` with the same complete input and the map's path, and the
    same verdicts.
  - When that command reads `none yet → /testing-policy` and the map's full-suite end-to-end
    command is filled too, no author is dispatched: the `fallback:` line names the single-flow slot
    the map left unfilled and quotes the full-suite command the map does carry, and the criterion
    it would have proven is left for the session to leave unticked at the close.
  - When both commands read `none yet → /testing-policy`, no author is dispatched either: the
    `fallback:` line reads `no end-to-end command in the project` and names `/testing-policy` as
    the command that would fill the slot.
- `Loop: fallback`: the same map decides, and where its command is filled the fork authors the flow
  itself and says so on a `fallback:` line.

## Reading the author's report

The report's `Run` section is read before its verdict. An author runs its flow at most twice in one
dispatch, so a report naming a third run broke the fix ceiling, whatever verdict it carried,
`GREEN` included. It is refused whole and the criterion is dispatched again naming the runs the
fork counted, since a forked author's report reaches no hook and the count is the caller's or
nobody's.

Then the verdict routes:

- `GREEN`: the flow must return it. The flow is committed, staged by path, on its own or with the
  last behaviour, and reported on a `flow:` line. A flow committed on its own carries no
  `Behaviour:` line.
- `BLOCKED` on a preflight stops the fork with that reason.
- `HANDBACK` takes the route the loop's `HANDBACK` takes in [build-loop.md](build-loop.md),
  read off the Handback's `Diagnosis` line, and a second `HANDBACK` on the same criterion stops the
  fork.
- `REFUSED_INCOMPLETE_INPUT` takes the loop's own route in [build-loop.md](build-loop.md): a
  criterion or a **Relied on by** too vague to become an outcome assertion is sharpened and
  dispatched again, and a refusal because no one relies on the criterion means it is structural, so
  it ships with no flow and its `flow:` line says so.
