//
//  ProbeMacroTests.swift
//  Probing
//
//  Created by Kamil Strzelecki on 10/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

#if canImport(ProbingMacros)
    import ProbingMacros
    import SwiftSyntaxMacros
    import SwiftSyntaxMacrosTestSupport
    import XCTest

    internal final class ProbeMacroTests: XCTestCase {

        private let macros: [String: any Macro.Type] = [
            "probe": ProbeMacro.self
        ]

        func testExpansion() {
            assertMacroExpansion(
                #"""
                #probe()
                """#,
                expandedSource:
                #"""
                { () async -> Void in
                    #if DEBUG
                    await _probe(
                        .default,
                        isolation: #isolation
                    )
                    #endif
                }()
                """#,
                macros: macros
            )
        }

        func testExpansionWithParameters() {
            assertMacroExpansion(
                #"""
                #probe(
                    "myIdentifier",
                    preprocessorFlag: "UNIT_TESTS"
                )
                """#,
                expandedSource:
                #"""
                { () async -> Void in
                    #if UNIT_TESTS
                    await _probe(
                        "myIdentifier",
                        isolation: #isolation
                    )
                    #endif
                }()
                """#,
                macros: macros
            )
        }
    }
#endif
