//
//  ProbeMacroTests.swift
//  Probing
//
//  Created by Kamil Strzelecki on 10/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import ProbingMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

internal final class ProbeMacroTests: XCTestCase {

    private let macros: [String: Macro.Type] = [
        "probe": ProbeMacro.self
    ]

    func testExpansion() {
        assertMacroExpansion(
            #"""
            #probe()
            """#,
            expandedSource:
            #"""
            { (isolation: isolated (any Actor)?) async -> Void in
                #if DEBUG
                await _probe(
                    .default,
                    when: true,
                    isolation: isolation
                )
                #endif
            }(#isolation)
            """#,
            macros: macros
        )
    }

    func testExpansionWithParameters() {
        assertMacroExpansion(
            #"""
            #probe(
                "myIdentifier",
                when: false,
                preprocessorFlag: "UNIT_TESTS"
            )
            """#,
            expandedSource:
            #"""
            { (isolation: isolated (any Actor)?) async -> Void in
                #if UNIT_TESTS
                await _probe(
                    "myIdentifier",
                    when: false,
                    isolation: isolation
                )
                #endif
            }(#isolation)
            """#,
            macros: macros
        )
    }
}
