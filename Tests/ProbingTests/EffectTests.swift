//
//  EffectTests.swift
//  Probing
//
//  Created by Kamil Strzelecki on 02/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@testable import Probing
import Testing

internal struct EffectTests {

    struct WithIsolatedOperation {

        @Test
        func testTestableEffectInit() async {
            await confirmation { confirmation in
                let effect = #Effect("Test") {
                    try? await Task.sleep(for: .microseconds(1))
                    confirmation()
                }

                #expect(effect is TestableEffect<Void>)
                #expect(effect.erasedToAnyEffect().task == effect.task)
                await effect.value
            }
        }

        @Test
        func testTaskInit() async {
            await confirmation { confirmation in
                let effect = #Effect(
                    "Test",
                    preprocessorFlag: "NULL",
                    operation: {
                        try? await Task.sleep(for: .microseconds(1))
                        confirmation()
                    }
                )

                #expect(effect is Task<Void, Never>)
                #expect(effect.erasedToAnyEffect().task == effect.task)
                await effect.value
            }
        }
    }

    struct WithExecutorPreference {

        @Test
        func testTestableEffectInit() async {
            await confirmation { confirmation in
                let effect = #Effect("Test", executorPreference: globalConcurrentExecutor) {
                    try? await Task.sleep(for: .microseconds(1))
                    confirmation()
                }

                #expect(effect is TestableEffect<Void>)
                #expect(effect.erasedToAnyEffect().task == effect.task)
                await effect.value
            }
        }

        @Test
        func testTaskInit() async {
            await confirmation { confirmation in
                let effect = #Effect(
                    "Test",
                    preprocessorFlag: "NULL",
                    executorPreference: globalConcurrentExecutor,
                    operation: {
                        try? await Task.sleep(for: .microseconds(1))
                        confirmation()
                    }
                )

                #expect(effect is Task<Void, Never>)
                #expect(effect.erasedToAnyEffect().task == effect.task)
                await effect.value
            }
        }
    }

    struct Concurrent {

        @Test
        func testTestableEffectInit() async {
            await confirmation { confirmation in
                let effect = #ConcurrentEffect("Test") {
                    try? await Task.sleep(for: .microseconds(1))
                    confirmation()
                }

                #expect(effect is TestableEffect<Void>)
                #expect(effect.erasedToAnyEffect().task == effect.task)
                await effect.value
            }
        }

        @Test
        func testTaskInit() async {
            await confirmation { confirmation in
                let effect = #ConcurrentEffect(
                    "Test",
                    preprocessorFlag: "NULL",
                    operation: {
                        try? await Task.sleep(for: .microseconds(1))
                        confirmation()
                    }
                )

                #expect(effect is Task<Void, Never>)
                #expect(effect.erasedToAnyEffect().task == effect.task)
                await effect.value
            }
        }
    }

    struct Recursive {

        @Test
        func testTestableEffectNestedChildrenInit() async {
            await confirmation { confirmation in
                let effect = #Effect("1") {
                    #Effect("2", executorPreference: globalConcurrentExecutor) {
                        #ConcurrentEffect("3", priority: .high) {
                            confirmation()
                        }
                    }
                }

                #expect(effect is TestableEffect<any Effect<any Effect<Void>>>)
                #expect(effect.erasedToAnyEffect().task == effect.task)
                await effect.value.value.value
            }
        }

        @Test
        func testTaskNestedChildrenInit() async {
            await confirmation { confirmation in
                let effect = #Effect("1", preprocessorFlag: "NULL") {
                    #Effect("2", executorPreference: globalConcurrentExecutor) {
                        #ConcurrentEffect("3", priority: .high) {
                            confirmation()
                        }
                    }
                }

                #expect(effect is Task<any Effect<any Effect<Void>>, Never>)
                #expect(effect.erasedToAnyEffect().task == effect.task)
                await effect.value.value.value
            }
        }
    }
}
