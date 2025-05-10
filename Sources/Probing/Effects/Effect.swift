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

/// An interface shared by `Task` and types used by `Probing` to represent units of asynchronous work.
///
/// You do not need to conform your own types to this protocol.
/// Types conforming to `Effect` are returned from effect macros such as ``Effect(_:preprocessorFlag:priority:operation:)``.
///
/// Unlike `Task`, the `Effect` protocol does not currently support throwing errors.
/// Any error handling should be performed inside the operation executed by the effect itself.
///
public protocol Effect<Success>: Sendable {

    /// The type of value returned by the effect.
    ///
    associatedtype Success: Sendable

    /// The underlying `Task` that performs the effect’s work.
    ///
    var task: Task<Success, Never> { get }

    /// The result from an effect, after it completes.
    ///
    var value: Success { get async }

    /// Indicates whether the effect has been cancelled.
    ///
    var isCancelled: Bool { get }

    /// Cancels the effect.
    ///
    /// If the effect was cancelled after completing successfully, `Probing` considers it finished, not cancelled.
    ///
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
