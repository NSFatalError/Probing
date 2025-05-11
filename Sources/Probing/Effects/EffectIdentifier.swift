//
//  EffectIdentifier.swift
//  Probing
//
//  Created by Kamil Strzelecki on 21/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Synchronization

/// A unique identifier of an effect at every point in its execution.
///
/// An `EffectIdentifier` consists of the ``EffectName`` components passed to the ``Effect(_:preprocessorFlag:priority:operation:)``
/// macro (and its variants). These names form the identifier's ``path``, which reflects the stack of nested effects during a particular invocation.
///
/// The identifier is represented as a string formed by concatenating these components with `"."` separators:
/// ```swift
/// path.map(\.rawValue).joined(separator: ".")
/// // "effect1.effect2.(...).effectN"
/// ```
///
/// If the ``path`` is empty, the identifier is also empty, and the effect is known as the ``root``.
/// The root effect is the one that executes the `body` of the `ProbeTesting.withProbing` function, and it is created implicitly.
/// All effects created within `body` are considered descendants of the root effect.
/// ```swift
/// withProbing {
///     // #Effect(.root) {
///     try await body()
///     // }
/// } dispatchedBy: { ... }
/// ```
///
/// ### Example
///
/// ```swift
/// func createInnerEffect() {
///     #Effect("inner") {}
/// }
///
/// func createOuterEffect() {
///     #Effect("outer") {
///         createInnerEffect()
///     }
/// }
///
/// createInnerEffect()
/// // Identifier: "inner"
///
/// createOuterEffect()
/// // Identifiers: "outer", "outer.inner"
/// ```
///
public struct EffectIdentifier {

    /// The identifier of the effect executing the `body` of the `ProbeTesting.withProbing` function.
    ///
    /// This effect is created implicitly during testing, and all effects created within the `body` are considered its descendants.
    ///
    /// Its ``rawValue`` is `""`, and its ``path`` is `[]`.
    ///
    public static let root = Self(path: [])

    /// A string formed by concatenating the ``path`` elements with `"."` separators.
    ///
    /// The `rawValue` has the form:
    /// ```swift
    /// path.map(\.rawValue).joined(separator: ".")
    /// // "effect1.effect2.(...).effectN"
    /// ```
    ///
    public let rawValue: String

    /// The stack of effect names that created a particular effect.
    ///
    /// The `path` reflects the nesting hierarchy of effects during a particular invocation. For example:
    /// ```swift
    /// func createInnerEffect() {
    ///     #Effect("inner") {}
    /// }
    ///
    /// func createOuterEffect() {
    ///     #Effect("outer") {
    ///         createInnerEffect()
    ///     }
    /// }
    ///
    /// createInnerEffect()
    /// // Path: ["inner"]
    ///
    /// createOuterEffect()
    /// // Paths: ["outer"], ["outer", "inner"]
    ///
    public let path: [EffectName]

    /// Creates an effect identifier for lookup during tests.
    ///
    /// - Parameter path: The stack of effect names that created a particular effect.
    ///
    /// Effect identifiers are determined dynamically during test execution.
    /// Use this initializer to construct expected effect identifiers, which can be passed to the `ProbeTesting.ProbingDispatcher` to control the execution flow.
    ///
    public init(path: [EffectName]) {
        self.rawValue = ProbingIdentifiers.join(path)
        self.path = path
    }
}

extension EffectIdentifier {

    @TaskLocal
    private static var _currentNodes = [Node]()

    /// The identifier of the effect from which this property was accessed.
    ///
    /// - Important: This property only works if the effect was created by invocation of the `body` of the `ProbeTesting.withProbing` function.
    /// Otherwise, it returns the ``root`` identifier.
    ///
    public static var current: EffectIdentifier {
        _currentNodes.last?.id ?? .root
    }

    static func current(appending childName: EffectName) -> EffectIdentifier {
        guard let parentNode = _currentNodes.last else {
            preconditionFailure("Root identifier has not been set.")
        }

        let childName = parentNode.enumerateIfNeeded(childName)
        let childPath = current.path + CollectionOfOne(childName)
        return EffectIdentifier(path: childPath)
    }

    static func withChild<R>(
        _ childID: EffectIdentifier,
        operation: () throws -> R
    ) rethrows -> R {
        let childNode = Node(id: childID)
        let childrenNodes = _currentNodes + CollectionOfOne(childNode)
        return try $_currentNodes.withValue(
            childrenNodes,
            operation: operation
        )
    }

    static func withRoot<R>(
        isolation: isolated (any Actor)?,
        operation: () async throws -> R
    ) async rethrows -> R {
        let rootNode = [Node(id: .root)]
        return try await $_currentNodes.withValue(
            rootNode,
            operation: operation,
            isolation: isolation
        )
    }
}

extension EffectIdentifier: ProbingIdentifierProtocol {

    public var description: String {
        if rawValue.isEmpty {
            "(root)"
        } else {
            rawValue
        }
    }

    /// Creates an effect identifier for lookup during tests.
    ///
    /// - Parameter rawValue: A string in the format described by ``rawValue``.
    ///
    /// Effect identifiers are determined dynamically during test execution.
    /// Use this initializer to construct expected effect identifiers, which can be passed to the `ProbeTesting.ProbingDispatcher` to control the execution flow.
    ///
    public init(rawValue: String) {
        let path = ProbingIdentifiers.split(rawValue).map(EffectName.init)
        self.init(path: path)
    }
}

extension EffectIdentifier: ExpressibleByArrayLiteral {

    /// Creates an effect identifier for lookup during tests.
    ///
    /// - Parameter elements: The stack of effect names that created a particular effect.
    ///
    /// Effect identifiers are determined dynamically during test execution.
    /// Use this initializer to construct expected effect identifiers, which can be passed to the `ProbeTesting.ProbingDispatcher` to control the execution flow.
    ///
    public init(arrayLiteral elements: EffectName...) {
        self.init(path: elements)
    }
}

extension EffectIdentifier {

    private final class Node: Sendable {

        let id: EffectIdentifier
        private let childrenIndices = Mutex([EffectName: UInt]())

        init(id: EffectIdentifier) {
            self.id = id
        }

        func enumerateIfNeeded(_ childName: EffectName) -> EffectName {
            guard childName.isEnumerated else {
                return childName
            }

            let index = childrenIndices.withLock { childrenIndices in
                let index = if let existing = childrenIndices[childName] {
                    existing + 1
                } else {
                    UInt.zero
                }
                childrenIndices[childName] = index
                return index
            }

            return childName.withIndex(index)
        }
    }
}
