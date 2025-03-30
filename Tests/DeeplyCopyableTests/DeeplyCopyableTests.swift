//
//  DeeplyCopyableTests.swift
//  Probing
//
//  Created by Kamil Strzelecki on 23/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import DeeplyCopyable
import EquatableObject
import Testing

internal struct DeeplyCopyableTests {

    @Test
    func testEnum() {
        let source = Choice.fourth(arg2: .zero, "Hello")
        let copy = source.deepCopy()
        #expect(source == copy)
    }

    @Test
    func testStruct() {
        let source = Order(id: .zero, address: "Kraków")
        let copy = source.deepCopy()
        #expect(source == copy)
    }

    @Test
    func testClass() {
        let source = Person()
        let copy = source.deepCopy()
        #expect(source == copy)
    }
}

extension DeeplyCopyableTests {

    @DeeplyCopyable
    fileprivate enum Choice: Equatable {

        case first
        case second(Int)
        case third(arg1: Int)
        case fourth(arg2: Int, String)
    }

    @DeeplyCopyable
    fileprivate struct Order: Equatable {

        let id: UInt
        var address: String
        var recipient: Person?

        var description: String {
            "\(id) - \(address)"
        }
    }

    @DeeplyCopyable @EquatableObject
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
