//
//  WithProbing.swift
//  Probing
//
//  Created by Kamil Strzelecki on 05/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Probing
import Testing

public func withProbing<R>(
    options: ProbingOptions = .ignoreProbingInTasks,
    sourceLocation: SourceLocation = #_sourceLocation,
    isolation: isolated (any Actor)? = #isolation,
    @_implicitSelfCapture of runtime: @escaping () async throws -> sending R,
    @_implicitSelfCapture dispatchedBy test: @escaping (ProbingDispatcher) async throws -> Void
) async throws -> sending R {
    // https://github.com/swiftlang/swift/issues/77301
    // nonisolated(unsafe) let runtime = runtime
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
    let runtimeTask = Task {
        result = try await ProbingCoordinator.$current.withValue(
            coordinator,
            operation: {
                try await runRootEffect(
                    using: runtime,
                    testTask: testTask,
                    coordinator: coordinator,
                    isolation: isolation
                )
            },
            isolation: isolation
        )
    }

    defer {
        testTask.cancel()
        runtimeTask.cancel()
    }

    do {
        try await testTask.value
        try await runtimeTask.value
    } catch {
        if testTask.isCancelled {
            try await runtimeTask.value
        }
        throw error
    }

    guard let result else {
        preconditionFailure("Runtime task did not produce any result.")
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
        } catch {
            throw RecordedError(
                underlying: error,
                sourceLocation: sourceLocation
            )
        }
    }
}

private func runRootEffect<R>(
    using runtime: @escaping () async throws -> sending R,
    testTask: Task<Void, any Error>,
    coordinator: ProbingCoordinator,
    isolation: isolated (any Actor)?
) async throws -> sending R {
    do {
        _ = isolation
        await coordinator.willStartRootEffect(isolation: isolation)
        let result = try await runtime()
        coordinator.didCompleteRootEffect()
        return result
    } catch {
        testTask.cancel()
        coordinator.didCompleteRootEffect()
        throw error
    }
}
