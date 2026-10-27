# The `pr` Playbook pushes fast-forward only to its pull request's head, shared or not

Every other `do` Playbook ends with nothing pushed, and a push is the `outward` Handover class (ADR
0057). A request to follow a pull request, or to open one and follow it, is the developer
authorising the writes that loop needs, and only those: creating that one pull request when none is
open for the pair, pushing to its head branch by fast-forward, never `--force`, never a merge and
never a push to any other branch, and the one rerun of a check ADR 0089 allows. The fixes go on the
head itself even when it is a branch others write, such as `dev` in a `dev` to `prod` pull request:
before each push the run fetches, pulls and replays the round when the remote moved, and a head that
still refuses a fast-forward stops the run, so git's own refusal is what serialises the writers.

## Considered options

- A stop with `Yours: outward` before every push: a loop that runs until the checks are green
  cannot stop on its first push wave.
- Fixes on a `fix/pr-<n>` branch opened as a pull request into the head: the loop waits on two CI
  runs per round and protects nothing the fast-forward rule does not already protect.

Amended: ADR 0102 widens what the push carries. A fixer whose own compose brought the job's stack up
healthy leaves it as a `chore(e2e)` commit ahead of its fix commit, and the push carries both by
fast-forward, compose first; the fast-forward rule above is unchanged.
