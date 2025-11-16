//
//  EffectNameTests.swift
//  Probing
//
//  Created by Kamil Strzelecki on 10/05/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@testable import Probing
import Testing

internal struct EffectNameTests {

    @Test
    func equality() {
        let name: EffectName = "effect"
        let enumeratedName = EffectName.enumerated(name)

        #expect(name == enumeratedName)
        #expect(name.hashValue == enumeratedName.hashValue)
    }

    @Test
    func indexing() {
        let name: EffectName = "effect"
        let enumeratedName = EffectName.enumerated(name)

        let index: UInt = 123
        let indexedName = name.withIndex(index)
        let enumeratedIndexedName = enumeratedName.withIndex(index)
        let literalName: EffectName = "effect123"

        #expect(indexedName == literalName)
        #expect(indexedName == enumeratedIndexedName)
        #expect(indexedName.hashValue == literalName.hashValue)
        #expect(indexedName.hashValue == enumeratedIndexedName.hashValue)
    }
}
