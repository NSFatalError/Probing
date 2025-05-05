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
    at sourceLocation: SourceLocation = #_sourceLocation,
    options: ProbingOptions = .ignoreProbingInTasks,
    isolation: isolated (any Actor)? = #isolation,
    @_implicitSelfCapture of runtime: @escaping () async throws -> sending R,
    @_implicitSelfCapture dispatchedBy test: @escaping (ProbingDispatcher) async throws -> Void
) async throws -> R {
    nonisolated(unsafe) let runtime = runtime
    nonisolated(unsafe) let test = test

    let coordinator = ProbingCoordinator(
        options: options.underlying,
        fileID: sourceLocation.fileID,
        line: sourceLocation.line,
        column: sourceLocation.column
    )

    let testTask = Task {
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

    return try await ProbingCoordinator.$current.withValue(
        coordinator,
        operation: {
            let result: R

            do {
                _ = isolation
                await coordinator.willStartRootEffect(isolation: isolation)
                result = try await runtime()
                coordinator.didCompleteRootEffect()
            } catch {
                testTask.cancel()
                coordinator.didCompleteRootEffect()
                throw error
            }

            _ = try await testTask.value
            return result
        },
        isolation: isolation
    )
}
