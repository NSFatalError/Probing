//
//  ProbeIdentifier.swift
//  Probing
//
//  Created by Kamil Strzelecki on 21/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

public struct ProbeIdentifier {

    public let rawValue: String
    public let effect: EffectIdentifier
    public let name: ProbeName

    init(
        effect: EffectIdentifier,
        name: ProbeName
    ) {
        self.rawValue = ProbingIdentifiers.join([
            effect.rawValue,
            name.rawValue
        ])
        self.effect = effect
        self.name = name
    }
}

extension ProbeIdentifier {

    public static var probe: Self {
        .probe(.default)
    }

    public static func probe(
        _ name: ProbeName
    ) -> Self {
        .init(effect: .root, name: name)
    }

    public static func probe(
        _ name: ProbeName = .default,
        in effect: EffectIdentifier
    ) -> Self {
        .init(effect: effect, name: name)
    }
}

extension ProbeIdentifier: ProbingIdentifierProtocol {

    public init(rawValue: String) {
        let components = ProbingIdentifiers.split(rawValue)
        let path = components.dropLast().map(EffectName.init)
        let effect = EffectIdentifier(path: path)
        let name = ProbeName(rawValue: components.last ?? "")
        self.init(effect: effect, name: name)
    }
}
