//
//  EquatableObjectTests.swift
//  Probing
//
//  Created by Kamil Strzelecki on 22/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import EquatableObject
import Testing

internal struct EquatableObjectTests {

    @Test
    func testEquality() {
        let lhs = Person()
        let rhs = Person()
        #expect(lhs == rhs)
    }

    @Test
    func testNonEquality() {
        let lhs = Person(id: 0)
        let rhs = Person(id: 1)
        #expect(lhs != rhs)
    }
}

extension EquatableObjectTests {

    @EquatableObject
    fileprivate final class Person {

        let id: UInt
        var age = 25
        var name = "John"
        var surname = "Doe"

        var fullName: String {
            "\(name) \(surname)"
        }

        init(id: UInt = .zero) {
            self.id = id
        }
    }
}
