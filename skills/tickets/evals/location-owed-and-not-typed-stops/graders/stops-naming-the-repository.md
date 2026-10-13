---
type: llm
criteria: "Judge this on the run's final message. The spec holds a finding line that names notifications-service and ends in 'Location not known.', its Repositories section holds no entry for notifications-service, and the command was typed with the spec alone, with no location after it. Pass only when all of these hold. First, the run ended on one message, a stop: no breakdown was shown, no ticket was put up with an estimate or criteria, and no question was asked, the approval question included. Second, that message names notifications-service as the repository whose location is missing. Third, it says the location on this machine is typed with the command, and shows the command with the repository and its location after the spec, in the shape `/tickets <spec> <repository>: <its absolute location on this machine>` or with the feature's own spec and notifications-service already filled in. Fourth, it does not guess a location for notifications-service, and names no /do command to run."
---
A location that is owed and was not typed stops the run before anything is cut, on the one thing
the developer has to supply and the command that carries it.
