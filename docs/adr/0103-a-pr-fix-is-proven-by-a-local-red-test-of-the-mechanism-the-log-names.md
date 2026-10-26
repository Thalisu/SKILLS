# A `pr` fix is proven by a local red test of the mechanism the log names

ADR 0087 let the fixer act only on a failure it reproduced locally, which stopped every check whose
end-to-end run does not fail on the developer's machine, even when the log named the cause (a stub
whose id counter resets and collides with an `external_id` already stored). The evidence is now any
local test that goes red on the cause the log points at, the whole e2e or a smaller unit or
integration test of the mechanism, written red-first like any fix. The log stays the pointer and is
never the proof: no code is edited with nothing red locally. A fix proven this way returns
`fixed <k> by mechanism: <the test> <the log line that names it>`, and the Reply says the e2e itself
was not reproduced locally.

## Considered options

- ADR 0087 kept strict, with a richer stop: the diagnosis reaches the developer, and the run still
  stops on a failure it could have proven and fixed.
