//
//  TestableEffect.swift
//  Probing
//
//  Created by Kamil Strzelecki on 07/03/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import PrincipleConcurrency

@_documentation(visibility: private)
public struct TestableEffect<Success: Sendable>: Effect, Hashable {

    public let task: Task<Success, Never>

    private init(task: Task<Success, Never>) {
        self.task = task
    }

    @discardableResult
    public static func _make( // swiftlint:disable:this identifier_name
        _ name: EffectName,
        priority: TaskPriority?,
        fileID: String = #fileID,
        line: Int = #line,
        column: Int = #column,
        @_inheritActorContext @_implicitSelfCapture operation: sending @escaping @isolated(any) () async -> Success
    ) -> Self {
        guard let coordinator = ProbingCoordinator.current else {
            return .init(
                task: Task(
                    name: name.rawValue,
                    priority: priority,
                    operation: operation
                )
            )
        }

        let isolation = extractIsolation(operation)
        let id = EffectIdentifier.current(appending: name)
        var transfer = SingleUseTransfer(operation)
        let location = ProbingLocation(
            fileID: fileID,
            line: line,
            column: column
        )

        guard coordinator.willCreateEffect(withID: id, at: location) else {
            return .init(
                task: Task(
                    name: name.rawValue,
                    priority: priority,
                    operation: transfer.finalize()
                )
            )
        }

        let task = EffectIdentifier.withChild(id) {
            var transfer = transfer.take()

            return Task(name: name.rawValue, priority: priority) {
                // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0461-async-function-isolation.md
                // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0472-task-start-synchronously-on-caller-context.md
                // https://forums.swift.org/t/closure-isolation-control/70378
                // This closure would preferably be isolated to `isolation`

                await coordinator.willStartEffect(withID: id, isolation: isolation)
                let value = await transfer.finalize()()

                defer {
                    coordinator.didCompleteEffect(
                        withID: id,
                        returning: value,
                        wasCancelled: Task.isCancelled
                    )
                }

                return value
            }
        }

        return .init(task: task)
    }

    @discardableResult
    public static func _make( // swiftlint:disable:this identifier_name
        _ name: EffectName,
        executorPreference taskExecutor: (any TaskExecutor)?,
        priority: TaskPriority?,
        fileID: String = #fileID,
        line: Int = #line,
        column: Int = #column,
        operation: sending @escaping () async -> Success
    ) -> Self {
        guard let coordinator = ProbingCoordinator.current else {
            return .init(
                task: Task(
                    name: name.rawValue,
                    executorPreference: taskExecutor,
                    priority: priority,
                    operation: operation
                )
            )
        }

        let id = EffectIdentifier.current(appending: name)
        var transfer = SingleUseTransfer(operation)
        let location = ProbingLocation(
            fileID: fileID,
            line: line,
            column: column
        )

        guard coordinator.willCreateEffect(withID: id, at: location) else {
            return .init(
                task: Task(
                    name: name.rawValue,
                    executorPreference: taskExecutor,
                    priority: priority,
                    operation: transfer.finalize()
                )
            )
        }

        let task = EffectIdentifier.withChild(id) { [taskExecutor] in
            var transfer = transfer.take()

            return Task(name: name.rawValue, executorPreference: taskExecutor, priority: priority) {
                await coordinator.willStartEffect(withID: id, isolation: nil)
                let value = await transfer.finalize()()

                defer {
                    coordinator.didCompleteEffect(
                        withID: id,
                        returning: value,
                        wasCancelled: Task.isCancelled
                    )
                }

                return value
            }
        }

        return .init(task: task)
    }
}

extension TestableEffect {

    private static func extractIsolation(
        _ operation: @escaping @isolated(any) () async throws -> Success
    ) -> (any Actor)? {
        operation.isolation
    }
}

extension Task
where Failure == Never {

    @discardableResult
    public init(
        name: EffectName,
        priority: TaskPriority? = nil,
        @_inheritActorContext @_implicitSelfCapture operation: sending @escaping @isolated(any) () async -> Success
    ) {
        self.init(
            name: name.rawValue,
            priority: priority,
            operation: operation
        )
    }

    @discardableResult
    public init(
        name: EffectName,
        executorPreference taskExecutor: (any TaskExecutor)?,
        priority: TaskPriority? = nil,
        operation: sending @escaping () async -> Success
    ) {
        self.init(
            name: name.rawValue,
            executorPreference: taskExecutor,
            priority: priority,
            operation: operation
        )
    }
}
