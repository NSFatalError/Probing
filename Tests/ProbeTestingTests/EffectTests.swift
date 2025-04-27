//
//  EffectTests.swift
//  Probing
//
//  Created by Kamil Strzelecki on 26/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

// swiftlint:disable file_length
@testable import ProbeTesting
@testable import Probing
import Algorithms
import Testing

internal class EffectTests {

    private let model: IsolatedModel
    private let shell: IsolatedShell

    init() async {
        self.model = .init()
        self.shell = await .init(model: model)
    }
}

extension EffectTests {

    final class Independent: EffectTests {

        @Test
        func testRunningThroughProbes() async throws {
            try await withProbing {
                await shell.callWithIndependentEffects()
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
                await shell.callWithIndependentEffects()
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
    }
}

extension EffectTests.Independent {

    @Test
    func testRunningWithoutDispatches() async throws {
        try await withProbing {
            await shell.callWithIndependentEffects()
        } dispatchedBy: { _ in
            await #expect(model.values.isEmpty)
        }
        await #expect(model.values[.root] == 3)
    }

    @Test
    func testRunningUntilExitOfBody() async throws {
        try await withProbing {
            await shell.callWithIndependentEffects()
        } dispatchedBy: { dispatcher in
            await #expect(model.values.isEmpty)
            try await dispatcher.runUntilExitOfBody()
            await #expect(model.values == [.root: 3])
        }
    }

    @Test
    func testRunningUntilEverythingCompleted() async throws {
        try await withProbing {
            await shell.callWithIndependentEffects()
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
                await shell.callWithIndependentEffects()
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
                await shell.callWithIndependentEffects()
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
                await shell.callWithIndependentEffects()
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
                await shell.callWithIndependentEffects()
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
                await shell.callWithIndependentEffects()
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

extension EffectTests {

    final class Nested: EffectTests {

        @Test
        func testRunningThroughProbes() async throws {
            try await withProbing {
                await shell.callWithNestedEffects()
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
                await shell.callWithNestedEffects()
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
    }
}

extension EffectTests.Nested {

    @Test
    func testRunningWithoutDispatches() async throws {
        try await withProbing {
            await shell.callWithNestedEffects()
        } dispatchedBy: { _ in
            await #expect(model.values.isEmpty)
        }
        await #expect(model.values[.root] == 3)
    }

    @Test
    func testRunningUntilExitOfBody() async throws {
        try await withProbing {
            await shell.callWithNestedEffects()
        } dispatchedBy: { dispatcher in
            await #expect(model.values.isEmpty)
            try await dispatcher.runUntilExitOfBody()
            await #expect(model.values == [.root: 3])
        }
    }

    @Test
    func testRunningUntilEverythingCompleted() async throws {
        try await withProbing {
            await shell.callWithNestedEffects()
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
                await shell.callWithNestedEffects()
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
                await shell.callWithNestedEffects()
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
                await shell.callWithNestedEffects()
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
                await shell.callWithNestedEffects()
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
                await shell.callWithNestedEffects()
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

extension EffectTests {

    @MainActor
    private final class IsolatedModel {

        var values = [EffectIdentifier: Int]()

        func tick() {
            values[.current, default: 0] += 1
        }
    }

    @MainActor
    private final class IsolatedShell {

        private let model: IsolatedModel

        init(model: IsolatedModel) {
            self.model = model
        }

        @discardableResult
        private func makeEffect(_ name: EffectName) -> any Effect<Void> {
            #Effect(name) {
                self.model.tick()
                await #probe("1")

                guard !Task.isCancelled else {
                    return
                }

                self.model.tick()
                await #probe("2")
                self.model.tick()
            }
        }

        func callWithEffect() {
            makeEffect("1")
        }

        func callWithCancelledEffect() {
            let effect = makeEffect("1")
            effect.cancel()
        }

        func callWithIndependentEffects() async {
            model.tick()
            makeEffect("1")
            await #probe("1")
            model.tick()
            makeEffect("2")
            await #probe("2")
            model.tick()
        }

        func callWithNestedEffects() async {
            model.tick()
            #Effect("1") {
                await self.callWithIndependentEffects()
            }
            await #probe("1")
            model.tick()
            #Effect("2") {
                await self.callWithIndependentEffects()
            }
            await #probe("2")
            model.tick()
        }
    }
}
