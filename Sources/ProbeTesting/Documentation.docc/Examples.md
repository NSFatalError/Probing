# Examples

Explore simplified examples from the `ProbingPlayground` sample project to see `ProbeTesting` integration in action.

## Download the Sample Project

You can download the `ProbingPlayground` sample project from its [GitHub page](https://github.com/NSFatalError/ProbingPlayground).

## Running Through Probes in Async Functions

To verify that an object has changed state while an `async` function is running,  
you can suspend the execution of `body` at declared probes using the ``ProbingDispatcher/runUpToProbe(sourceLocation:isolation:)`` 
method. You don't need to declare a probe at the end of the `body`, since the 
``ProbingDispatcher/runUntilExitOfBody(sourceLocation:isolation:)`` method suspends execution there for you:

```swift
@Test
func testUploadingImage() async throws {
    try await withProbing {
        await viewModel.uploadImage(ImageMock())
    } dispatchedBy: { dispatcher in
        #expect(viewModel.uploadState == nil)

        try await dispatcher.runUpToProbe()
        #expect(uploader.uploadImageCallsCount == 0)
        #expect(viewModel.uploadState == .uploading)

        try await dispatcher.runUpToProbe()
        #expect(uploader.uploadImageCallsCount == 1)
        #expect(viewModel.uploadState == .success)

        try await dispatcher.runUntilExitOfBody()
        #expect(viewModel.uploadState == nil)
    }
}
```

This lets you reliably verify the `uploadState`, reproducing the exact sequence of events users experience in your app.

## Interacting with Mocks During Tests

When testing asynchronous functions or side effects, you often have to set up mocks far in advance.
This can be problematic, as it decouples the setup from the actual invocation, obscuring its purpose.

With `ProbeTesting`, you can control your objects directly in the `test` closure, 
immediately before running a dispatch that triggers their usage. For example, you can yield elements to an `AsyncSequence`
or finish it at precise moments:

```swift
@Test
func testUpdatingLocation() async throws {
    try await withProbing {
        await viewModel.beginUpdatingLocation()
    } dispatchedBy: { dispatcher in
        #expect(viewModel.locationState == nil)

        locationProvider.continuation.yield(.init(location: .sanFrancisco))
        try await dispatcher.runUpToProbe()
        #expect(viewModel.locationState == .near)
        
        locationProvider.continuation.yield(.init(location: .init(latitude: 0, longitude: 0)))
        try await dispatcher.runUpToProbe()
        #expect(viewModel.locationState == .far)
        
        locationProvider.continuation.yield(.init(location: .sanFrancisco))
        try await dispatcher.runUpToProbe()
        #expect(viewModel.locationState == .near)
        
        locationProvider.continuation.yield(.init(location: nil, authorizationDenied: true))
        try await dispatcher.runUpToProbe()
        #expect(viewModel.locationState == .error)
        
        locationProvider.continuation.yield(.init(location: .sanFrancisco))
        try await dispatcher.runUpToProbe()
        #expect(viewModel.locationState == .near)

        locationProvider.continuation.finish(throwing: ErrorMock())
        try await dispatcher.runUntilExitOfBody()
        #expect(viewModel.locationState == .error)
    }
}
```

This allows you to reliably verify the `locationState` before entering the loop, after each iteration, 
or after an error is thrown.

## Controlling Execution of Effects

To control the execution of effects, you have several options, starting with the
``ProbingDispatcher/runUntilEffectCompleted(_:includingDescendants:sourceLocation:isolation:)`` method.

You can also retrieve the value returned by an effect using ``ProbingDispatcher/getValue(fromEffect:as:sourceLocation:)``,
or check if it was cancelled using ``ProbingDispatcher/getCancelledValue(fromEffect:as:sourceLocation:)``.

None of these methods require you to store references to effects. `ProbeTesting` can identify and access them during testing:

```swift
@Test
func testDownloadingImage() async throws {
    try await withProbing {
        await viewModel.downloadImage()
    } dispatchedBy: { dispatcher in
        await #expect(viewModel.downloadState == nil)

        try await dispatcher.runUntilExitOfBody()
        #expect(viewModel.downloadState?.isDownloading == true)

        try await dispatcher.runUntilEffectCompleted("low")
        #expect(viewModel.downloadState?.quality == .low)

        try await dispatcher.runUntilEffectCompleted("high")
        #expect(viewModel.downloadState?.quality == .high)
    }
}
```

This enables you to reliably verify the `downloadState` before downloads start, 
as well as verify its progression as effects complete.

## Recreating Runtime Scenarios

Even with full test coverage reported by Xcode, you can’t be certain that all execution paths have been exercised.
Each await introduces a suspension point where another side effect - isolated to the same actor - might interleave, 
altering the sequence of events.

By flattening the execution tree into a series of dispatches, `ProbeTesting` allows you to recreate specific runtime scenarios 
that users might experience. Previously, this level of control and expressivity was nearly impossible to achieve in tests:

```swift
@Test
func testDownloadingImageWhenLowQualityDownloadFailsFirst() async throws {
    try await withProbing {
        viewModel.downloadImage()
    } dispatchedBy: { dispatcher in
        #expect(viewModel.downloadState == nil)

        try await dispatcher.runUntilExitOfBody()
        #expect(viewModel.downloadState?.isDownloading == true)

        downloader.shouldFailDownload = true
        try await dispatcher.runUntilEffectCompleted("low")
        #expect(viewModel.downloadState?.isDownloading == true)

        downloader.shouldFailDownload = false
        try await dispatcher.runUntilEffectCompleted("high")
        #expect(viewModel.downloadState?.quality == .high)
    }
}

@Test
func testDownloadingImageWhenHighQualityDownloadFailsFirst() async throws { 
    // ... 
}

@Test
func testDownloadingImageWhenLowQualityDownloadFailsAfterHighQualityDownloadSucceeds() async throws {
    try await withProbing {
        viewModel.downloadImage()
    } dispatchedBy: { dispatcher in
        #expect(viewModel.downloadState == nil)

        try await dispatcher.runUntilExitOfBody()
        #expect(viewModel.downloadState?.isDownloading == true)

        try await dispatcher.runUntilEffectCompleted("high")
        #expect(viewModel.downloadState?.quality == .high)

        downloader.shouldFailDownload = true
        try await dispatcher.runUntilEffectCompleted("low")
        try dispatcher.getCancelledValue(fromEffect: "low", as: Void.self)
        #expect(viewModel.downloadState?.quality == .high)
    }
}

@Test
func testDownloadingImageWhenHighQualityDownloadFailsAfterLowQualityDownloadSucceeds() async throws { 
    // ... 
}

@Test
func testDownloadingImageRepeatedly() async throws {
    try await withProbing {
        viewModel.downloadImage()
        viewModel.downloadImage()
    } dispatchedBy: { dispatcher in
        #expect(viewModel.downloadState == nil)

        try await dispatcher.runUntilExitOfBody()
        #expect(viewModel.downloadState?.isDownloading == true)

        try await dispatcher.runUntilEffectCompleted("low0")
        try dispatcher.getCancelledValue(fromEffect: "low0", as: Void.self)
        #expect(viewModel.downloadState?.isDownloading == true)

        try await dispatcher.runUntilEffectCompleted("high0")
        try dispatcher.getCancelledValue(fromEffect: "high0", as: Void.self)
        #expect(viewModel.downloadState?.isDownloading == true)

        try await dispatcher.runUntilEffectCompleted("low1")
        #expect(viewModel.downloadState?.quality == .low)

        try await dispatcher.runUntilEffectCompleted("high1")
        #expect(viewModel.downloadState?.quality == .high)
    }
}

// ...
```

It’s up to you to decide how much granularity your tests require, yet with `ProbeTesting` 
you have full control over execution flow.
