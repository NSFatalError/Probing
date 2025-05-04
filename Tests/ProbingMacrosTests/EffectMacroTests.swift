//
//  EffectMacroTests.swift
//  Probing
//
//  Created by Kamil Strzelecki on 01/03/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

#if canImport(ProbingMacros)
    import ProbingMacros
    import SwiftSyntaxMacros
    import SwiftSyntaxMacrosTestSupport
    import XCTest

    internal final class EffectMacroTests: XCTestCase {

        private let macros: [String: any Macro.Type] = [
            "Effect": EffectMacro.self
        ]

        func testExpansionWithIsolatedOperation() {
            assertMacroExpansion(
                #"""
                #Effect("test") {
                    print("Hello")
                }
                """#,
                expandedSource:
                #"""
                {
                    #if DEBUG
                    return TestableEffect._make(
                        "test",
                        priority: nil,
                        operation: {
                            print("Hello")
                        }
                    )
                    #else
                    return Task(
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

        func testExpansionWithIsolatedOperationAndParameters() {
            assertMacroExpansion(
                #"""
                #Effect(
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
                        priority: .high,
                        operation: operation
                    )
                    #else
                    return Task(
                        priority: .high,
                        operation: operation
                    )
                    #endif
                }()
                """#,
                macros: macros
            )
        }

        func testExpansionWithExecutorPreference() {
            assertMacroExpansion(
                #"""
                #Effect("test", executorPreference: globalConcurrentExecutor) {
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

        func testExpansionWithExecutorPreferenceAndParameters() {
            assertMacroExpansion(
                #"""
                #Effect(
                    "test",
                    preprocessorFlag: "UNIT_TESTS",
                    executorPreference: globalConcurrentExecutor,
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
                #Effect("1") {
                    #ConcurrentEffect("2", priority: .high) {
                        print("Hello")
                        if true {
                            #Effect("3", operation: operation)
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
                        priority: nil,
                        operation: {
                            TestableEffect._make(
                                "2",
                                executorPreference: globalConcurrentExecutor,
                                priority: .high,
                                operation: {
                                    print("Hello")
                                    if true {
                                        TestableEffect._make(
                                            "3",
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
                        priority: nil,
                        operation: {
                            Task(
                                executorPreference: globalConcurrentExecutor,
                                priority: .high,
                                operation: {
                                    print("Hello")
                                    if true {
                                        Task(
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
