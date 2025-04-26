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
    isolation: isolated (any Actor)? = #isolation,
    @_implicitSelfCapture of body: @escaping () async throws -> sending R,
    @_implicitSelfCapture dispatchedBy test: @escaping (ProbingDispatcher) async throws -> sending Void
) async throws -> R {
    let test = uncheckedSendable(test)
    let body = uncheckedSendable(body)

    return try await ProbingCoordinator.run(
        isolation: isolation,
        fileID: sourceLocation.fileID,
        line: sourceLocation.line,
        column: sourceLocation.column,
        body: { coordinator in
            let testTask = Task {
                do {
                    _ = isolation
                    let dispatcher = ProbingDispatcher(coordinator: coordinator)
                    await coordinator.willStartTest(isolation: isolation)
                    try await test.perform(dispatcher)
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

            let result: R

            do {
                _ = isolation
                await coordinator.willStartRootEffect(isolation: isolation)
                defer { coordinator.didCompleteRootEffect() }
                result = try await body.perform()
            }

            _ = try await testTask.value
            return result
        }
    )
}
