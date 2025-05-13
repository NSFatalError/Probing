//
//  ProbingDispatcher.swift
//  Probing
//
//  Created by Kamil Strzelecki on 05/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Probing
import Testing

/// Object that controls execution of the `body` during a test.
///
/// You don't create instances of `ProbingDispatcher` directly.
/// Instead, an instance is provided to you within the `test` closure of ``withProbing(options:sourceLocation:isolation:of:dispatchedBy:)``.
///
/// `ProbingDispatcher` always performs the minimal necessary work to drive execution toward a desired state.
/// After calling one of its methods, it eagerly suspends the `body` and any effects it created by its invocation at two points:
/// - Explicitly, at declared `#probe()` macros within the `body` and nested effects
/// - Implicitly, immediately after initializing effects with `#Effect` macros, preventing them from starting until required
///
/// This ensures that no part of the tested code runs concurrently with the expectations defined in the `test`,
/// as long as your code uses `#Effect` macros instead of the `Task` APIs.
///
/// - SeeAlso: For details on how probe and effect identifiers are constructed, see the `Probing` documentation.
///
public struct ProbingDispatcher: ~Escapable, Sendable {

    private let coordinator: ProbingCoordinator

    init(coordinator: inout ProbingCoordinator) {
        // @lifetime(immortal)
        // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0446-non-escapable.md
        // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0465-nonescapable-stdlib-primitives.md
        self.coordinator = coordinator
    }
}

extension ProbingDispatcher {

    private func withIssueRecording(
        at sourceLocation: SourceLocation,
        isolation: isolated (any Actor)?,
        perform dispatch: () async throws -> Void
    ) async throws {
        do {
            _ = isolation
            try await dispatch()
        } catch let error as any RecordableProbingError {
            throw RecordedError(
                underlying: error,
                sourceLocation: sourceLocation
            )
        }
        try Task.checkCancellation()
    }

    private func withIssueRecording<R>(
        at sourceLocation: SourceLocation,
        perform block: () throws -> R
    ) rethrows -> R {
        do {
            return try block()
        } catch let error as any RecordableProbingError {
            throw RecordedError(
                underlying: error,
                sourceLocation: sourceLocation
            )
        }
    }
}

extension ProbingDispatcher {

    /// Resumes execution of `body`, performing the minimal necessary work to install the specified probe, and suspends `body` again before returning.
    ///
    /// - Parameter id: Identifier of the probe, which is guaranteed to be installed when this function returns.
    ///
    /// If any effect along the `id.effect.path` has not yet been created, this function resumes its closest ancestor until the required effect is initialized,
    /// suspending that ancestor at the next available probe. Once the parent effect (`id.effect.path.last`) is created , it is resumed and suspended at the first probe matching `id.name`.
    ///
    /// - Throws: If the probe is unreachable, fails to install, or if API misuse is detected, an `Issue` is recorded containing the error and possible recovery suggestions.
    ///
    /// ```swift
    /// try await withProbing {
    ///     await #probe("1") // id: "1"
    ///     print("1")
    ///     #Effect("first") { // <- SUSPENDED
    ///         print("Not called until dispatch is given.")
    ///     }
    ///     #Effect("second") {
    ///         await #probe("1") // id: "second.1"
    ///         print("second.1")
    ///         await #probe("2") // id: "second.2" <- SUSPENDED
    ///         print("Not called until dispatch is given.")
    ///     }
    ///     await #probe("2") // id: "2" <- SUSPENDED
    ///     print("Not called until dispatch is given.")
    /// } dispatchedBy: { dispatcher in
    ///     try await dispatcher.runUpToProbe("second.2")
    ///     // Always prints:
    ///     // 1
    ///     // second.1
    /// }
    /// ```
    ///
    /// - Tip: Conceptually, this algorithm resembles [breadth-first search](https://en.wikipedia.org/wiki/Breadth-first_search),
    /// where effects form the nodes and probes are the leaves of the execution tree.
    ///
    public func runUpToProbe(
        _ id: ProbeIdentifier,
        sourceLocation: SourceLocation = #_sourceLocation,
        isolation: isolated (any Actor)? = #isolation
    ) async throws {
        try await withIssueRecording(
            at: sourceLocation,
            isolation: isolation,
            perform: {
                try await coordinator.runUntilProbeInstalled(
                    withID: id,
                    isolation: isolation
                )
            }
        )
    }

