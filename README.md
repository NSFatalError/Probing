<p align="center">
    <img src="Images/Probing.png" height="220" />
</p>

<h1 align="center">Probing</h1>
<p align="center">Breakpoints for Swift Testing - precise control over side effects and execution suspension at any point.</p>

<p align="center">
    <a href="https://swiftpackageindex.com/NSFatalError/Probing">
        <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNSFatalError%2FProbing%2Fbadge%3Ftype%3Dswift-versions" />
    </a>
    <a href="https://swiftpackageindex.com/NSFatalError/Probing">
        <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNSFatalError%2FProbing%2Fbadge%3Ftype%3Dplatforms" />
    </a>
    <a href="https://codecov.io/gh/NSFatalError/Probing">
        <img src="https://codecov.io/gh/NSFatalError/Probing/graph/badge.svg?token=CDPR2O8BZO" />
    </a>
</p>

---

#### Contents
- [What Problem Probing Solves?](#what-problem-probing-solves)
- [How Probing Works?](#how-probing-works)
- [Documentation & Sample Project](#documentation--sample-project)
- [Installation](#installation)

## What Problem Probing Solves?

Testing asynchronous code remains challenging, even with Swift Concurrency and Swift Testing. 
Some of the persistent difficulties include:

- **Unobservable state transitions**: When invoking methods on objects, often with complex dependencies between them, it’s not enough 
to inspect just the final output of the function. Inspecting the internal state changes during execution, such as loading states in view models, 
is equally important but notoriously difficult.
- **Non-determinism**: `Task` instances run concurrently and may complete in different orders each time, leading to unpredictable states. 
Even with full code coverage, there’s no guarantee that all execution paths have been reached, and it's' difficult to reason about what remains untested.
- **Limited runtime control**: Once an asynchronous function is running, influencing its behavior becomes nearly impossible. 
This limitation pushes developers to rely on ahead-of-time setups, like intricate mocks, which add complexity and reduce clarity of the test.

Over the years, the Swift community has introduced a number of tools to address these challenges, each with its own strengths:

- **Quick/Nimble**: Polling with the designated matchers allows checking changes to object state, 
but it can lead to flaky tests and is generally not concurrency-safe.
- **Combine/RxSwift**: Reactive paradigms are powerful, but they can be difficult to set up and may introduce unnecessary abstraction, 
especially now that `AsyncSequence` covers many use cases natively.
- **ComposableArchitecture**: Provides a robust approach for testing UI logic, but it’s tightly coupled 
to its own architectural patterns and isn’t suited for other application layers.

These tools have pushed the ecosystem forward and work well within their intended contexts. 
Still, none provide a lightweight, general-purpose way to tackle all of the listed problems that embraces the Swift Concurrency model.
That's why I have designed and developed `Probing`.

## How Probing Works?

The `Probing` package consists of two main modules:
- `Probing`, which you add as a dependency to the targets you want to test
- `ProbeTesting`, which you add as a dependency to your test targets

With `Probing`, you can define **probes** - suspension points typically placed after a state change,
conceptually similar to breakpoints, but accessible and targetable from your tests.
You can also define **effects**, which make `Task` instances controllable and predictable.

Then, with the help of `ProbeTesting`, you write a sequence of **dispatches** that advance your program to a desired state. 
This flattens the execution hierarchy of side effects, allowing you to write tests from the user’s perspective,
as a clear and deterministic flow of events:

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

`ProbeTesting` also includes robust error handling. It provides recovery suggestions for every error it throws, 
guiding you toward a solution and making it easier to get started with the API.

## Documentation & Sample Project

Full documentation is available on the Swift Package Index:
- [Probing](https://swiftpackageindex.com/NSFatalError/Probing/documentation/probing)
- [ProbeTesting](https://swiftpackageindex.com/NSFatalError/Probing/documentation/probetesting)

You can download the `ProbingPlayground` sample project from its [GitHub page](https://github.com/NSFatalError/ProbingPlayground).

## Installation

To use `Probing`, declare it as a dependency in your `Package.swift` or via Xcode project settings.
Add a dependency on `Probing` in the targets you want to test, and `ProbeTesting` in your test targets:

```swift
let package = Package(
    name: "MyPackage",
    dependencies: [
        .package(
            url: "https://github.com/NSFatalError/Probing",
            from: "1.0.0"
        )
    ],
    targets: [
        .target(
            name: "MyModule",
            dependencies: [
                .product(name: "Probing", package: "Probing")
            ]
        ),
        .testTarget(
            name: "MyModuleTests",
            dependencies: [
                "MyModule",
                .product(name: "ProbeTesting", package: "Probing")
            ]
        )
    ]
)
```

Supported platforms:
- macOS 15.0 or later
- iOS 18.0 or later
- tvOS 18.0 or later
- watchOS 11.0 or later
- visionOS 2.0 or later

Other requirements:
- Swift 6.1 or later
- Xcode 16.3 or later
