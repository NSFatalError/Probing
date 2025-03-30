//
//  ProbingDispatcher.swift
//  Probing
//
//  Created by Kamil Strzelecki on 05/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Principle
import Probing
import Testing

public struct ProbingDispatcher: Sendable {

    private let coordinator: ProbingCoordinator

    init(coordinator: ProbingCoordinator) {
        self.coordinator = coordinator
    }
}

extension ProbingDispatcher {

    private func withIssueRecording<R: Sendable>(
        at sourceLocation: SourceLocation,
        isolation: isolated (any Actor)?,
        perform dispatch: () async throws -> Void,
        after operation: () async throws -> R
    ) async throws -> R {
        try await withoutActuallyEscaping(operation) { operation in
            let task = Task {
                _ = isolation
                try Task.checkCancellation()
                return try await operation()
            }

            do {
                _ = isolation
                try await dispatch()
                return try await task.value
            } catch {
                task.cancel()
                throw RecordedError(
                    underlying: error,
                    sourceLocation: sourceLocation
                )
            }
        }
    }

    private func withIssueRecording<R>(
        at sourceLocation: SourceLocation,
        perform block: () throws -> R
    ) rethrows -> R {
        do {
            return try block()
        } catch {
            throw RecordedError(
                underlying: error,
                sourceLocation: sourceLocation
            )
        }
    }
}

extension ProbingDispatcher {

    // swiftlint:disable no_empty_block

    public func run<R: Sendable>(
        upTo id: ProbeIdentifier,
        sourceLocation: SourceLocation = #_sourceLocation,
        isolation: isolated (any Actor)? = #isolation,
        after operation: () async throws -> R = {}
    ) async throws -> R {
        try await withIssueRecording(
            at: sourceLocation,
            isolation: isolation,
            perform: {
                try await coordinator.runUntilProbeInstalled(
                    withID: id,
                    isolation: isolation
                )
            },
            after: operation
        )
    }

    public func runUntilCompletion<R: Sendable>(
        of id: EffectIdentifier,
        includingDescendants includeDescendants: Bool = false,
        sourceLocation: SourceLocation = #_sourceLocation,
        isolation: isolated (any Actor)? = #isolation,
        after operation: () async throws -> R = {}
    ) async throws -> R {
        try await withIssueRecording(
            at: sourceLocation,
            isolation: isolation,
            perform: {
                try await coordinator.runUntilEffectCompleted(
                    withID: id,
                    includingDescendants: includeDescendants,
                    isolation: isolation
                )
            },
            after: operation
        )
    }

    public func runUntilEverythingCompleted<R: Sendable>(
        sourceLocation: SourceLocation = #_sourceLocation,
        isolation: isolated (any Actor)? = #isolation,
        after operation: () async throws -> R = {}
    ) async throws -> R {
        try await withIssueRecording(
            at: sourceLocation,
            isolation: isolation,
            perform: {
                try await coordinator.runUntilEffectCompleted(
                    withID: .root,
                    includingDescendants: true,
                    isolation: isolation
                )
            },
            after: operation
        )
    }

    public func runUntilExitOfBody<R: Sendable>(
        sourceLocation: SourceLocation = #_sourceLocation,
        isolation: isolated (any Actor)? = #isolation,
        after operation: () async throws -> R = {}
    ) async throws -> R {
        try await withIssueRecording(
            at: sourceLocation,
            isolation: isolation,
            perform: {
                try await coordinator.runUntilEffectCompleted(
                    withID: .root,
                    includingDescendants: false,
                    isolation: isolation
                )
            },
            after: operation
        )
    }

    // swiftlint:enable no_empty_block
}

extension ProbingDispatcher {

    public func getValue<Success: Sendable>(
        ofEffect id: EffectIdentifier,
        as successType: Success.Type,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> Success {
        try withIssueRecording(at: sourceLocation) {
            try coordinator.getValue(ofEffectWithID: id, at: successType)
        }
    }

    public func getCancelledValue<Success: Sendable>(
        ofEffect id: EffectIdentifier,
        as successType: Success.Type,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> Success {
        try withIssueRecording(at: sourceLocation) {
            try coordinator.getCancelledValue(ofEffectWithID: id, at: successType)
        }
    }
}
