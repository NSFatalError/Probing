//
//  EffectTests.swift
//  Probing
//
//  Created by Kamil Strzelecki on 26/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@testable import ProbeTesting
@testable import Probing
import Algorithms
import Testing

internal final class NestedEffectsTests: EffectTests {

    @Test
    func testRunningThroughProbes() async throws {
        try await withProbing {
            await interactor.callWithNestedEffects()
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

            try await dispatcher.runUpToProbe("1.1.1")
            await #expect(
                model.values == [
                    .root: 3,
                    "1": 3,
                    "1.1": 1
                ]
            )

            try await dispatcher.runUpToProbe("1.1.2")
            await #expect(
                model.values == [
                    .root: 3,
                    "1": 3,
                    "1.1": 2
                ]
            )

            try await dispatcher.runUntilEffectCompleted("1.1")
            await #expect(
                model.values == [
                    .root: 3,
                    "1": 3,
                    "1.1": 3
                ]
            )
        }
    }

    @Test(
        arguments: Array(product(1 ..< 3, 1 ..< 3)),
        1 ..< 3
    )
    func testRunningToProbe(
        inEffect effect: (parent: Int, child: Int),
        withNumber number: Int
    ) async throws {
        try await withProbing {
            await interactor.callWithNestedEffects()
        } dispatchedBy: { dispatcher in
            await #expect(model.values.isEmpty)
            try await dispatcher.runUpToProbe("\(effect.parent).\(effect.child).\(number)")
            await #expect(
                model.values == [
                    .root: effect.parent,
                    "\(effect.parent)": effect.child,
                    "\(effect.parent).\(effect.child)": number
                ]
            )

            try await dispatcher.runUntilEffectCompleted("\(effect.parent).\(effect.child)")
            await #expect(
                model.values == [
                    .root: effect.parent,
                    "\(effect.parent)": effect.child,
                    "\(effect.parent).\(effect.child)": 3
                ]
            )

            try await dispatcher.runUntilEffectCompleted("\(effect.parent)")
            await #expect(
                model.values == [
                    .root: effect.parent,
                    "\(effect.parent)": 3,
                    "\(effect.parent).\(effect.child)": 3
                ]
            )

            try await dispatcher.runUntilEffectCompleted(
                "\(effect.parent)",
                includingDescendants: true
            )
            await #expect(
                model.values == [
                    .root: effect.parent,
                    "\(effect.parent)": 3,
                    "\(effect.parent).1": 3,
                    "\(effect.parent).2": 3
                ]
            )
        }
        await #expect(model.values[.root, default: 0] == 3)
    }

    @Test
    func testNameEnumeration() async throws {
        try await withProbing {
            await interactor.callWithNestedEnumeratedEffects()
        } dispatchedBy: { dispatcher in
            try await dispatcher.runUntilExitOfBody()
            try await dispatcher.runUntilEffectCompleted("name0.effect0")
            await #expect(model.values == ["name0.effect0": 3])

            try await dispatcher.runUntilEffectCompleted("name1.effect1")
            await #expect(
                model.values == [
                    "name0.effect0": 3,
                    "name1.effect1": 3
                ]
            )

            try await dispatcher.runUntilEffectCompleted("name0", includingDescendants: true)
            await #expect(
                model.values == [
                    "name0.effect0": 3,
                    "name0.effect1": 3,
                    "name1.effect1": 3
                ]
            )

            try await dispatcher.runUntilEffectCompleted("name1", includingDescendants: true)
            await #expect(
                model.values == [
                    "name0.effect0": 3,
                    "name0.effect1": 3,
                    "name1.effect0": 3,
                    "name1.effect1": 3
                ]
            )
        }
    }
}

extension NestedEffectsTests {

    @Test
    func testRunningWithoutDispatches() async throws {
        try await withProbing {
            await interactor.callWithNestedEffects()
        } dispatchedBy: { _ in
            await #expect(model.values.isEmpty)
        }
        await #expect(model.values[.root] == 3)
    }

