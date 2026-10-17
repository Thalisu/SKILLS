# The `pr` Playbook reruns a check once, after its fixer could not reproduce it

ADR 0086 authorises two writes outside the repository, and this adds a third: `gh run rerun
--failed` on the run of the pull request's head, once per check per run, and nothing else. The
rerun is triggered by a fact, the fixer's failed local reproduction (ADR 0087), never by the
session reading a log as a flake, so a round has no `flake` class (ADR 0028). On a round that also
pushes fixes, the new run on the pushed head is the check's retry and no rerun is made. A check red
again after its retry stops the run as not reproducible. A rerun loses nobody's work and costs only
CI minutes, while handing it over turns every flake into a stop whose `Yours:` line is a command
the run could have run itself.

## Considered options

- No rerun, the first pick in the journey: every flake costs a fixer fork, a reproduction attempt
  and a stop that hands the developer the rerun command.
- A rerun when the log looks like a flake, as story 20 first read: a class the session reads off
  the log, and a rerun spent before anyone knows whether the failure reproduces.
