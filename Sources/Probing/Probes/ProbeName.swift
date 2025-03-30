//
//  ProbeName.swift
//  Probing
//
//  Created by Kamil Strzelecki on 05/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

public struct ProbeName: ProbingIdentifierProtocol {

    public static let `default`: Self = "probe"

    public let rawValue: String

    public init(rawValue: String) {
        ProbingNames.preconditionValid(rawValue)
        self.rawValue = rawValue
    }
}
