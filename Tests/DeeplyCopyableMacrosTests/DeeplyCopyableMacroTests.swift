//
//  DeeplyCopyableMacroTests.swift
//  Probing
//
//  Created by Kamil Strzelecki on 22/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import DeeplyCopyableMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

internal final class DeeplyCopyableMacroTests: XCTestCase {

    private let macros: [String: any Macro.Type] = [
        "DeeplyCopyable": DeeplyCopyableMacro.self
    ]

    func testEnumExpansion() {
        assertMacroExpansion(
            #"""
            @DeeplyCopyable
            public enum Choice {

                case first
                case second(Int)
                case third(arg1: Int)
                case fourth(arg2: Int, String)
            }
            """#,
            expandedSource:
            #"""
            public enum Choice {

                case first
                case second(Int)
                case third(arg1: Int)
                case fourth(arg2: Int, String)

                public init(deeplyCopying other: Choice) {
                    switch other {
                    case .first:
                        self = .first
                    case let .second(_0):
                        self = .second(_0.deepCopy())
                    case let .third(arg1):
                        self = .third(arg1: arg1.deepCopy())
                    case let .fourth(arg2, _1):
                        self = .fourth(arg2: arg2.deepCopy(), _1.deepCopy())
                    }
                }
            }

            extension Choice: DeeplyCopyable {
            }
            """#,
            macros: macros
        )
    }

    func testStructExpansion() {
        assertMacroExpansion(
            #"""
            @DeeplyCopyable
            public struct Order {

                static var current: Order?

                let id: UUID
                var address: String
                var recipient: Person?

                var description: String {
                    "\(id) - \(address)"
                }
            }
            """#,
            expandedSource:
            #"""
            public struct Order {

                static var current: Order?

                let id: UUID
                var address: String
                var recipient: Person?

                var description: String {
                    "\(id) - \(address)"
                }
            }

            extension Order: DeeplyCopyable {

                public init(deeplyCopying other: Order) {
                    self.id = other.id.deepCopy()
                    self.address = other.address.deepCopy()
                    self.recipient = other.recipient.deepCopy()
                }
            }
            """#,
            macros: macros
        )
    }

    func testClassExpansion() {
        assertMacroExpansion(
            #"""
            @DeeplyCopyable
            public final class Person {

                static var user: Person?

                let id: UUID
                var age = 25
                var name = "John"
                var surname = "Doe"

                var fullName: String {
                    "\(name) \(surname)"
                }

                init(id: UUID = .init()) {
                    self.id = id
                }
            }
            """#,
            expandedSource:
            #"""
            public final class Person {

                static var user: Person?

                let id: UUID
                var age = 25
                var name = "John"
                var surname = "Doe"

                var fullName: String {
                    "\(name) \(surname)"
                }

                init(id: UUID = .init()) {
                    self.id = id
                }

                public init(deeplyCopying other: Person) {
                    self.id = other.id.deepCopy()
                    self.age = other.age.deepCopy()
                    self.name = other.name.deepCopy()
                    self.surname = other.surname.deepCopy()
                }
            }

            extension Person: DeeplyCopyable {
            }
            """#,
            macros: macros
        )
    }
}
