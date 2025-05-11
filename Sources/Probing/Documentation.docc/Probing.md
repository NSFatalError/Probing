# ``Probing``

Define suspension points accessible from tests with probes, and make side effects controllable.

## Overview

To use `ProbeTesting`, you first need to prepare your codebase using the `Probing` library.

The `Probing` library lets you define suspension points using the ``probe(_:preprocessorFlag:)`` macro. 
These are typically placed after a state change and before `await` statements, for example:

```swift
func load() async {
    isLoading = true

    // Add a probe macro after `isLoading` is set to `true`, 
    // but before next `await`, to verify the state change in your tests.
    await #probe() 

    await downloadAndProcess()
    isLoading = false
}
```

If your code uses `Task` to create side effects, you can replace them with the ``Effect(_:preprocessorFlag:priority:operation:)`` 
macro or one of its variants. For example:

```swift
func load() {
    isLoading = true
    
    #Effect("download") {
        // Replace `Task` instances with effect macros, 
        // so they will become initially suspended during tests,
        // making their execution controllable and predictable.

        await downloadAndProcess()
        isLoading = false
    }
}
```

`Task` and effects created by `Probing` both conform to the ``Effect`` protocol and have the same public interface, 
so replacing one with the other should be seamless. In fact, in release builds (by default), effect macros will return 
standard Swift `Task` instances, so that your production code will not be affected by integration with `Probing`.

- SeeAlso: Refer to the `ProbeTesting` documentation for details on accessing probes and controlling effects during tests.

## Topics

### Getting Started

- <doc:Examples>

### Installing Probes

- ``probe(_:preprocessorFlag:)``
- ``ProbeName``
- ``ProbeIdentifier``

### Creating Effects 

- ``Effect(_:preprocessorFlag:priority:operation:)``
- ``Effect(_:preprocessorFlag:executorPreference:priority:operation:)``
- ``ConcurrentEffect(_:preprocessorFlag:priority:operation:)``
- ``EffectName``
- ``EffectIdentifier``

### Using Effects

- ``Effect``
- ``AnyEffect``
