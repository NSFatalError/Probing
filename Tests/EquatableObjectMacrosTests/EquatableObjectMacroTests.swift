//
//  EquatableObjectMacroTests.swift
//  Probing
//
//  Created by Kamil Strzelecki on 22/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import EquatableObjectMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

internal final class EquatableObjectMacroTests: XCTestCase {

    private let macros: [String: any Macro.Type] = [
        "EquatableObject": EquatableObjectMacro.self
    ]

    func testExpansion() {
        assertMacroExpansion(
            #"""
            @EquatableObject
            public final class Person {

                static var user: Person?

                let id: UUID
                var age: Int
                var name: String
                var surname: String

                var fullName: String {
                    "\(name) \(surname)"
                }
            }
            """#,
            expandedSource:
            #"""
            public final class Person {

                static var user: Person?

                let id: UUID
                var age: Int
                var name: String
                var surname: String

                var fullName: String {
                    "\(name) \(surname)"
                }

                public static func == (lhs: Person, rhs: Person) -> Bool {
                    guard lhs.id == rhs.id else {
                        return false
                    }
                    guard lhs.age == rhs.age else {
                        return false
                    }
                    guard lhs.name == rhs.name else {
                        return false
                    }
                    guard lhs.surname == rhs.surname else {
                        return false
                    }
                    return true
                }
            }

            extension Person: Equatable {
            }
            """#,
            macros: macros
        )
    }
}