    /// Resumes execution of `body`, performing the minimal necessary work to install a default probe in the specified effect, and suspends `body` again before returning.
    ///
    /// - Parameter effectID: Identifier of the effect in which a default probe is guaranteed to be installed when this function returns.
    ///
    /// - Attention: A **default probe** is a probe created via `#probe()` macro without specifying a name, or via `#probe(.default)`.
    ///
    /// - Note: This function is equivalent to calling ``runUpToProbe(_:sourceLocation:isolation:)`` with `ProbeIdentifier(effect: effectID, name: .default)`
    ///
    /// If any effect along the `effectID.path` has not yet been created, this function resumes its closest ancestor until the required effect is initialized,
    /// suspending that ancestor at the next available probe. Once the parent effect (`effectID.path.last`) is created , it is resumed and suspended at the first probe with `.default` name.
    ///
    /// - Throws: If the probe is unreachable, fails to install, or if API misuse is detected, an `Issue` is recorded containing the error and possible recovery suggestions.
    ///
    /// ```swift
    /// try await withProbing {
    ///     await #probe() // id: "probe"
    ///     print("probe")
    ///     #Effect("first") { // <- SUSPENDED
    ///         print("Not called until dispatch is given.")
    ///     }
    ///     #Effect("second") {
    ///         await #probe("1") // id: "second.1"
    ///         print("second.1")
    ///         await #probe() // id: "second.probe" <- SUSPENDED
    ///         print("Not called until dispatch is given.")
    ///     }
    ///     await #probe() // id: "probe" <- SUSPENDED
    ///     print("Not called until dispatch is given.")
    /// } dispatchedBy: { dispatcher in
    ///     try await dispatcher.runUpToProbe(inEffect: "second")
    ///     // Always prints:
    ///     // probe
    ///     // second.1
    /// }
    /// ```
    ///
    /// - Tip: Conceptually, this algorithm resembles [breadth-first search](https://en.wikipedia.org/wiki/Breadth-first_search),
    /// where effects form the nodes and probes are the leaves of the execution tree.
    ///
    public func runUpToProbe(
        inEffect effectID: EffectIdentifier,
        sourceLocation: SourceLocation = #_sourceLocation,
        isolation: isolated (any Actor)? = #isolation
    ) async throws {
        try await runUpToProbe(
            .init(effect: effectID, name: .default),
            sourceLocation: sourceLocation,
            isolation: isolation
        )
    }

    /// Resumes execution of `body`, performing the minimal necessary work to install a default probe that is not nested in any effect, and suspends `body` again before returning.
    ///
    /// - Attention: A **default probe** is a probe created via `#probe()` macro without specifying a name, or via `#probe(.default)`.
    ///
    /// - Note: This function is equivalent to calling ``runUpToProbe(_:sourceLocation:isolation:)`` with `ProbeIdentifier(effect: .root, name: .default)`
    ///
    /// - Throws: If the probe is unreachable, fails to install, or if API misuse is detected, an `Issue` is recorded containing the error and possible recovery suggestions.
    ///
    /// ```swift
    /// try await withProbing {
    ///     await #probe("1") // id: "1"
    ///     print("1")
    ///     #Effect("first") { // <- SUSPENDED
    ///         print("Not called until dispatch is given.")
    ///     }
    ///     #Effect("second") { // <- SUSPENDED
    ///         await #probe() // id: "second.probe"
    ///         print("Not called until dispatch is given.")
    ///         await #probe() // id: "second.probe"
    ///         print("Not called until dispatch is given.")
    ///     }
    ///     await #probe() // id: "probe" <- SUSPENDED
    ///     print("Not called until dispatch is given.")
    /// } dispatchedBy: { dispatcher in
    ///     try await dispatcher.runUpToProbe()
    ///     // Always prints:
    ///     // 1
    /// }
    /// ```
    ///
    public func runUpToProbe(
        sourceLocation: SourceLocation = #_sourceLocation,
        isolation: isolated (any Actor)? = #isolation
    ) async throws {
        try await runUpToProbe(
            inEffect: .root,
            sourceLocation: sourceLocation,
            isolation: isolation
        )
    }
}

