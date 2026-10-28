# The integrate door's refusal

It is read by step 1 of [integrate.md](integrate.md), the door, when `integrate-door.sh` exits 1,
and by no other step or Playbook.

The door prints one `refused=` line, first match wins:

- a `git am` stopped on the branch: `refused=am-in-progress`, the message naming its continue and
  abort;
- a branch that does not exist, local or remote-tracking: `refused=missing-branch`;
- a branch name carrying a shell metacharacter (`$`, backtick, `;`, `|`, `&`, `(`, `)`, `<`, `>`, a
  newline): `refused=unsafe-branch-name`;
- a merge whose target is protected, by the rule `trivial-door.sh branch <name>` prints:
  `refused=protected-target`. A rebase onto a protected branch is not refused;
- a branch written to that is not the one the developer stands on: `refused=wrong-branch`, the
  message naming the `git switch` that fixes it;
- uncommitted work with no integration in progress: `refused=dirty-tree`, the files named.

The run ends there, nothing integrated: the reply is the `Playbook: integrate` first line and the
door's `message=` line, word for word, which ends `nothing integrated`.
