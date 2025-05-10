//
//  EffectIdentifier.swift
//  Probing
//
//  Created by Kamil Strzelecki on 21/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Synchronization

public struct EffectIdentifier {

    public static let root = Self(path: [])

    public let rawValue: String
    public let path: [EffectName]

    public init(path: [EffectName]) {
        self.rawValue = ProbingIdentifiers.join(path)
        self.path = path
    }
}

extension EffectIdentifier {

    @TaskLocal
    private static var _currentNodes = [Node]()

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

    public init(rawValue: String) {
        let path = ProbingIdentifiers.split(rawValue).map(EffectName.init)
        self.init(path: path)
    }
}

extension EffectIdentifier: ExpressibleByArrayLiteral {

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