extension ProbingDispatcher {

    /// Resumes execution of `body`, performing the minimal necessary work to complete the specified effect, and suspends `body` again before returning.
    ///
    /// - Parameters:
    ///   - id: Identifier of the effect, which is guaranteed to be completed when this function returns.
    ///   - includeDescendants: If `true`, all descendants of the specified effect will also be completed.
    ///   Defaults to `false`, meaning they will remain suspended in their current state.
    ///
    /// If any effect along the `id.path` has not yet been created, this function resumes its closest ancestor until the required effect is initialized,
    /// suspending that ancestor at the next available probe. Once the specified effect (`id.path.last`) is created , it is resumed and run until completion.
    ///
    /// - Throws: If the effect is unreachable, fails to be created, or if API misuse is detected, an `Issue` is recorded containing the error and possible recovery suggestions.
    ///
    /// ```swift
    /// try await withProbing {
    ///     await #probe("1") // id: "1"
    ///     print("1")
    ///     #Effect("first") { // <- SUSPENDED
    ///         print("Not called until dispatch is given.")
    ///     }
    ///     #Effect("second") {
    ///         await #probe("1") // id: "second.1"
    ///         print("second.1")
    ///         await #probe("2") // id: "second.2"
    ///         print("second.2") // <- COMPLETED
    ///     }
    ///     await #probe("2") // id: "2" <- SUSPENDED
    ///     print("Not called until dispatch is given.")
    /// } dispatchedBy: { dispatcher in
    ///     try await dispatcher.runUntilEffectCompleted("second.2")
    ///     // Always prints:
    ///     // 1
    ///     // second.1
    ///     // second.2
    /// }
    /// ```
    ///
    /// - Tip: Conceptually, this algorithm resembles [breadth-first search](https://en.wikipedia.org/wiki/Breadth-first_search),
    /// where effects form the nodes of the execution tree.
    ///
    public func runUntilEffectCompleted(
        _ id: EffectIdentifier,
        includingDescendants includeDescendants: Bool = false,
        sourceLocation: SourceLocation = #_sourceLocation,
        isolation: isolated (any Actor)? = #isolation
    ) async throws {
        try await withIssueRecording(
            at: sourceLocation,
            isolation: isolation,
            perform: {
                try await coordinator.runUntilEffectCompleted(
                    withID: id,
                    includingDescendants: includeDescendants,
                    isolation: isolation
                )
            }
        )
    }

    /// Resumes execution of `body`, completing all remaining work within it, as well as all effects and their descendants, before returning.
    ///
    /// - Note: This function is equivalent to calling ``runUntilEffectCompleted(_:includingDescendants:sourceLocation:isolation:)``
    /// with `EffectIdentifier.root` and `includeDescendants` set to `true`.
    ///
    /// - Throws: If API misuse is detected, an `Issue` is recorded containing the error and possible recovery suggestions.
    ///
    /// ```swift
    /// try await withProbing {
    ///     await #probe("1") // id: "1"
    ///     print("1")
    ///     #Effect("first") {
    ///         print("first") // <- COMPLETED
    ///     }
    ///     #Effect("second") {
    ///         await #probe("1") // id: "second.1"
    ///         print("second.1")
    ///         await #probe("2") // id: "second.2"
    ///         print("second.2") // <- COMPLETED
    ///     }
    ///     await #probe("2") // id: "2"
    ///     print("2") // <- COMPLETED
    /// } dispatchedBy: { dispatcher in
    ///     try await dispatcher.runUntilEverythingCompleted()
    ///     // Always prints:
    ///     // 1
    ///     // 2
    ///     // first
    ///     // second.1
    ///     // second.2
    ///     // Note: Exact order of prints may vary, as effects may execute concurrently.
    /// }
    /// ```
    ///
    public func runUntilEverythingCompleted(
        sourceLocation: SourceLocation = #_sourceLocation,
        isolation: isolated (any Actor)? = #isolation
    ) async throws {
        try await runUntilEffectCompleted(
            .root,
            includingDescendants: true,
            sourceLocation: sourceLocation,
            isolation: isolation
        )
    }

