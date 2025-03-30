//
//  EffectIdentifier.swift
//  Probing
//
//  Created by Kamil Strzelecki on 21/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

public struct EffectIdentifier {

    package static let root = Self(path: [])

    public let rawValue: String
    public let path: [EffectName]

    init(path: [EffectName]) {
        self.rawValue = ProbingIdentifiers.join(path)
        self.path = path
    }
}

extension EffectIdentifier {

    public static func effect(_ path: [EffectName]) -> Self {
        ProbingIdentifiers.preconditionNotEmpty(path)
        return .init(path: path)
    }

    public static func effect(_ path: EffectName...) -> Self {
        ProbingIdentifiers.preconditionNotEmpty(path)
        return .init(path: path)
    }
}

extension EffectIdentifier: ProbingIdentifierProtocol {

    public init(rawValue: String) {
        let path = ProbingIdentifiers.split(rawValue).map(EffectName.init)
        ProbingIdentifiers.preconditionNotEmpty(path)
        self.init(path: path)
    }
}

extension EffectIdentifier: ExpressibleByArrayLiteral {

    public init(arrayLiteral elements: EffectName...) {
        ProbingIdentifiers.preconditionNotEmpty(elements)
        self.init(path: elements)
    }
}

extension EffectIdentifier {

    @TaskLocal
    private static var _current = EffectIdentifier.root

    public static var current: EffectIdentifier {
        _current
    }

    static func appending<R>(
        _ childName: EffectName,
        operation: (EffectIdentifier) throws -> R
    ) rethrows -> R {
        let childPath = current.path + CollectionOfOne(childName)
        let childID = EffectIdentifier(path: childPath)
        return try $_current.withValue(childID) {
            try operation(childID)
        }
    }
}
