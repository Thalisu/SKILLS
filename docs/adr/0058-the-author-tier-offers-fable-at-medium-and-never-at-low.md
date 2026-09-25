# The author tier offers Fable at medium effort, and never at low

The tier question the testing-policy install asks per author gains a fourth option, `fable · medium`,
listed beside the Recommended `opus · medium`, `sonnet · high` and `inherit`. It is offered on the
prompting guideline for the model, `.agents/prompting/fable-5-1.md`, section "Consider all effort
levels": "At `low`, Claude Fable 5.1 is often competitive with Claude Opus and Claude Sonnet models
on cost per task while scoring higher, so include it in the comparison wherever you'd otherwise run
a smaller model at a higher effort level." The `sonnet · high` option is exactly that slot, a
smaller model at a higher effort, so the Fable option sits next to it and the Sonnet description
is written against it. Its effort is `medium` and never `low`, on the same file's section "Search
triggering at low effort": "At `low` effort, Claude Fable 5.1 is less likely than Claude Fable 5 to
call a search or retrieval tool, and more likely to answer from memory." The author's core job is
the reuse audit, a search over the test tree, and an author that answers it from memory recreates
the asset it was dispatched to find; `medium` is the lowest effort the guideline backs there ("At
`medium`, results roughly match Claude Fable 5 at lower cost"). The Recommended pair stays
`opus · medium`: the argument of
[ADR 0052](0052-the-test-authors-carry-the-model-and-effort-the-project-picked-at-install.md), a
wrong test paid twice under red-first and an author that diagnoses its own misses, is unchanged,
and the guideline asks for the comparison to be run against your own evals, which this repository
has not run for the author on Fable. This record amends nothing in 0052.

## Considered options

- **`fable · low`**: rejected on the search-triggering line. Cost per task is the whole point of the
  option, and `low` is where it is best, but an audit skipped is a duplicate written, which the
  second-use rule then pays back later.
- **`fable · medium` as the Recommended pair over Opus**: rejected as unmeasured. The guideline says
  to test the effort levels against your own evals before stepping down, and a recommendation the
  counts of step 2 cannot justify is one the user cannot correct.
- **Replacing `sonnet · high` with the Fable option**: rejected because Sonnet stays a value the
  harness accepts and the trade-off is the project's to make, per 0052; the option is kept and
  described against Fable so the two cheaper pairs read as a comparison.
- **Adding `fable · high` as well**: rejected because it undercuts nothing. The Recommended pair
  already holds the stronger model, and a fourth pair at a higher effort blurs the one reason the
  Fable option is listed, cost per task.

## Consequences

The question carries four options plus the free-text Other the tool adds. `render-agent.sh` already
accepts `fable`, so no script and no test changes: the option is prose in the skill and its docs
page. An eval that shows Fable holding on the reuse audit and the handback diagnosis is the trigger
to revisit the Recommended pair, in a record of its own.
