//
//  Effect.swift
//  Probing
//
//  Created by Kamil Strzelecki on 01/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

/// Creates a `Task`-like effect that can be controlled from your tests.
///
/// - Parameters:
///   - name: The name of the effect. It must be unique within the scope of its parent while the effect is still running.
///   - preprocessorFlag: A preprocessor flag that determines whether the generated code is included in the compiled binary.
///   Defaults to `DEBUG`.
///   - priority: The priority of the underlying task.
///   - operation: The asynchronous operation to perform.
///
/// - Returns: An instance of type conforming to the ``Effect`` protocol.
///
/// When run in the `body` of `ProbeTesting.withProbing` function, the effect is suspended immediately after initialization,
/// instead of starting execution as `Task` would. Later, it can be resumed and suspended at suspension points declared
/// using the ``probe(_:preprocessorFlag:)`` macro within the `operation`.
///
/// Each effect must be uniquely identified within the scope of its parent by its `name` at every point in its execution.
/// Failure to do so will result in an error during testing. Once an effect completes, its identifier can be reused.
///
/// If your code is compiled with the given `preprocessorFlag`, the effect becomes accessible and controllable from your tests
/// only when created within the `body` of `ProbeTesting.withProbing` function. Outside of that scope, this call initializes
/// a regular Swift `Task` that is not subject to any additional scheduling.
///
/// - Attention: Unlike `Task`, the ``Effect`` protocol does not support throwing errors.
/// Any error handling should be performed inside the operation executed by the effect itself.
/// This design choice helps prevent errors from being unintentionally left unhandled.
///
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

/// Creates a `Task`-like effect that runs on the specified executor and can be controlled from your tests.
///
/// - Parameters:
///   - name: The name of the effect. It must be unique within the scope of its parent while the effect is still running.
///   - preprocessorFlag: A preprocessor flag that determines whether the generated code is included in the compiled binary.
///   Defaults to `DEBUG`.
///   - taskExecutor: The preferred task executor for the underlying task, and any child tasks created by it.
///   - priority: The priority of the underlying task.
///   - operation: The asynchronous operation to perform.
///
/// - Returns: An instance of type conforming to the ``Effect`` protocol.
///
/// When run in the `body` of `ProbeTesting.withProbing` function, the effect is suspended immediately after initialization,
/// instead of starting execution as `Task` would. Later, it can be resumed and suspended at suspension points declared
/// using the ``probe(_:preprocessorFlag:)`` macro within the `operation`.
///
/// Each effect must be uniquely identified within the scope of its parent by its `name` at every point in its execution.
/// Failure to do so will result in an error during testing. Once an effect completes, its identifier can be reused.
///
/// If your code is compiled with the given `preprocessorFlag`, the effect becomes accessible and controllable from your tests
/// only when created within the `body` of `ProbeTesting.withProbing` function. Outside of that scope, this call initializes
/// a regular Swift `Task` that is not subject to any additional scheduling.
///
/// - Attention: Unlike `Task`, the ``Effect`` protocol does not support throwing errors.
/// Any error handling should be performed inside the operation executed by the effect itself.
/// This design choice helps prevent errors from being unintentionally left unhandled.
///
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

/// Creates a `Task`-like effect that runs on the `globalConcurrentExecutor` and can be controlled from your tests.
///
/// - Parameters:
///   - name: The name of the effect. It must be unique within the scope of its parent while the effect is still running.
///   - preprocessorFlag: A preprocessor flag that determines whether the generated code is included in the compiled binary.
///   Defaults to `DEBUG`.
///   - priority: The priority of the underlying task.
///   - operation: The asynchronous operation to perform.
///
/// - Returns: An instance of type conforming to the ``Effect`` protocol.
///
/// - Note: This macro is equivalent to calling ``Effect(_:preprocessorFlag:executorPreference:priority:operation:)`` with `globalConcurrentExecutor`.
/// If you were using `Task.detached`, this may be a viable alternative.
///
/// When run in the `body` of `ProbeTesting.withProbing` function, the effect is suspended immediately after initialization,
/// instead of starting execution as `Task` would. Later, it can be resumed and suspended at suspension points declared
/// using the ``probe(_:preprocessorFlag:)`` macro within the `operation`.
///
/// Each effect must be uniquely identified within the scope of its parent by its `name` at every point in its execution.
/// Failure to do so will result in an error during testing. Once an effect completes, its identifier can be reused.
///
/// If your code is compiled with the given `preprocessorFlag`, the effect becomes accessible and controllable from your tests
/// only when created within the `body` of `ProbeTesting.withProbing` function. Outside of that scope, this call initializes
/// a regular Swift `Task` that is not subject to any additional scheduling.
///
/// - Attention: Unlike `Task`, the ``Effect`` protocol does not support throwing errors.
/// Any error handling should be performed inside the operation executed by the effect itself.
/// This design choice helps prevent errors from being unintentionally left unhandled.
///
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
/// - Attention: Unlike `Task`, the `Effect` protocol does not support throwing errors.
/// Any error handling should be performed inside the operation executed by the effect itself.
/// This design choice helps prevent errors from being unintentionally left unhandled.
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
