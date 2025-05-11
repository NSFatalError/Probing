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
