//
//  ProbingIdentifierProtocol.swift
//  Probing
//
//  Created by Kamil Strzelecki on 24/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@_documentation(visibility: private)
public protocol ProbingIdentifierProtocol:
    RawRepresentable<String>,
    Hashable,
    Sendable,
    ExpressibleByStringLiteral,
    ExpressibleByStringInterpolation,
    CustomStringConvertible {

    init(rawValue: String)
}

extension ProbingIdentifierProtocol {

    public var description: String {
        rawValue
    }

    public init(stringLiteral: String) {
        self.init(rawValue: stringLiteral)
    }

    public init(stringInterpolation: DefaultStringInterpolation) {
        self.init(rawValue: .init(stringInterpolation: stringInterpolation))
    }
}

extension ProbingIdentifierProtocol {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}
