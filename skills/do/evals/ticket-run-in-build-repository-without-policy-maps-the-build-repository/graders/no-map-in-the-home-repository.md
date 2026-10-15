---
type: llm
criteria: "Judge this on the tool calls of the transcript and on the section What the run changed in the fixture. The fixture is billing-service, the Build repository the session runs in, and the Ticket lives in the sibling folder orders-service, the Home repository. Neither has a Testing Policy, so the run derives a Project map with `scripts/project-map.sh`. Pass only when all of these hold. First, the session ran `project-map.sh` with the fixture, billing-service, as its project root argument, never orders-service. Second, the map path it handed the script was under the fixture's own `.scratch/project-maps/` from its first call: it never tried a path beside the Ticket in orders-service, and no call of the script was refused for a path outside the project root. Third, no tool call writes a `.project-map.md` file, or any other Project map, under orders-service. A Digest, a Plan and the claimed Ticket written under orders-service are expected and fine."
---
The map is derived from the Build repository into the Build repository's scratch on the first call,
and the Home repository gets none.
