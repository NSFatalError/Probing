//
//  Effect.swift
//  Probing
//
//  Created by Kamil Strzelecki on 01/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@discardableResult
@freestanding(expression)
public macro Effect<Success: Sendable>(
    _ name: @autoclosure () -> EffectName,
    preprocessorFlag: StaticString = "DEBUG",
    priority: TaskPriority? = nil,
    @_inheritActorContext @_implicitSelfCapture operation: sending @escaping @isolated(any) () async -> Success
) -> any Effect<Success> = #externalMacro(
    module: "ProbingMacros",
    type: "EffectMacro"
)

@discardableResult
@freestanding(expression)
public macro Effect<Success: Sendable>(
    _ name: @autoclosure () -> EffectName,
    preprocessorFlag: StaticString = "DEBUG", // swiftformat:disable:next all
    executorPreference taskExecutor: consuming (any TaskExecutor)?,
    priority: TaskPriority? = nil,
    operation: sending @escaping () async -> Success
) -> any Effect<Success> = #externalMacro(
    module: "ProbingMacros",
    type: "EffectMacro"
)

@discardableResult
@freestanding(expression)
public macro ConcurrentEffect<Success: Sendable>(
    _ name: @autoclosure () -> EffectName,
    preprocessorFlag: StaticString = "DEBUG",
    priority: TaskPriority? = nil,
    operation: sending @escaping () async -> Success
) -> any Effect<Success> = #externalMacro(
    module: "ProbingMacros",
    type: "EffectMacro"
)

public protocol Effect<Success>: Sendable {

    associatedtype Success: Sendable

    var task: Task<Success, Never> { get }
    var value: Success { get async }
    var isCancelled: Bool { get }

    func cancel()
}

extension Effect {

    public var value: Success {
        get async {
            await task.value
        }
    }

    public var isCancelled: Bool {
        task.isCancelled
    }

    public func cancel() {
        task.cancel()
    }
}

extension Task: Effect where Failure == Never {

    public var task: Task<Success, Never> {
        self
    }
}

extension Never: Effect {

    public var task: Task<Void, Never> {
        fatalError("Never instance cannot be constructed.")
    }
}
