//
//  EffectState.swift
//  Probing
//
//  Created by Kamil Strzelecki on 01/03/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

internal final class EffectState {

    let backtrace: EffectBacktrace
    private(set) var phase = EffectPhase.created

    private(set) var dispatch = EffectDispatch.suspendWhenPossible
    private(set) var children = [EffectName: EffectState]()

    var tree: TreeView {
        TreeView(root: self)
    }

    private init(backtrace: EffectBacktrace) {
        self.backtrace = backtrace
    }
}

extension EffectState {

    static func root(location: ProbingLocation) -> EffectState {
        let backtrace = EffectBacktrace(id: .root, location: location)
        return .init(backtrace: backtrace)
    }
}

extension EffectState {

    func getValue<Success: Sendable>(as _: Success.Type) throws -> Success {
        preconditionChild()
        switch phase {
        case let .finished(success as Success):
            return success
        default:
            throw ProbingErrors.FinishedValueNotMatching(
                backtrace: backtrace,
                phase: phase
            )
        }
    }

    func getCancelledValue<Success: Sendable>(as _: Success.Type) throws -> Success {
        preconditionChild()
        switch phase {
        case let .cancelled(success as Success):
            return success
        default:
            throw ProbingErrors.CancelledValueNotMatching(
                backtrace: backtrace,
                phase: phase
            )
        }
    }
}

extension EffectState {

    func child(withID childID: EffectIdentifier) throws -> EffectState {
        preconditionRoot()
        return try child(at: childID.path[...])
    }

    private func child(at path: ArraySlice<EffectName>) throws -> EffectState {
        guard let descendantName = path.first else {
            return self
        }
        guard let descendant = children[descendantName] else {
            throw ProbingErrors.EffectNotFound(
                ancestor: backtrace,
                expectation: EffectIdentifier(
                    path: backtrace.id.path + path
                )
            )
        }
        return try descendant.child(at: path.dropFirst())
    }
}

extension EffectState {

    func createChild(withBacktrace backtrace: EffectBacktrace) throws {
        preconditionRoot()
        let child = EffectState(backtrace: backtrace)
        try insertChild(child, at: backtrace.id.path[...])
    }

    private func insertChild(_ child: EffectState, at path: ArraySlice<EffectName>) throws {
        guard let descendantName = path.first else {
            preconditionFailure("Child effect cannot have identifier with an empty path.")
        }

        if path.count == 1 {
            if let preexisting = children[descendantName],
               !preexisting.tree.isCompleted() {
                throw ProbingErrors.EffectIdentifierAmbiguous(
                    backtrace: child.backtrace,
                    preexisting: (
                        preexisting.backtrace.location,
                        preexisting.phase
                    )
                )
            }

            let childID = child.backtrace.id
            child.dispatch = dispatch.relayToChild(withID: childID)
            children[descendantName] = child

        } else {
            guard let descendant = children[descendantName] else {
                preconditionFailure("""
                Child effect identifier \"\(child.backtrace.id)\" was malformed \
                or descendant with name \"\(descendantName)\" is missing.
                """)
            }

            try descendant.insertChild(
                child,
                at: path.dropFirst()
            )
        }
    }
}

extension EffectState {

    func runUntilProbeInstalled(withID probeID: ProbeIdentifier) throws {
        preconditionRoot()
        try runUntilProbeInstalled(
            withID: probeID,
            path: probeID.effect.path[...]
        )
    }

    private func runUntilProbeInstalled(
        withID probeID: ProbeIdentifier,
        path: ArraySlice<EffectName>
    ) throws {
        if let descendantName = path.first {
            if let descendant = children[descendantName] {
                try descendant.runUntilProbeInstalled(
                    withID: probeID,
                    path: path.dropFirst()
                )
                return
            }

            dispatch = .runUntilChildCreated(
                id: probeID.effect,
                dispatch: .runUntilProbeInstalled(id: probeID)
            )

        } else {
            dispatch = .runUntilProbeInstalled(id: probeID)
        }

        try resumeIfNeeded()
    }

    func runUntilEffectCompleted(
        withID effectID: EffectIdentifier,
        includingDescendants includeDescendants: Bool
    ) throws {
        preconditionRoot()
        try runUntilEffectCompleted(
            withID: effectID,
            path: effectID.path[...],
            includingDescendants: includeDescendants
        )
    }

