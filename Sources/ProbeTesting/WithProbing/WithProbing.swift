//
//  WithProbing.swift
//  Probing
//
//  Created by Kamil Strzelecki on 05/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Probing
import Testing

/// Enables control over probes and effects, making asynchronous code testable.
///
/// - Parameters:
///   - options: Controls testability of probes and effects created from `Task` APIs.  Defaults to ``ProbingOptions/ignoreProbingInTasks``.
///   - body: A closure containing the code under test. Probes and effects invoked from this closure become controllable in `test`.
///   - test: A closure used to control the execution of `body` via ``ProbingDispatcher``, verify expectations, and interact with the system under test.
///
/// - Throws: Rethrows any error thrown by either the `body` or `test` closure.
///
/// - Returns: The result returned by the `body` closure.
///
/// This function always begins by invoking `test`, suspending execution of `body` until the first dispatch is given.
/// Before returning, it awaits the completion of both `body` and `test`.
///
/// ```swift
/// try await withProbing {
///     print("Body")
/// } dispatchedBy: { dispatcher in
///     // Noting is printed yet at this point
///     print("Test")
/// }
/// // Always prints:
/// // Test
/// // Body
/// ```
///
/// - Note: This does **not** guarantee that all effects created by the `body` invocation are completed when `withProbing` returns.
/// To ensure this, call the ``ProbingDispatcher/runUntilEverythingCompleted(sourceLocation:isolation:)`` method
/// on the dispatcher at the appropriate point within `test`.
///
/// `ProbeTesting` guarantees that as long as your code uses `#Effect` macros instead of the `Task` APIs,
/// no part of code initiated by the `body` invocation will run concurrently with `test`. This is enforced by the ``ProbingDispatcher``,
/// which lets you deterministically advance execution to the desired state. This model allows you to reliably check expectations
/// and interact with the system under test. For example:
///
/// ```swift
/// try await withProbing {
///     await viewModel.load()
/// } dispatchedBy: { dispatcher in
///     #expect(viewModel.isLoading == false)
///     #expect(viewModel.download == nil)
///
///     try await dispatcher.runUpToProbe()
///     #expect(viewModel.isLoading == true)
///     #expect(viewModel.download == nil)
///
///     downloaderMock.shouldFailDownload = false
///     try await dispatcher.runUntilExitOfBody()
///     #expect(viewModel.isLoading == false)
///     #expect(viewModel.download != nil)
///
///     #expect(viewModel.prefetchedData == nil)
///     try await dispatcher.runUntilEffectCompleted("backgroundFetch")
///     #expect(viewModel.prefetchedData != nil)
/// }
/// ```
///
public func withProbing<R>(
    options: ProbingOptions = .ignoreProbingInTasks,
    sourceLocation: SourceLocation = #_sourceLocation,
    isolation: isolated (any Actor)? = #isolation,
    @_implicitSelfCapture of body: @escaping () async throws -> sending R,
    @_implicitSelfCapture dispatchedBy test: @escaping (ProbingDispatcher) async throws -> Void
) async throws -> sending R {
    // https://github.com/swiftlang/swift/issues/77301
    // nonisolated(unsafe) let body = body
    // nonisolated(unsafe) let test = test

    let coordinator = ProbingCoordinator(
        options: options.underlying,
        fileID: sourceLocation.fileID,
        line: sourceLocation.line,
        column: sourceLocation.column
    )

    let testTask = makeTestTask(
        dispatchedBy: test,
        coordinator: coordinator,
        sourceLocation: sourceLocation,
        isolation: isolation
    )

    var result: R?
    let bodyTask = Task {
        result = try await coordinator.withProbing(isolation: isolation) {
            try await runRootEffect(
                using: body,
                testTask: testTask,
                coordinator: coordinator,
                isolation: isolation
            )
        }
    }

    defer {
        testTask.cancel()
        bodyTask.cancel()
    }

    do {
        try await testTask.value
    } catch {
        if testTask.isCancelled {
            try await bodyTask.value
        } else {
            try? await bodyTask.value
        }
        if error is RecordedError {
            throw ProbingTerminatedError()
        } else {
            throw error
        }
    }

    try await bodyTask.value
    guard let result else {
        preconditionFailure("Body task did not produce any result.")
    }

    return result
}

private func makeTestTask(
    dispatchedBy test: @escaping (ProbingDispatcher) async throws -> Void,
    coordinator: ProbingCoordinator,
    sourceLocation: SourceLocation,
    isolation: isolated (any Actor)?
) -> Task<Void, any Error> {
    Task {
        do {
            _ = isolation
            var reference = coordinator
            let dispatcher = ProbingDispatcher(coordinator: &reference)
            await coordinator.willStartTest(isolation: isolation)
            try Task.checkCancellation()
            try await test(dispatcher)
        } catch {
            try? coordinator.didCompleteTest()
            throw error
        }

        do {
            try coordinator.didCompleteTest()
        } catch let error as any RecordableProbingError {
            throw RecordedError(
                underlying: error,
                sourceLocation: sourceLocation
            )
        }
    }
}

private func runRootEffect<R>(
    using body: () async throws -> sending R,
    testTask: Task<Void, any Error>,
    coordinator: ProbingCoordinator,
    isolation: isolated (any Actor)?
) async throws -> sending R {
    do {
        await coordinator.willStartRootEffect(isolation: isolation)
        let result = try await body()
        coordinator.didCompleteRootEffect()
        return result
    } catch {
        testTask.cancel()
        coordinator.didCompleteRootEffect()
        throw error
    }
}
