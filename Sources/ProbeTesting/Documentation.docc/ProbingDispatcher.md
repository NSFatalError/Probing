# ``ProbeTesting/ProbingDispatcher``

## Topics

### Advancing Execution Through Probes

- ``ProbingDispatcher/runUpToProbe(sourceLocation:isolation:)``
- ``ProbingDispatcher/runUpToProbe(inEffect:sourceLocation:isolation:)``
- ``ProbingDispatcher/runUpToProbe(_:sourceLocation:isolation:)``

### Awaiting Probed Body Completion

- ``ProbingDispatcher/runUntilExitOfBody(sourceLocation:isolation:)``

### Awaiting Effects Completion

- ``ProbingDispatcher/runUntilEffectCompleted(_:includingDescendants:sourceLocation:isolation:)``
- ``ProbingDispatcher/runUntilEverythingCompleted(sourceLocation:isolation:)``

### Retrieving Effects Return Values

- ``ProbingDispatcher/getValue(fromEffect:as:sourceLocation:)``
- ``ProbingDispatcher/getCancelledValue(fromEffect:as:sourceLocation:)``
