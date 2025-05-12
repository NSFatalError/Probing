//
//  ProbingCoordinator.swift
//  Probing
//
//  Created by Kamil Strzelecki on 05/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Synchronization

package final class ProbingCoordinator: Sendable {

    let options: _ProbingOptions
    private let state: Mutex<ProbingState>

    package init(
        options: _ProbingOptions,
        fileID: String,
        line: Int,
        column: Int
    ) {
        let initialState = ProbingState(
            options: options,
            rootEffectLocation: ProbingLocation(
                fileID: fileID,
                line: line,
                column: column
            )
        )

        self.options = options
        self.state = .init(initialState)
    }

    deinit {
        state.withLock { state in
            precondition(
                state.testPhase.isCompleted,
                "Test has not been completed before coordinator deallocation."
            )
            precondition(
                state.taskIDs.isEmpty,
                "Some effects did not report completion before coordinator deallocation."
            )
        }
    }
}

// MARK: - Tests

extension ProbingCoordinator {

    @TaskLocal
    private static var _current: ProbingCoordinator?

    static var current: ProbingCoordinator? {
        _current
    }

    package func withProbing<R>(
        isolation: isolated (any Actor)?,
        operation: () async throws -> R
    ) async rethrows -> R {
        nonisolated(unsafe) let operation = operation
        return try await EffectIdentifier.withRoot(isolation: isolation) {
            try await ProbingCoordinator.$_current.withValue(
                self,
                operation: operation,
                isolation: isolation
            )
        }
    }
}

extension ProbingCoordinator {

    private func pauseTest(
        isolation: isolated (any Actor)?,
        phasePrecondition precondition: TestPhase.Precondition,
        awaiting dispatches: (ProbingState) throws -> Void
    ) async throws {
        try await withCheckedThrowingContinuation(isolation: isolation) { continuation in
            state.resumeTestIfPossible { state in
                state.preconditionTestPhase(precondition)
                state.pauseTest(using: continuation)
                try dispatches(state)
            }
        }
    }

    package func willStartTest(
        isolation: isolated (any Actor)?
    ) async {
        do {
            try await pauseTest(
                isolation: isolation,
                phasePrecondition: .init(\.isScheduled),
                awaiting: { _ in } // swiftlint:disable:this no_empty_block
            )
        } catch {
            preconditionFailure("""
            Test should never fail right after root effect is enqueued and suspended.
            """)
        }
    }

    package func didCompleteTest() throws {
        try state.withLock { state in
            guard !state.testPhase.isFailed else {
                return
            }
            state.preconditionTestPhase(\.isRunning)
            try state.passTest()
        }
    }
}

extension ProbingCoordinator {

    package func runUntilProbeInstalled(
        withID id: ProbeIdentifier,
        isolation: isolated (any Actor)?
    ) async throws {
        try await pauseTest(
            isolation: isolation,
            phasePrecondition: .init(\.isRunning),
            awaiting: { state in
                try state.rootEffect.runUntilProbeInstalled(withID: id)
            }
        )
    }

    package func runUntilEffectCompleted(
        withID id: EffectIdentifier,
        includingDescendants includeDescendants: Bool,
        isolation: isolated (any Actor)?
    ) async throws {
        try await pauseTest(
            isolation: isolation,
            phasePrecondition: .init(\.isRunning),
            awaiting: { state in
                try state.rootEffect.runUntilEffectCompleted(
                    withID: id,
                    includingDescendants: includeDescendants
                )
            }
        )
    }

    package func getValue<Success: Sendable>(
        fromEffectWithID id: EffectIdentifier,
        as successType: Success.Type
    ) throws -> Success {
        try state.withLock { state in
            state.preconditionTestPhase(\.isRunning)
            let childEffect = try state.rootEffect.child(withID: id)
            return try childEffect.getValue(as: successType)
        }
    }

    package func getCancelledValue<Success: Sendable>(
        fromEffectWithID id: EffectIdentifier,
        as successType: Success.Type
    ) throws -> Success {
        try state.withLock { state in
            state.preconditionTestPhase(\.isRunning)
            let childEffect = try state.rootEffect.child(withID: id)
            return try childEffect.getCancelledValue(as: successType)
        }
    }
}

// MARK: - Probes

extension ProbingCoordinator {

