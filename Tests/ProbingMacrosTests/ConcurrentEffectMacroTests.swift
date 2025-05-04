//
//  ConcurrentEffectMacroTests.swift
//  Probing
//
//  Created by Kamil Strzelecki on 02/03/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

#if canImport(ProbingMacros)
import ProbingMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

internal final class ConcurrentEffectMacroTests: XCTestCase {

    private let macros: [String: any Macro.Type] = [
        "ConcurrentEffect": EffectMacro.self
    ]

    func testExpansion() {
        assertMacroExpansion(
            #"""
            #ConcurrentEffect("test") {
                print("Hello")
            }
            """#,
            expandedSource:
            #"""
            {
                #if DEBUG
                return TestableEffect._make(
                    "test",
                    executorPreference: globalConcurrentExecutor,
                    priority: nil,
                    operation: {
                        print("Hello")
                    }
                )
                #else
                return Task(
                    executorPreference: globalConcurrentExecutor,
                    priority: nil,
                    operation: {
                        print("Hello")
                    }
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
            #ConcurrentEffect(
                "test",
                preprocessorFlag: "UNIT_TESTS",
                priority: .high,
                operation: operation
            )
            """#,
            expandedSource:
            #"""
            {
                #if UNIT_TESTS
                return TestableEffect._make(
                    "test",
                    executorPreference: globalConcurrentExecutor,
                    priority: .high,
                    operation: operation
                )
                #else
                return Task(
                    executorPreference: globalConcurrentExecutor,
                    priority: .high,
                    operation: operation
                )
                #endif
            }()
            """#,
            macros: macros
        )
    }

    func testExpansionWithNestedChildren() {
        assertMacroExpansion(
            #"""
            #ConcurrentEffect("1") {
                #Effect("2", priority: .high) {
                    print("Hello")
                    if true {
                        #ConcurrentEffect("3", operation: operation)
                    } else {
                        print("World")
                    }
                }
                print("!")
            }
            """#,

            expandedSource:
            #"""
            {
                #if DEBUG
                return TestableEffect._make(
                    "1",
                    executorPreference: globalConcurrentExecutor,
                    priority: nil,
                    operation: {
                        TestableEffect._make(
                            "2",
                            priority: .high,
                            operation: {
                                print("Hello")
                                if true {
                                    TestableEffect._make(
                                        "3",
                                        executorPreference: globalConcurrentExecutor,
                                        priority: nil,
                                        operation: operation
                                    )
                                } else {
                                    print("World")
                                }
                            }
                        )
                        print("!")
                    }
                )
                #else
                return Task(
                    executorPreference: globalConcurrentExecutor,
                    priority: nil,
                    operation: {
                        Task(
                            priority: .high,
                            operation: {
                                print("Hello")
                                if true {
                                    Task(
                                        executorPreference: globalConcurrentExecutor,
                                        priority: nil,
                                        operation: operation
                                    )
                                } else {
                                    print("World")
                                }
                            }
                        )
                        print("!")
                    }
                )
                #endif
            }()
            """#,
            macros: macros
        )
    }
}
#endif
