//
//  WithProbingTests.swift
//  Probing
//
//  Created by Kamil Strzelecki on 26/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@testable import ProbeTesting
@testable import Probing
import Foundation
import Testing

internal struct WithProbingTests {

    private let model: NonSendableModel
    private let interactor: NonSendableInteractor

    init() {
        self.model = .init()
        self.interactor = .init(model: model)
    }

    @Test
    func testRunningWithoutDispatches() async throws {
        try await withProbing {
            interactor.call()
        } dispatchedBy: { _ in
            #expect(model.value == 0)
        }
        #expect(model.value == 1)
    }

    @Test
    func testRunningUntilExitOfBody() async throws {
        try await withProbing {
            interactor.call()
        } dispatchedBy: { dispatcher in
            #expect(model.value == 0)
            try await dispatcher.runUntilExitOfBody()
            #expect(model.value == 1)
        }
    }

    @Test
    func testRunningUntilEverythingCompleted() async throws {
        try await withProbing {
            interactor.call()
        } dispatchedBy: { dispatcher in
            #expect(model.value == 0)
            try await dispatcher.runUntilEverythingCompleted()
            #expect(model.value == 1)
        }
    }

    @Test
    func testGettingMissingEffectValue() async throws {
        try await withKnownIssue {
            try await withProbing {
                interactor.call()
            } dispatchedBy: { dispatcher in
                do {
                    #expect(model.value == 0)
                    try dispatcher.getValue(fromEffect: "test", as: Void.self)
                } catch {
                    #expect(model.value == 0)
                    throw error
                }
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.EffectNotFound.self)
        }
        #expect(model.value == 1)
    }

    @Test
    func testGettingMissingEffectCancelledValue() async throws {
        try await withKnownIssue {
            try await withProbing {
                interactor.call()
            } dispatchedBy: { dispatcher in
                do {
                    #expect(model.value == 0)
                    try dispatcher.getCancelledValue(fromEffect: "test", as: Void.self)
                } catch {
                    #expect(model.value == 0)
                    throw error
                }
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.EffectNotFound.self)
        }
        #expect(model.value == 1)
    }

    @Test(arguments: ProbingOptions.all)
    func testRunningUpToMissingProbe(options: ProbingOptions) async throws {
        try await withKnownIssue {
            try await withProbing(options: options) {
                interactor.call()
            } dispatchedBy: { dispatcher in
                do {
                    #expect(model.value == 0)
                    try await dispatcher.runUpToProbe()
                } catch {
                    #expect(model.value == 1)
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
                interactor.call()
            } dispatchedBy: { dispatcher in
                do {
                    #expect(model.value == 0)
                    try await dispatcher.runUpToProbe(inEffect: "test")
                } catch {
                    #expect(model.value == 1)
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
                interactor.call()
            } dispatchedBy: { dispatcher in
                do {
                    #expect(model.value == 0)
                    try await dispatcher.runUntilEffectCompleted(
                        "test",
                        includingDescendants: includingDescendants
                    )
                } catch {
                    #expect(model.value == 1)
                    throw error
                }
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.ChildEffectNotCreated.self)
        }
    }
}

extension WithProbingTests {

    @Test
    func testReturningValue() async throws {
        let id = UUID()
        let value = try await withProbing {
            id
        } dispatchedBy: { dispatcher in
            try await dispatcher.runUntilExitOfBody()
        }
        #expect(id == value)
    }

    @Test
    func testThrowingEarlyInRuntime() async {
        await #expect(throws: ErrorMock.self) {
            try await withProbing {
                throw ErrorMock()
            } dispatchedBy: { dispatcher in
                try await dispatcher.runUntilExitOfBody()
                Issue.record()
            }
        }
    }

    @Test
    func testThrowingWhileTesting() async {
        await #expect(throws: ErrorMock.self) {
            try await confirmation { confirmation in
                try await withProbing {
                    confirmation()
                } dispatchedBy: { _ in
                    throw ErrorMock()
                }
            }
        }
    }
}

extension WithProbingTests {

    @CustomActor
    @Test
    func testIsolationInRuntime() async throws {
        try await withProbing {
            #expect(#isolation === CustomActor.shared)
            CustomActor.shared.assertIsolated()
        } dispatchedBy: { _ in
            // Void
        }
    }

    @CustomActor
    @Test
    func testIsolationWhileTesting() async throws {
        try await withProbing {
            // Void
        } dispatchedBy: { _ in
            #expect(#isolation === CustomActor.shared)
            CustomActor.shared.assertIsolated()
        }
    }
}

extension WithProbingTests {

    private struct ErrorMock: Error {}

    private final class NonSendableModel {

        private(set) var value = 0

        func tick() {
            value += 1
        }
    }

    private final class NonSendableInteractor {

        private let model: NonSendableModel

        init(model: NonSendableModel) {
            self.model = model
        }

        func call() {
            model.tick()
        }
    }
}
