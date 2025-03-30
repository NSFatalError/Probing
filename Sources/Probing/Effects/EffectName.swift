//
//  EffectName.swift
//  Probing
//
//  Created by Kamil Strzelecki on 21/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

public struct EffectName: ProbingIdentifierProtocol {

    public let rawValue: String

    public init(rawValue: String) {
        ProbingNames.preconditionValid(rawValue)
        self.rawValue = rawValue
    }
}