    func installProbe(
        withName name: ProbeName,
        at location: ProbingLocation,
        isolation: isolated (any Actor)?
    ) async {
        let id = ProbeIdentifier(
            effect: .current,
            name: name
        )

        await withCheckedContinuation(isolation: isolation) { underlying in
            state.resumeTestIfPossible { state in
                let continuation = ProbeContinuation(
                    id: id,
                    location: location,
                    underlying: underlying
                )

                guard state.isTracking,
                      state.shouldProbeCurrentTask(),
                      let childEffect = state.childEffect(withID: id.effect)
                else {
                    continuation.resume()
                    return
                }

                switch childEffect.phase {
                case let .probed(preexisting):
                    continuation.resume()
                    throw ProbingErrors.ProbeAPIMisuse(
                        backtrace: continuation.backtrace,
                        preexisting: preexisting.backtrace
                    )

                default:
                    guard !state.testPhase.isRunning else {
                        continuation.resume()
                        throw ProbingErrors.ProbeAPIMisuse(
                            backtrace: continuation.backtrace,
                            preexisting: nil
                        )
                    }

                    state.preconditionTestPhase(\.isPaused)
                    childEffect.probe(using: continuation)
                }
            }
        }
    }
}

// MARK: - Effects

extension ProbingCoordinator {

    func willCreateEffect(
        withID id: EffectIdentifier,
        at location: ProbingLocation
    ) -> Bool {
        var shouldProbe = true
        let backtrace = EffectBacktrace(
            id: id,
            location: location
        )

        state.resumeTestIfPossible { state in
            guard state.isTracking else {
                return
            }

            guard state.shouldProbeCurrentTask() else {
                shouldProbe = false
                return
            }

            guard !state.testPhase.isRunning else {
                throw ProbingErrors.EffectAPIMisuse(backtrace: backtrace)
            }

            state.preconditionTestPhase(\.isPaused)
            try state.rootEffect.createChild(withBacktrace: backtrace)
        }

        return shouldProbe
    }
}

extension ProbingCoordinator {

    private func willStartEffect(
        withID id: EffectIdentifier,
        isolation: isolated (any Actor)?,
        testPhasePrecondition precondition: TestPhase.Precondition
    ) async {
        await withCheckedContinuation(isolation: isolation) { underlying in
            state.resumeTestIfPossible { state in
                state.registerCurrentTaskIfNeeded()

                guard state.isTracking,
                      let childEffect = state.childEffect(withID: id)
                else {
                    underlying.resume()
                    return
                }

                let continuation = EffectContinuation(
                    id: childEffect.backtrace.id,
                    location: childEffect.backtrace.location,
                    underlying: underlying
                )

                guard !state.testPhase.isRunning else {
                    continuation.resume()
                    throw ProbingErrors.EffectAPIMisuse(backtrace: childEffect.backtrace)
                }

                state.preconditionTestPhase(precondition)
                childEffect.enqueue(using: continuation)
            }
        }
    }

    func willStartEffect(
        withID id: EffectIdentifier,
        isolation: isolated (any Actor)?
    ) async {
        await willStartEffect(
            withID: id,
            isolation: isolation,
            testPhasePrecondition: .init(\.isPaused)
        )
    }

    package func willStartRootEffect(
        isolation: isolated (any Actor)?
    ) async {
        await willStartEffect(
            withID: .root,
            isolation: isolation,
            testPhasePrecondition: .init { testPhase in
                testPhase.isScheduled || testPhase.isPaused
            }
        )
    }
}

extension ProbingCoordinator {

    private func didCompleteEffect(
        withID id: EffectIdentifier,
        returning value: some Sendable,
        wasCancelled: Bool,
        testPhasePrecondition precondition: TestPhase.Precondition
    ) {
        state.resumeTestIfPossible { state in
            state.unregisterCurrentTaskIfNeeded()

            guard state.isTracking,
                  let childEffect = state.childEffect(withID: id)
            else {
                return
            }

            guard !state.testPhase.isRunning else {
                throw ProbingErrors.EffectAPIMisuse(backtrace: childEffect.backtrace)
            }

            state.preconditionTestPhase(precondition)
            try (wasCancelled ? childEffect.cancel : childEffect.finish)(value)
        }
    }

    func didCompleteEffect(
        withID id: EffectIdentifier,
        returning value: some Sendable,
        wasCancelled: Bool
    ) {
        didCompleteEffect(
            withID: id,
            returning: value,
            wasCancelled: wasCancelled,
            testPhasePrecondition: .init(\.isPaused)
        )
    }

    package func didCompleteRootEffect() {
        didCompleteEffect(
            withID: .root,
            returning: (),
            wasCancelled: false,
            testPhasePrecondition: .init(\.isPaused)
        )
    }
}
