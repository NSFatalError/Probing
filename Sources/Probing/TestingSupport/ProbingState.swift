//
//  ProbingState.swift
//  Probing
//
//  Created by Kamil Strzelecki on 09/03/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Synchronization

internal struct ProbingState {

    let rootEffect: EffectState
    private(set) var testPhase = TestPhase.scheduled
    private(set) var errors = [Error]()

    var isTracking: Bool {
        !testPhase.isCompleted && errors.isEmpty
    }

    init(rootEffectLocation: ProbingLocation) {
        self.rootEffect = .root(location: rootEffectLocation)
    }
}

extension ProbingState {

    mutating func pauseTest(using continuation: TestContinuation) {
        testPhase = .paused(continuation)
    }

    mutating func resumeTestIfPossible(throwing error: Error?) {
        if let error {
            errors.append(error)
        }

        guard case let .paused(continuation) = testPhase else {
            return
        }

        if let firstError = errors.first {
            continuation.resume(throwing: firstError)
            failTest(with: firstError)
            return
        }

        if rootEffect.tree.isSuspended() {
            continuation.resume()
            testPhase = .running
        }
    }
}

extension ProbingState {

    mutating func passTest() throws {
        if let firstError = errors.first {
            failTest(with: firstError)
            throw firstError
        }

        testPhase = .passed
        completeTest()
    }

    private mutating func failTest(with error: Error) {
        testPhase = .failed(error)
        completeTest()
    }

    private func completeTest() {
        rootEffect.runUntilEffectCompleted(
            withID: .root,
            includingDescendants: true
        )
    }
}

extension ProbingState {

    func childEffect(
        withID id: EffectIdentifier,
        file: StaticString = #file,
        line: UInt = #line
    ) -> EffectState? {
        do {
            return try rootEffect.child(withID: id)
        } catch {
            precondition(
                !errors.isEmpty,
                """
                Child effect with identifier \"\(id)\" should exist \
                or error should have been thrown earlier.
                """,
                file: file,
                line: line
            )
            return nil
        }
    }

    func preconditionTestPhase(
        _ condition: (TestPhase) -> Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        precondition(
            condition(testPhase),
            "Cannot transition from current test phase: \(testPhase).",
            file: file,
            line: line
        )
    }
}

extension Mutex<ProbingState> {

    func resumeTestIfPossible(
        after operation: (inout ProbingState) throws -> Void
    ) {
        withLock { state in
            do {
                try operation(&state)
                state.resumeTestIfPossible(throwing: nil)
            } catch {
                state.resumeTestIfPossible(throwing: error)
            }
        }
    }
}