    @Test
    func testRunningUntilExitOfBody() async throws {
        try await withProbing {
            await interactor.callWithNestedEffects()
        } dispatchedBy: { dispatcher in
            await #expect(model.values.isEmpty)
            try await dispatcher.runUntilExitOfBody()
            await #expect(model.values == [.root: 3])
        }
    }

    @Test
    func testRunningUntilEverythingCompleted() async throws {
        try await withProbing {
            await interactor.callWithNestedEffects()
        } dispatchedBy: { dispatcher in
            await #expect(model.values.isEmpty)
            try await dispatcher.runUntilEverythingCompleted()
            await #expect(
                model.values == [
                    .root: 3,
                    "1": 3,
                    "1.1": 3,
                    "1.2": 3,
                    "2": 3,
                    "2.1": 3,
                    "2.2": 3
                ]
            )
        }
    }

    @Test
    func testGettingMissingEffectValue() async throws {
        try await withKnownIssue {
            try await withProbing {
                await interactor.callWithNestedEffects()
            } dispatchedBy: { dispatcher in
                do {
                    await #expect(model.values.isEmpty)
                    try dispatcher.getValue(fromEffect: "1.2.test", as: Void.self)
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
                await interactor.callWithNestedEffects()
            } dispatchedBy: { dispatcher in
                do {
                    await #expect(model.values.isEmpty)
                    try dispatcher.getCancelledValue(fromEffect: "1.2.test", as: Void.self)
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
                await interactor.callWithNestedEffects()
            } dispatchedBy: { dispatcher in
                do {
                    await #expect(model.values.isEmpty)
                    try await dispatcher.runUpToProbe("1.2.test")
                } catch {
                    await #expect(model.values[.root, default: 0] >= 1)
                    await #expect(model.values["1", default: 0] >= 2)
                    await #expect(model.values["1.2", default: 0] == 3)
                    throw error
                }
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.ProbeNotInstalled.self)
        }
        await #expect(model.values[.root] == 3)
    }

    @Test(arguments: ProbingOptions.all)
    func testRunningUpToMissingProbeInEffect(options: ProbingOptions) async throws {
        try await withKnownIssue {
            try await withProbing(options: options) {
                await interactor.callWithNestedEffects()
            } dispatchedBy: { dispatcher in
                do {
                    await #expect(model.values.isEmpty)
                    try await dispatcher.runUpToProbe(inEffect: "1.2.test")
                } catch {
                    await #expect(model.values[.root, default: 0] >= 1)
                    await #expect(model.values["1", default: 0] >= 2)
                    await #expect(model.values["1.2", default: 0] == 3)
                    throw error
                }
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.ChildEffectNotCreated.self)
        }
        await #expect(model.values[.root] == 3)
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
                await interactor.callWithNestedEffects()
            } dispatchedBy: { dispatcher in
                do {
                    await #expect(model.values.isEmpty)
                    try await dispatcher.runUntilEffectCompleted(
                        "1.2.test",
                        includingDescendants: includingDescendants
                    )
                } catch {
                    await #expect(model.values[.root, default: 0] >= 1)
                    await #expect(model.values["1", default: 0] >= 2)
                    await #expect(model.values["1.2", default: 0] == 3)
                    throw error
                }
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.ChildEffectNotCreated.self)
        }
        await #expect(model.values[.root] == 3)
    }
}

extension EffectTests.IsolatedInteractor {

    func callWithNestedEffects() async {
        model.tick()
        #Effect("1") {
            await self.callWithIndependentEffects()
        }

        await #probe("1")
        model.tick()
        #ConcurrentEffect("2") {
            await self.callWithIndependentEffects()
        }

        await #probe("2")
        model.tick()
    }

    func callWithNestedEnumeratedEffects() {
        #Effect(.enumerated("name")) {
            self.callWithIndependentEnumeratedEffects()
        }
        #ConcurrentEffect(.enumerated("name")) {
            await self.callWithIndependentEnumeratedEffects()
        }
    }
}
