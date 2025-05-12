# ``ProbeTesting``

Control the execution of asynchronous code during tests using a sequence of dispatches.

## Overview

To use `ProbeTesting`, you first need to prepare your codebase using the `Probing` library.

- SeeAlso: Refer to the `Probing` documentation for details on how to make your code controllable during tests.

`ProbeTesting` gives you precise control over the execution of asynchronous code,  
making it fully predictable and testable. It also lets you reason about the flow 
from the user’s perspective by reducing it to a clear, step-by-step sequence of dispatches.

To use these features, wrap your test code with the 
``withProbing(options:sourceLocation:isolation:of:dispatchedBy:)`` function:

```swift
@Test
func testLoading() async throws {
    try await withProbing {
        await viewModel.load()
    } dispatchedBy: { dispatcher in
        #expect(viewModel.isLoading == false)
        #expect(viewModel.download == nil)

        try await dispatcher.runUpToProbe()
        #expect(viewModel.isLoading == true)
        #expect(viewModel.download == nil)

        downloaderMock.shouldFailDownload = false
        try await dispatcher.runUntilExitOfBody()
        #expect(viewModel.isLoading == false)
        #expect(viewModel.download != nil)

        #expect(viewModel.prefetchedData == nil)
        try await dispatcher.runUntilEffectCompleted("backgroundFetch")
        #expect(viewModel.prefetchedData != nil)
    }
}
```

## Topics

### Getting Started

- <doc:Examples>

### Enabling Probing In Tests

- ``withProbing(options:sourceLocation:isolation:of:dispatchedBy:)``
- ``ProbingDispatcher``
- ``ProbingOptions``
