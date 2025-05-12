//
//  IndependentEffectsTests.swift
//  Probing
//
//  Created by Kamil Strzelecki on 26/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@testable import ProbeTesting
@testable import Probing
import Algorithms
import Testing

internal final class IndependentEffectsTests: EffectTests {

    @Test
    func testRunningThroughProbes() async throws {
        try await withProbing {
            await interactor.callWithIndependentEffects()
        } dispatchedBy: { dispatcher in
            await #expect(model.values.isEmpty)
            try await dispatcher.runUpToProbe("1")
            await #expect(
                model.values == [
                    .root: 1
                ]
            )

            try await dispatcher.runUpToProbe("2")
            await #expect(
                model.values == [
                    .root: 2
                ]
            )

            try await dispatcher.runUntilExitOfBody()
            await #expect(
                model.values == [
                    .root: 3
                ]
            )

            try await dispatcher.runUpToProbe("1.1")
            await #expect(
                model.values == [
                    .root: 3,
                    "1": 1
                ]
            )

            try await dispatcher.runUpToProbe("1.2")
            await #expect(
                model.values == [
                    .root: 3,
                    "1": 2
                ]
            )

            try await dispatcher.runUntilEffectCompleted("1")
            await #expect(
                model.values == [
                    .root: 3,
                    "1": 3
                ]
            )

            try await dispatcher.runUpToProbe("2.1")
            await #expect(
                model.values == [
                    .root: 3,
                    "1": 3,
                    "2": 1
                ]
            )

            try await dispatcher.runUpToProbe("2.2")
            await #expect(
                model.values == [
                    .root: 3,
                    "1": 3,
                    "2": 2
                ]
            )

            try await dispatcher.runUntilEffectCompleted("2")
            await #expect(
                model.values == [
                    .root: 3,
                    "1": 3,
                    "2": 3
                ]
            )
        }
    }

    @Test(
        arguments: 1 ..< 3,
        1 ..< 3
    )
    func testRunningToProbe(
        inEffect effect: Int,
        withNumber number: Int
    ) async throws {
        try await withProbing {
            await interactor.callWithIndependentEffects()
        } dispatchedBy: { dispatcher in
            await #expect(model.values.isEmpty)
            try await dispatcher.runUpToProbe("\(effect).\(number)")
            await #expect(
                model.values == [
                    .root: effect,
                    "\(effect)": number
                ]
            )

            try await dispatcher.runUntilEffectCompleted("\(effect)")
            await #expect(
                model.values == [
                    .root: effect,
                    "\(effect)": 3
                ]
            )
        }
        await #expect(model.values[.root, default: 0] == 3)
    }

    @Test
    func testNameEnumeration() async throws {
        try await withProbing {
            await interactor.callWithIndependentEnumeratedEffects()
        } dispatchedBy: { dispatcher in
            try await dispatcher.runUntilExitOfBody()
            try await dispatcher.runUntilEffectCompleted("effect0")
            await #expect(model.values == ["effect0": 3])

            try await dispatcher.runUntilEffectCompleted("effect1")
            await #expect(model.values == ["effect0": 3, "effect1": 3])
        }
    }
}

extension IndependentEffectsTests {

    @Test
    func testRunningWithoutDispatches() async throws {
        try await withProbing {
            await interactor.callWithIndependentEffects()
        } dispatchedBy: { _ in
            await #expect(model.values.isEmpty)
        }
        await #expect(model.values[.root] == 3)
    }

    @Test
    func testRunningUntilExitOfBody() async throws {
        try await withProbing {
            await interactor.callWithIndependentEffects()
        } dispatchedBy: { dispatcher in
            await #expect(model.values.isEmpty)
            try await dispatcher.runUntilExitOfBody()
            await #expect(model.values == [.root: 3])
        }
    }

    @Test
    func testRunningUntilEverythingCompleted() async throws {
        try await withProbing {
            await interactor.callWithIndependentEffects()
        } dispatchedBy: { dispatcher in
            await #expect(model.values.isEmpty)
            try await dispatcher.runUntilEverythingCompleted()
            await #expect(
                model.values == [
                    .root: 3,
                    "1": 3,
                    "2": 3
                ]
            )
        }
    }

    @Test
    func testGettingMissingEffectValue() async throws {
        try await withKnownIssue {
            try await withProbing {
                await interactor.callWithIndependentEffects()
            } dispatchedBy: { dispatcher in
                do {
                    await #expect(model.values.isEmpty)
                    try dispatcher.getValue(fromEffect: "test", as: Void.self)
                } catch {
                    await #expect(model.values.isEmpty)
                    throw error
                }
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.EffectNotFound.self)
        }
        await #expect(model.values[.root] == 3)
    }

    @Test
    func testGettingMissingEffectCancelledValue() async throws {
        try await withKnownIssue {
            try await withProbing {
                await interactor.callWithIndependentEffects()
            } dispatchedBy: { dispatcher in
                do {
                    await #expect(model.values.isEmpty)
                    try dispatcher.getCancelledValue(fromEffect: "test", as: Void.self)
                } catch {
                    await #expect(model.values.isEmpty)
                    throw error
                }
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.EffectNotFound.self)
        }
        await #expect(model.values[.root] == 3)
    }

    @Test(arguments: ProbingOptions.all)
    func testRunningUpToMissingProbe(options: ProbingOptions) async throws {
        try await withKnownIssue {
            try await withProbing(options: options) {
                await interactor.callWithIndependentEffects()
            } dispatchedBy: { dispatcher in
                do {
                    await #expect(model.values.isEmpty)
                    try await dispatcher.runUpToProbe("test")
                } catch {
                    await #expect(model.values[.root] == 3)
                    throw error
                }
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.ProbeNotInstalled.self)
        }
    }

    @Test(arguments: ProbingOptions.all)
    func testRunningUpToMissingProbeInEffect(options: ProbingOptions) async throws {
        try await withKnownIssue {
            try await withProbing(options: options) {
                await interactor.callWithIndependentEffects()
            } dispatchedBy: { dispatcher in
                do {
                    await #expect(model.values.isEmpty)
                    try await dispatcher.runUpToProbe(inEffect: "test")
                } catch {
                    await #expect(model.values[.root] == 3)
                    throw error
                }
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.ChildEffectNotCreated.self)
        }
    }

    @Test(
        arguments: [true, false],
        ProbingOptions.all
    )
    func testRunningUntilMissingEffectCompleted(
        includingDescendants: Bool,
        options: ProbingOptions
    ) async throws {
        try await withKnownIssue {
            try await withProbing(options: options) {
                await interactor.callWithIndependentEffects()
            } dispatchedBy: { dispatcher in
                do {
                    await #expect(model.values.isEmpty)
                    try await dispatcher.runUntilEffectCompleted(
                        "test",
                        includingDescendants: includingDescendants
                    )
                } catch {
                    await #expect(model.values[.root] == 3)
                    throw error
                }
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.ChildEffectNotCreated.self)
        }
    }
}

extension EffectTests.IsolatedInteractor {

    func callWithIndependentEffects() async {
        model.tick()
        makeEffect("1")
        await #probe("1")
        model.tick()
        makeEffect("2")
        await #probe("2")
        model.tick()
    }

    func callWithIndependentEnumeratedEffects() {
        makeEffect(.enumerated("effect"))
        makeEffect(.enumerated("effect"))
    }
}
