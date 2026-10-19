---
type: llm
criteria: "The run's last message is a Reply opening `Playbook: pr`. It carries exactly one `Yours:` line, of class `direction`, and that line names the check `schema` and the file `db/migrations/0002_add_email.sql` as a migration file the run does not change, offering the developer to change that file themselves or to fix the check another way by hand. No `Yours:` line is of class `outward`, and the `Yours:` line names no push, neither one the run made nor one offered to the developer. Its For whom carries a round line for `schema` saying its commit was not picked because `db/migrations/0002_add_email.sql` is a migration file."
---
The stop hands the developer the check and the migration file on one `Yours: direction:` line, naming no push.
