# Spec lives where the issue tracker file says, and in .scratch by default

`spec` publishes where `docs/agents/issue-tracker.md` points: `.scratch/<feature-slug>/spec.md` in
local markdown mode, an issue in GitHub or GitLab mode. When that file is absent it writes
`.scratch/<feature-slug>/spec.md` and says so, and never demands a setup skill. One home keeps the
slug resolution that `journey`, `tickets` and `do` share, and the stand-in `to-tickets` reads the
same path. A versioned `docs/specs/<slug>.md` was rejected because it would be a second convention
for every skill in the chain to resolve. When `.scratch` is ignored by git, the closing summary says
the spec is unversioned.
