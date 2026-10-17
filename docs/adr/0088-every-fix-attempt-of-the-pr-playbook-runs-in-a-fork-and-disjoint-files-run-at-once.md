# Every fix attempt of the `pr` Playbook runs in a fork, and disjoint files run at once

ADR 0009 has the session write and a delegate as the exception. The `pr` Playbook writes no fix in
the session: each red check is one fork of `do-pr-fixer`, in a worktree and on a branch of its
own, and the checks whose files are disjoint run at once, grouped in Waves by the grouping core of
`do-code-review`'s `fix-waves.sh` and brought onto the head by `fix-integrate.sh`, which aborts a
conflicting pick and re-routes it to the next Wave (ADR 0053, ADR 0054). The session keeps the
loop: watch the checks, fork the Wave, integrate, fast-forward, push, watch again. A round can carry
several unrelated failures, and a session that fixed them one after another would hold every log and
every diagnosis in one window and serialise work that shares no file.

## Considered options

- The session fixes each failure itself, per ADR 0009: one window for every failure of every round,
  and no parallelism across disjoint files.
- A mechanism of the Playbook's own for the Waves and the integration: a second copy of scripts that
  already sequence, abort and re-route by Finding number, which works as well by check number.
