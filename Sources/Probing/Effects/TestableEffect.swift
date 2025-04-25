//
//  TestableEffect.swift
//  Probing
//
//  Created by Kamil Strzelecki on 07/03/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import PrincipleConcurrency

public struct TestableEffect<Success: Sendable>: Effect, Hashable {

    public let task: Task<Success, Never>

    private init(task: Task<Success, Never>) {
        self.task = task
    }

    @discardableResult
    public static func _make( // swiftlint:disable:this identifier_name
        _ name: @autoclosure () -> EffectName,
        priority: TaskPriority?,
        fileID: String = #fileID,
        line: Int = #line,
        column: Int = #column,
        @_inheritActorContext @_implicitSelfCapture operation: sending @escaping @isolated(any) () async -> Success
    ) -> Self {
        guard let coordinator = ProbingCoordinator.current else {
            return .init(
                task: Task(
                    priority: priority,
                    operation: operation
                )
            )
        }

        let isolation = extractIsolation(operation)
        var transfer = SingleUseTransfer(operation)
        let location = ProbingLocation(
            fileID: fileID,
            line: line,
            column: column
        )

        let task = EffectIdentifier.appending(name()) { id in
            var transfer = transfer.take()
            coordinator.willCreateEffect(
                withID: id,
                at: location
            )

            return Task(priority: priority) {
                // NOTE: #isolation != isolation
                // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0461-async-function-isolation.md
                // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0472-task-start-synchronously-on-caller-context.md
                // https://forums.swift.org/t/closure-isolation-control/70378
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
        _ name: @autoclosure () -> EffectName,
        executorPreference taskExecutor: consuming (any TaskExecutor)?,
        priority: TaskPriority?,
        fileID: String = #fileID,
        line: Int = #line,
        column: Int = #column,
        operation: sending @escaping () async -> Success
    ) -> Self {
        guard let coordinator = ProbingCoordinator.current else {
            return .init(
                task: Task(
                    executorPreference: taskExecutor,
                    priority: priority,
                    operation: operation
                )
            )
        }

        var transfer = SingleUseTransfer(operation)
        let location = ProbingLocation(
            fileID: fileID,
            line: line,
            column: column
        )

        let task = EffectIdentifier.appending(name()) { [taskExecutor] id in
            var transfer = transfer.take()
            coordinator.willCreateEffect(
                withID: id,
                at: location
            )

            return Task(executorPreference: taskExecutor, priority: priority) {
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
