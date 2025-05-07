//
//  ProbingDispatcher.swift
//  Probing
//
//  Created by Kamil Strzelecki on 05/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Probing
import Testing

public struct ProbingDispatcher: ~Escapable, Sendable {

    private let coordinator: ProbingCoordinator

    init(coordinator: inout ProbingCoordinator) {
        // @lifetime(immortal)
        // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0446-non-escapable.md
        // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0465-nonescapable-stdlib-primitives.md
        self.coordinator = coordinator
    }
}

extension ProbingDispatcher {

    public typealias Injection<R> = @Sendable () async throws -> sending R

    private func withIssueRecording<R>(
        at sourceLocation: SourceLocation,
        isolation: isolated (any Actor)?,
        perform dispatch: @escaping (() -> Void) async throws -> Void,
        after injection: @escaping Injection<R>
    ) async throws -> sending R {
        // https://github.com/swiftlang/swift/issues/77301
        // When `isolation` is nil `injection` must be `@Sendable`

        let signal = AsyncSignal()
        var result: R?

        let injectionTask = Task {
            _ = isolation
            await signal.wait()
            await Task.yield()

            guard !Task.isCancelled else {
                return
            }

            result = try await injection()
        }

        let dispatchTask = Task {
            do {
                _ = isolation
                try await dispatch {
                    signal.finish()
                }
            } catch {
                injectionTask.cancel()
                signal.finish()
                throw RecordedError(
                    underlying: error,
                    sourceLocation: sourceLocation
                )
            }
        }

        defer {
            injectionTask.cancel()
            dispatchTask.cancel()
        }

        try await injectionTask.value
        try await dispatchTask.value
        try Task.checkCancellation()

        guard let result else {
            preconditionFailure("Injection task did not produce any result.")
        }

        return result
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

    public func runUpToProbe<R>(
        _ id: ProbeIdentifier,
        sourceLocation: SourceLocation = #_sourceLocation,
        isolation: isolated (any Actor)? = #isolation,
        @_inheritActorContext @_implicitSelfCapture after injection: @escaping Injection<R> = {}
    ) async throws -> sending R {
        try await withIssueRecording(
            at: sourceLocation,
            isolation: isolation,
            perform: { [coordinator] startOperation in
                try await coordinator.runUntilProbeInstalled(
                    withID: id,
                    isolation: isolation,
                    after: startOperation
                )
            },
            after: injection
        )
    }

    public func runUpToProbe<R>(
        inEffect effectID: EffectIdentifier,
        sourceLocation: SourceLocation = #_sourceLocation,
        isolation: isolated (any Actor)? = #isolation,
        @_inheritActorContext @_implicitSelfCapture after injection: @escaping Injection<R> = {}
    ) async throws -> sending R {
        try await runUpToProbe(
            .init(effect: effectID, name: .default),
            sourceLocation: sourceLocation,
            isolation: isolation,
            after: injection
        )
    }

    public func runUpToProbe<R>(
        sourceLocation: SourceLocation = #_sourceLocation,
        isolation: isolated (any Actor)? = #isolation,
        @_inheritActorContext @_implicitSelfCapture after injection: @escaping Injection<R> = {}
    ) async throws -> sending R {
        try await runUpToProbe(
            inEffect: .root,
            sourceLocation: sourceLocation,
            isolation: isolation,
            after: injection
        )
    }

    // swiftlint:enable no_empty_block
}

extension ProbingDispatcher {

    // swiftlint:disable no_empty_block

    public func runUntilEffectCompleted<R>(
        _ id: EffectIdentifier,
        includingDescendants includeDescendants: Bool = false,
        sourceLocation: SourceLocation = #_sourceLocation,
        isolation: isolated (any Actor)? = #isolation,
        @_inheritActorContext @_implicitSelfCapture after injection: @escaping Injection<R> = {}
    ) async throws -> sending R {
        try await withIssueRecording(
            at: sourceLocation,
            isolation: isolation,
            perform: { [coordinator] startOperation in
                try await coordinator.runUntilEffectCompleted(
                    withID: id,
                    includingDescendants: includeDescendants,
                    isolation: isolation,
                    after: startOperation
                )
            },
            after: injection
        )
    }

    public func runUntilEverythingCompleted<R>(
        sourceLocation: SourceLocation = #_sourceLocation,
        isolation: isolated (any Actor)? = #isolation,
        @_inheritActorContext @_implicitSelfCapture after injection: @escaping Injection<R> = {}
    ) async throws -> sending R {
        try await runUntilEffectCompleted(
            .root,
            includingDescendants: true,
            sourceLocation: sourceLocation,
            isolation: isolation,
            after: injection
        )
    }

    public func runUntilExitOfBody<R>(
        sourceLocation: SourceLocation = #_sourceLocation,
        isolation: isolated (any Actor)? = #isolation,
        @_inheritActorContext @_implicitSelfCapture after injection: @escaping Injection<R> = {}
    ) async throws -> sending R {
        try await runUntilEffectCompleted(
            .root,
            includingDescendants: false,
            sourceLocation: sourceLocation,
            isolation: isolation,
            after: injection
        )
    }

    // swiftlint:enable no_empty_block
}

extension ProbingDispatcher {

    public func getValue<Success: Sendable>(
        fromEffect id: EffectIdentifier,
        as successType: Success.Type = Success.self,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> Success {
        precondition(
            id != .root,
            "To get value from the root effect use result from withProbing function."
        )
        return try withIssueRecording(at: sourceLocation) {
            try coordinator.getValue(fromEffectWithID: id, as: successType)
        }
    }

    public func getCancelledValue<Success: Sendable>(
        fromEffect id: EffectIdentifier,
        as successType: Success.Type = Success.self,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> Success {
        precondition(
            id != .root,
            "Root effect does not support cancellation."
        )
        return try withIssueRecording(at: sourceLocation) {
            try coordinator.getCancelledValue(fromEffectWithID: id, as: successType)
        }
    }
}
