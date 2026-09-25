# The E2E author is Recommended at high effort, and an unmeasured xhigh is never Recommended

The tier question the testing-policy install asks for the `e2e-test-author` marks `opus · high`
as the Recommended pair on every project. Until now the skill stepped it up to `opus · xhigh` when
the preflight named stateful services (a database, auth, seeds) the flows depend on. That step-up
goes, on the prompting guideline for the model, `.agents/prompting/opus-5-5.md`, section
"Calibrate effort": "Reserve `xhigh` and `max` for work where you've measured a quality gain."
This repository has measured no such gain for the E2E author on stateful flows, and the same
section says what an unmeasured step-up costs on every turn: "At a given level, Claude Opus 5.5
tends to think more per turn than Claude Opus 5, especially at `xhigh` and `max`." The count
stays: when the preflight names stateful services, the option's description quotes them as the
one reason a user may answer `opus xhigh` in free text, and says that step-up is unmeasured, so
the choice is the project's and made with the fact in view. The unit author's step up to
`opus · high` on shared-home debt is untouched: `high` is not a level the guideline reserves. The
Recommended model stays `opus` for the reasons of
[ADR 0052](0052-the-test-authors-carry-the-model-and-effort-the-project-picked-at-install.md), a
wrong test paid twice under red-first and an author that diagnoses its own misses. This record
amends nothing there.

## Considered options

- **Keep the `xhigh` step-up on stateful services**: rejected as unmeasured. The intuition behind
  it, that a flow which seeds a database and signs a user in is harder to author, is plausible and
  is exactly what the guideline asks to test against an eval before paying for it per turn.
- **Refuse `xhigh` in the free-text answer for the E2E author**: rejected because
  `render-agent.sh` accepts every level the harness does, and the cost-against-quality trade-off is
  the project's to make, per 0052. The option's description carries the fact; the answer stays
  free.
- **Count the stateful services in discovery and step up above a threshold**: rejected because a
  threshold is a count standing in for a measurement. The guideline reserves the level for a gain
  that was measured, and a count of services measures nothing about the author's output.

## Consequences

The E2E question carries the same four options as the unit one, with `opus · high` Recommended on
every surface that installs the author. No script, template, rendered copy or test changes: the
rule is prose in the skill and its docs page. An eval that shows the E2E author gaining at `xhigh`
on stateful flows is the trigger to revisit the pair, in a record of its own.
