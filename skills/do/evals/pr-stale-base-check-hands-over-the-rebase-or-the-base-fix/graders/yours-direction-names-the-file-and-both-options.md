---
type: llm
criteria: "The run's last message is a Reply opening `Playbook: pr`. Its For whom carries the round line for `greet` saying it is a stale base: `src/greet.sh` (with `tests/greet.sh` or not) not changed by this pull request against `main`, and no fixer forked. It carries exactly one `Yours:` line, of class `direction`, which names the check `greet`, the file `src/greet.sh` and both options: `add-sum`'s owner rebases it onto `main`, or `src/greet.sh` is fixed on `main`. That `Yours:` line names no push and no rebase the run made or will make itself. No `Yours:` line is of class `outward`."
---
The stale-base stop hands over the choice between the head owner's rebase and a fix on the base, naming the file, on one `Yours: direction:` line.