    private func runUntilEffectCompleted(
        withID effectID: EffectIdentifier,
        path: ArraySlice<EffectName>,
        includingDescendants includeDescendants: Bool
    ) throws {
        if let descendantName = path.first {
            if let descendant = children[descendantName] {
                try descendant.runUntilEffectCompleted(
                    withID: effectID,
                    path: path.dropFirst(),
                    includingDescendants: includeDescendants
                )
                return
            }

            dispatch = .runUntilChildCreated(
                id: effectID,
                dispatch: .runUntilCompleted(
                    includingDescendants: includeDescendants
                )
            )

        } else {
            dispatch = .runUntilCompleted(
                includingDescendants: includeDescendants
            )

            if includeDescendants {
                for child in children.values {
                    try child.runUntilEffectCompleted(
                        withID: effectID,
                        path: path,
                        includingDescendants: true
                    )
                }
            }
        }

        try resumeIfNeeded()
    }
}

extension EffectState {

    private func resumeIfNeeded() throws {
        switch phase {
        case let .enqueued(continuation):
            resumeIfNeeded(using: continuation)
        case let .probed(continuation):
            resumeIfNeeded(using: continuation)
        case .cancelled, .finished:
            try complete()
        case .created, .executing:
            break
        }
    }

    private func resumeIfNeeded(
        using continuation: ProbingContinuation<some ProbingIdentifierProtocol>
    ) {
        switch dispatch {
        case .suspendWhenPossible:
            break
        case .runUntilChildCreated, .runUntilCompleted, .runUntilProbeInstalled:
            continuation.resume()
            phase = .executing
        }
    }
}

extension EffectState {

    func enqueue(using continuation: EffectContinuation) {
        preconditionPhase(\.isCreated)
        switch dispatch {
        case .suspendWhenPossible:
            phase = .enqueued(continuation)
        case .runUntilChildCreated, .runUntilCompleted, .runUntilProbeInstalled:
            phase = .executing
            continuation.resume()
        }
    }

    func probe(using continuation: ProbeContinuation) {
        preconditionPhase(\.isExecuting)
        switch dispatch {
        case .suspendWhenPossible:
            phase = .probed(continuation)
        case let .runUntilProbeInstalled(id) where id == continuation.backtrace.id:
            dispatch = .suspendWhenPossible
            phase = .probed(continuation)
        case .runUntilChildCreated, .runUntilCompleted, .runUntilProbeInstalled:
            continuation.resume()
        }
    }

    func finish(with value: some Sendable) throws {
        preconditionPhase(\.isExecuting)
        phase = .finished(value)
        try complete()
    }

    func cancel(with value: some Sendable) throws {
        preconditionChild()
        preconditionPhase(\.isExecuting)
        phase = .cancelled(value)
        try complete()
    }

    private func complete() throws {
        switch dispatch {
        case .runUntilCompleted, .suspendWhenPossible:
            break

        case let .runUntilChildCreated(id, dispatch):
            throw ProbingErrors.ChildEffectNotCreated(
                backtrace: backtrace,
                expectation: (id, dispatch)
            )

        case let .runUntilProbeInstalled(id):
            throw ProbingErrors.ProbeNotInstalled(
                backtrace: backtrace,
                expectation: id
            )
        }
    }
}

extension EffectState {

    private func preconditionPhase(
        _ condition: (EffectPhase) -> Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        precondition(
            condition(phase),
            "Cannot transition from current phase: \(phase).",
            file: file,
            line: line
        )
    }

    private func preconditionRoot(
        file: StaticString = #file,
        line: UInt = #line
    ) {
        precondition(
            backtrace.id == .root,
            "This method should only be called on root effect.",
            file: file,
            line: line
        )
    }

    private func preconditionChild(
        file: StaticString = #file,
        line: UInt = #line
    ) {
        precondition(
            backtrace.id != .root,
            "This method should only be called on child effect.",
            file: file,
            line: line
        )
    }
}

extension EffectState {

    struct TreeView {

        private let root: EffectState

        fileprivate init(root: EffectState) {
            self.root = root
        }

        func isSuspended() -> Bool {
            root.phase.isSuspended && root.children.values.allSatisfy { child in
                child.tree.isSuspended()
            }
        }

        func isCompleted() -> Bool {
            root.phase.isCompleted && root.children.values.allSatisfy { child in
                child.tree.isCompleted()
            }
        }
    }
}
