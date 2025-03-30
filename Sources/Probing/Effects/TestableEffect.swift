//
//  TestableEffect.swift
//  Probing
//
//  Created by Kamil Strzelecki on 07/03/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Principle

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
        let operation = unsafeSendable(operation)
        let location = ProbingLocation(
            fileID: fileID,
            line: line,
            column: column
        )

        let task = EffectIdentifier.appending(name()) { id in
            coordinator.willCreateEffect(
                withID: id,
                at: location
            )

            return Task(priority: priority) {
                await coordinator.willStartEffect(
                    withID: id,
                    isolation: isolation
                )

                let value = await operation.perform()

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

        let operation = unsafeSendable(operation)
        let location = ProbingLocation(
            fileID: fileID,
            line: line,
            column: column
        )

        let task = EffectIdentifier.appending(name()) { [taskExecutor] id in
            coordinator.willCreateEffect(
                withID: id,
                at: location
            )

            return Task(executorPreference: taskExecutor, priority: priority) {
                await coordinator.willStartEffect(
                    withID: id,
                    isolation: #isolation
                )

                let value = await operation.perform()

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
