# The dispatch names who relies on the behaviour, and no scan judges an assertion

The criterion of ADR 0040 is a judgement, and a rule that lives only in `POLICY.md` never reaches
the author at the moment a test is written. Both test-author agents therefore take a required
dispatch field, `Relied on by`: who relies on the behaviour and what a wrong or missing result
costs them. The agent refuses with `REFUSED_INCOMPLETE_INPUT` a dispatch whose field names no cost,
which is the field a label-only test cannot fill. The report gains an `Outcome` line pointing at the
assertion that proves the behaviour, `file:line`, with each **Settle point** and its anchor, so a
reviewer checks in seconds that the test ends in an **Outcome**.

## Considered options

- A new section in `scan-test-assets.sh` flagging bare-presence text assertions: a pattern cannot
  read what rides on a string, and a role-gated menu check and a showcase title check have the same
  shape, so the scan would flag the contracts along with the decoration.

## Consequences

Every caller that dispatches an author supplies the field, the `do` skill's playbooks and its
global test-author agents included.