    /// Resumes execution of `body`, completing all remaining work within it, while leaving effects suspended in their current state, before returning.
    ///
    /// - Note: This function is equivalent to calling ``runUntilEffectCompleted(_:includingDescendants:sourceLocation:isolation:)``
    /// with `EffectIdentifier.root` and `includeDescendants` set to `false`.
    ///
    /// - Throws: If API misuse is detected, an `Issue` is recorded containing the error and possible recovery suggestions.
    ///
    /// ```swift
    /// try await withProbing {
    ///     await #probe("1") // id: "1"
    ///     print("1")
    ///     #Effect("first") { // <- SUSPENDED
    ///         print("Not called until dispatch is given.")
    ///     }
    ///     #Effect("second") { // <- SUSPENDED
    ///         await #probe("1") // id: "second.1"
    ///         print("Not called until dispatch is given.")
    ///         await #probe("2") // id: "second.2"
    ///         print("Not called until dispatch is given.")
    ///     }
    ///     await #probe("2") // id: "2"
    ///     print("2") // <- COMPLETED
    /// } dispatchedBy: { dispatcher in
    ///     try await dispatcher.runUntilExitOfBody()
    ///     // Always prints:
    ///     // 1
    ///     // 2
    /// }
    /// ```
    ///
    public func runUntilExitOfBody(
        sourceLocation: SourceLocation = #_sourceLocation,
        isolation: isolated (any Actor)? = #isolation
    ) async throws {
        try await runUntilEffectCompleted(
            .root,
            includingDescendants: false,
            sourceLocation: sourceLocation,
            isolation: isolation
        )
    }
}

extension ProbingDispatcher {

    /// Retrieves the return value of the specified effect, ensuring it has completed successfully.
    ///
    /// - Parameters:
    ///   - id: Identifier of the effect, which is expected to have completed successfully.
    ///   - successType: The expected type of the value returned by the effect.
    ///
    /// - Returns: The return value of the effect, if it completed successfully.
    ///
    /// - Important: This method does not resume the execution of `body`. You must ensure the effect has finished running through prior dispatches.
    ///
    /// - Throws: If the effect has not been completed successfully yet, was cancelled, or if API misuse is detected, an `Issue` is recorded containing the error and possible recovery suggestions.
    ///
    public func getValue<Success: Sendable>(
        fromEffect id: EffectIdentifier,
        as successType: Success.Type = Success.self,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> Success {
        precondition(
            id != .root,
            "To get value from the root effect use result from withProbing function."
        )
        return try withIssueRecording(at: sourceLocation) {
            try coordinator.getValue(fromEffectWithID: id, as: successType)
        }
    }

    /// Retrieves the return value of the specified effect, ensuring it has been cancelled.
    ///
    /// - Parameters:
    ///   - id: Identifier of the effect, which is expected to have been cancelled.
    ///   - successType: The expected type of the value returned by the effect.
    ///
    /// - Returns: The return value of the effect, if it was cancelled.
    ///
    /// - Important: This method does not resume the execution of `body`. You must ensure the effect has finished running through prior dispatches.
    ///
    /// - Throws: If the effect has not been cancelled yet, was completed successfully, or if API misuse is detected, an `Issue` is recorded containing the error and possible recovery suggestions.
    ///
    public func getCancelledValue<Success: Sendable>(
        fromEffect id: EffectIdentifier,
        as successType: Success.Type = Success.self,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> Success {
        precondition(
            id != .root,
            "Root effect does not support cancellation."
        )
        return try withIssueRecording(at: sourceLocation) {
            try coordinator.getCancelledValue(fromEffectWithID: id, as: successType)
        }
    }
}
