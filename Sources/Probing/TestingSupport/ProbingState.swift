//
//  ProbingState.swift
//  Probing
//
//  Created by Kamil Strzelecki on 09/03/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Synchronization

internal struct ProbingState {

    let options: _ProbingOptions
    let rootEffect: EffectState

    private(set) var testPhase = TestPhase.scheduled
    private(set) var taskIDs = Set<Int>()
    private(set) var errors = [any Error]()

    var isTracking: Bool {
        !testPhase.isCompleted && errors.isEmpty
    }

    init(
        options: _ProbingOptions,
        rootEffectLocation: ProbingLocation
    ) {
        self.options = options
        self.rootEffect = .root(location: rootEffectLocation)
    }
}

extension ProbingState {

    mutating func pauseTest(using continuation: TestContinuation) {
        testPhase = .paused(continuation)
    }

    mutating func resumeTestIfPossible(throwing error: (any Error)?) {
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

        do {
            try unblockRootEffect()
            testPhase = .passed
        } catch {
            testPhase = .failed(error)
            throw error
        }
    }

    private mutating func failTest(with error: any Error) {
        testPhase = .failed(error)
        try? unblockRootEffect()
    }

    private func unblockRootEffect() throws {
        try rootEffect.runUntilEffectCompleted(
            withID: .root,
            includingDescendants: true
        )
    }
}

extension ProbingState {

    mutating func registerCurrentTaskIfNeeded() {
        guard options.contains(.ignoreProbingInTasks),
              let taskID = Task.id
        else {
            return
        }
        let result = taskIDs.insert(taskID)
        precondition(result.inserted, "Task was already registered.")
    }

    mutating func unregisterCurrentTaskIfNeeded() {
        guard options.contains(.ignoreProbingInTasks),
              let taskID = Task.id
        else {
            return
        }
        let result = taskIDs.remove(taskID)
        precondition(result != nil, "Task was never registered.")
    }

    func shouldProbeCurrentTask() -> Bool {
        guard options.contains(.ignoreProbingInTasks) else {
            return true
        }
        guard let taskID = Task.id else {
            return false
        }
        return taskIDs.contains(taskID)
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
}

extension ProbingState {

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

    func preconditionTestPhase(_ precondition: TestPhase.Precondition) {
        preconditionTestPhase(
            precondition.condition,
            file: precondition.file,
            line: precondition.line
        )
    }
}

extension Mutex<ProbingState> {

    func resumeTestIfPossible(
        after operation: (inout sending ProbingState) throws -> Void
    ) {
        withLock { state in
            // https://github.com/swiftlang/swift/issues/80489
            // https://github.com/swiftlang/swift/issues/80490
            // https://forums.swift.org/t/sending-inout-sending-mutex/76373/15
            nonisolated(unsafe) var mutableState = consume state
            defer { state = mutableState }

            do {
                try operation(&mutableState)
                mutableState.resumeTestIfPossible(throwing: nil)
            } catch {
                mutableState.resumeTestIfPossible(throwing: error)
            }
        }
    }
}
