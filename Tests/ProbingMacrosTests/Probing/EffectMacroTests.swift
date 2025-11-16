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

        func testExpansion() {
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
                        name: "test",
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

        func testExpansionWithGlobalActor() {
            assertMacroExpansion(
                #"""
                #Effect("test") { @MainActor in
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
                        operation: { @MainActor in
                            print("Hello")
                        }
                    )
                    #else
                    return Task(
                        name: "test",
                        priority: nil,
                        operation: { @MainActor in
                            print("Hello")
                        }
                    )
                    #endif
                }()
                """#,
                macros: macros
            )
        }

        func testExpansionWithConcurrentAttribute() {
            assertMacroExpansion(
                #"""
                #Effect("test") { @concurrent in
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
                        operation: { @concurrent in
                            print("Hello")
                        }
                    )
                    #else
                    return Task(
                        name: "test",
                        priority: nil,
                        operation: { @concurrent in
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
                        name: "test",
                        priority: .high,
                        operation: operation
                    )
                    #endif
                }()
                """#,
                macros: macros
            )
        }
    }

    extension EffectMacroTests {

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
                        name: "test",
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
                        name: "test",
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
    }

    extension EffectMacroTests {

        func testExpansionWithNestedChildren() {
            assertMacroExpansion(
                #"""
                #Effect("1") {
                    #Effect("2", priority: .high) { @concurrent in
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
                                priority: .high,
                                operation: { @concurrent in
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
                        name: "1",
                        priority: nil,
                        operation: {
                            Task(
                                name: "2",
                                priority: .high,
                                operation: { @concurrent in
                                    print("Hello")
                                    if true {
                                        Task(
                                            name: "3",
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
