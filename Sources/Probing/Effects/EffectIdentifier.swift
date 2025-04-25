//
//  EffectIdentifier.swift
//  Probing
//
//  Created by Kamil Strzelecki on 21/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

public struct EffectIdentifier {

    public static let root = Self(path: [])

    public let rawValue: String
    public let path: [EffectName]

    public init(path: [EffectName]) {
        self.rawValue = ProbingIdentifiers.join(path)
        self.path = path
    }
}

extension EffectIdentifier: ProbingIdentifierProtocol {

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
