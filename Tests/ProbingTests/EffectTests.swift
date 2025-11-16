//
//  EffectTests.swift
//  Probing
//
//  Created by Kamil Strzelecki on 02/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@testable import Probing
import Testing

internal enum EffectTests {

    struct WithIsolatedOperation {

        @Test
        func effectInit() async {
            await confirmation { confirmation in
                let effect = #Effect("Test") {
                    try? await Task.sleep(for: .microseconds(1))
                    confirmation()
                }

                #expect(effect is TestableEffect<Void>)
                #expect(effect.eraseToAnyEffect().task == effect.task)
                await effect.value
            }
        }

        @Test
        func taskInit() async {
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
                #expect(effect.eraseToAnyEffect().task == effect.task)
                await effect.value
            }
        }

        @CustomActor
        @Test
        func isolation() async {
            let effect = #Effect("Test") {
                let isolation = #isolation
                #expect(isolation === CustomActor.shared)
                CustomActor.shared.assertIsolated()
            }
            await effect.value
        }
    }

    struct WithExecutorPreference {

        @Test
        func effectInit() async {
            await confirmation { confirmation in
                let effect = #Effect("Test", executorPreference: globalConcurrentExecutor) {
                    try? await Task.sleep(for: .microseconds(1))
                    confirmation()
                }

                #expect(effect is TestableEffect<Void>)
                #expect(effect.eraseToAnyEffect().task == effect.task)
                await effect.value
            }
        }

        @Test
        func taskInit() async {
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
                #expect(effect.eraseToAnyEffect().task == effect.task)
                await effect.value
            }
        }

        @CustomActor
        @Test
        func isolation() async {
            let effect = #Effect("Test", executorPreference: globalConcurrentExecutor) {
                let isolation = #isolation
                #expect(isolation == nil)
            }
            await effect.value
        }
    }

    struct Concurrent {

        @Test
        func effectInit() async {
            await confirmation { confirmation in
                let effect = #Effect("Test") { @concurrent in
                    try? await Task.sleep(for: .microseconds(1))
                    confirmation()
                }

                #expect(effect is TestableEffect<Void>)
                #expect(effect.eraseToAnyEffect().task == effect.task)
                await effect.value
            }
        }

        @Test
        func taskInit() async {
            await confirmation { confirmation in
                let effect = #Effect(
                    "Test",
                    preprocessorFlag: "NULL",
                    operation: { @concurrent in
                        try? await Task.sleep(for: .microseconds(1))
                        confirmation()
                    }
                )

                #expect(effect is Task<Void, Never>)
                #expect(effect.eraseToAnyEffect().task == effect.task)
                await effect.value
            }
        }

        @CustomActor
        @Test
        func isolation() async {
            let effect = #Effect("Test") { @concurrent in
                let isolation = #isolation
                #expect(isolation == nil)
            }
            await effect.value
        }
    }

    struct Recursive {

        @Test
        func effectNestedChildrenInit() async {
            await confirmation { confirmation in
                let effect = #Effect("1") {
                    #Effect("2", executorPreference: globalConcurrentExecutor) {
                        #Effect("3", priority: .high) { @concurrent in
                            confirmation()
                        }
                    }
                }

                #expect(effect is TestableEffect<any Effect<any Effect<Void>>>)
                #expect(effect.eraseToAnyEffect().task == effect.task)
                await effect.value.value.value
            }
        }

        @Test
        func taskNestedChildrenInit() async {
            await confirmation { confirmation in
                let effect = #Effect("1", preprocessorFlag: "NULL") {
                    #Effect("2", executorPreference: globalConcurrentExecutor) {
                        #Effect("3", priority: .high) { @concurrent in
                            confirmation()
                        }
                    }
                }

                #expect(effect is Task<any Effect<any Effect<Void>>, Never>)
                #expect(effect.eraseToAnyEffect().task == effect.task)
                await effect.value.value.value
            }
        }
    }
}
