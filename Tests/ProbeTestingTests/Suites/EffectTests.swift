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

internal class EffectTests {

    let model: IsolatedModel
    let interactor: IsolatedInteractor

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

    @MainActor
    final class IsolatedModel {

        private(set) var values = [EffectIdentifier: Int]()

        func tick() {
            values[.current, default: 0] += 1
        }
    }

    @MainActor
    final class IsolatedInteractor {

        let model: IsolatedModel

        init(model: IsolatedModel) {
            self.model = model
        }

        @discardableResult
        func makeEffect(_ name: EffectName) -> any Effect<EffectIdentifier?> {
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
