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
    private let interactor: IsolatedInteractor

    init() async {
        self.model = .init()
        self.interactor = await .init(model: model)
    }

    @Test
    func testNameAmbiguity() async throws {
        try await withKnownIssue {
            try await withProbing {
                await interactor.callWithAmbiguousEffects()
            } dispatchedBy: { dispatcher in
                try await dispatcher.runUntilExitOfBody()
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.EffectIdentifierAmbiguous.self)
        }
    }

    @Test
    func testNameAmbiguityWhenChildNotCompleted() async throws {
        try await withKnownIssue {
            try await withProbing {
                await interactor.callWithAmbiguousEffects()
            } dispatchedBy: { dispatcher in
                try await dispatcher.runUntilEffectCompleted("ambiguous")
                try await dispatcher.runUntilExitOfBody()
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.EffectIdentifierAmbiguous.self)
        }
    }

    @Test
    func testNameReplacement() async throws {
        try await withProbing {
            await interactor.callWithAmbiguousEffects()
        } dispatchedBy: { dispatcher in
            try await dispatcher.runUntilEffectCompleted("ambiguous", includingDescendants: true)
            let first = try dispatcher.getValue(fromEffect: "ambiguous", as: Int.self)
            #expect(first == 1)

            try await dispatcher.runUntilExitOfBody()
            try await dispatcher.runUntilEffectCompleted("ambiguous")
            let second = try dispatcher.getValue(fromEffect: "ambiguous", as: Int.self)
            #expect(second == 2)
        }
    }
}

extension EffectTests {

    @Test
    func testGettingValue() async throws {
        try await withProbing {
            await interactor.callWithEffect()
        } dispatchedBy: { dispatcher in
            try await dispatcher.runUntilEffectCompleted("1")
            let result = try dispatcher.getValue(fromEffect: "1", as: EffectIdentifier?.self)
            #expect(result == "1")
        }
    }

    @Test
    func testGettingValueWhenCancelled() async throws {
        try await withKnownIssue {
            try await withProbing {
                await interactor.callWithCancelledEffect()
            } dispatchedBy: { dispatcher in
                try await dispatcher.runUntilEffectCompleted("1")
                _ = try dispatcher.getValue(fromEffect: "1", as: EffectIdentifier?.self)
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.FinishedValueNotMatching.self)
        }
    }

    @Test
    func testGettingValueWhenCastingFails() async throws {
        try await withKnownIssue {
            try await withProbing {
                await interactor.callWithEffect()
            } dispatchedBy: { dispatcher in
                try await dispatcher.runUntilEffectCompleted("1")
                _ = try dispatcher.getValue(fromEffect: "1", as: Int.self)
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.FinishedValueNotMatching.self)
        }
    }

    @Test
    func testGettingValueWhenNotCompleted() async throws {
        try await withKnownIssue {
            try await withProbing {
                await interactor.callWithEffect()
            } dispatchedBy: { dispatcher in
                try await dispatcher.runUntilExitOfBody()
                _ = try dispatcher.getValue(fromEffect: "1", as: Int.self)
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.FinishedValueNotMatching.self)
        }
    }
}

extension EffectTests {

    @Test
    func testGettingCancelledValue() async throws {
        try await withProbing {
            await interactor.callWithCancelledEffect()
        } dispatchedBy: { dispatcher in
            try await dispatcher.runUntilEffectCompleted("1")
            let result = try dispatcher.getCancelledValue(fromEffect: "1", as: EffectIdentifier?.self)
            #expect(result == nil)
        }
    }

    @Test
    func testGettingCancelledValueWhenFinished() async throws {
        try await withKnownIssue {
            try await withProbing {
                await interactor.callWithEffect()
            } dispatchedBy: { dispatcher in
                try await dispatcher.runUntilEffectCompleted("1")
                _ = try dispatcher.getCancelledValue(fromEffect: "1", as: EffectIdentifier?.self)
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.CancelledValueNotMatching.self)
        }
    }

    @Test
    func testGettingCancelledValueWhenCastingFails() async throws {
        try await withKnownIssue {
            try await withProbing {
                await interactor.callWithCancelledEffect()
            } dispatchedBy: { dispatcher in
                try await dispatcher.runUntilEffectCompleted("1")
                _ = try dispatcher.getCancelledValue(fromEffect: "1", as: Int.self)
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.CancelledValueNotMatching.self)
        }
    }

    @Test
    func testGettingCancelledValueWhenNotCompleted() async throws {
        try await withKnownIssue {
            try await withProbing {
                await interactor.callWithCancelledEffect()
            } dispatchedBy: { dispatcher in
                try await dispatcher.runUntilExitOfBody()
                _ = try dispatcher.getCancelledValue(fromEffect: "1", as: Int.self)
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.CancelledValueNotMatching.self)
        }
    }
}

extension EffectTests {

    final class Independent: EffectTests {

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
}

extension EffectTests.Independent {

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

extension EffectTests {

    final class Nested: EffectTests {

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
}

extension EffectTests.Nested {

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

extension EffectTests {

    @MainActor
    private final class IsolatedModel {

        private(set) var values = [EffectIdentifier: Int]()

        func tick() {
            values[.current, default: 0] += 1
        }
    }

    @MainActor
    private final class IsolatedInteractor {

        private let model: IsolatedModel

        init(model: IsolatedModel) {
            self.model = model
        }

        @discardableResult
        private func makeEffect(_ name: EffectName) -> any Effect<EffectIdentifier?> {
            #Effect(name) {
                self.model.tick()
                await #probe("1")

                guard !Task.isCancelled else {
                    return nil
                }

                self.model.tick()
                await #probe("2")
                self.model.tick()
                return .current
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

        func callWithIndependentEnumeratedEffects() {
            makeEffect(.enumerated("effect"))
            makeEffect(.enumerated("effect"))
        }

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

        func callWithAmbiguousEffects() async {
            #Effect("ambiguous") {
                #Effect("nested") { -1 }
                return 1
            }

            await #probe()
            #Effect("ambiguous") { 2 }
        }
    }
}
