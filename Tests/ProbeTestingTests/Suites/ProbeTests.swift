//
//  ProbeTests.swift
//  Probing
//
//  Created by Kamil Strzelecki on 26/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@testable import ProbeTesting
@testable import Probing
import Testing

internal struct ProbeTests {

    private let model: NonSendableModel
    private let interactor: NonSendableInteractor

    init() {
        self.model = .init()
        self.interactor = .init(model: model)
    }

    @Test
    func testRunningThroughDefaultProbes() async throws {
        try await withProbing {
            await interactor.callWithDefaultProbes()
        } dispatchedBy: { dispatcher in
            #expect(model.value == 0)
            try await dispatcher.runUpToProbe()
            #expect(model.value == 1)
            try await dispatcher.runUpToProbe()
            #expect(model.value == 2)
            try await dispatcher.runUntilExitOfBody()
            #expect(model.value == 3)
        }
    }

    @Test
    func testRunningThroughNamedProbes() async throws {
        try await withProbing {
            await interactor.callWithNamedProbes()
        } dispatchedBy: { dispatcher in
            #expect(model.value == 0)
            try await dispatcher.runUpToProbe("1")
            #expect(model.value == 1)
            try await dispatcher.runUpToProbe("2")
            #expect(model.value == 2)
            try await dispatcher.runUntilExitOfBody()
            #expect(model.value == 3)
        }
    }

    @Test(arguments: 1 ..< 3)
    func testRunningToNamedProbe(withNumber number: Int) async throws {
        try await withProbing {
            await interactor.callWithNamedProbes()
        } dispatchedBy: { dispatcher in
            #expect(model.value == 0)
            try await dispatcher.runUpToProbe("\(number)")
            #expect(model.value == number)
            try await dispatcher.runUntilExitOfBody()
            #expect(model.value == 3)
        }
    }
}

extension ProbeTests {

    @Test
    func testRunningWithoutDispatches() async throws {
        try await withProbing {
            await interactor.callWithDefaultProbes()
        } dispatchedBy: { _ in
            #expect(model.value == 0)
        }
        #expect(model.value == 3)
    }

    @Test
    func testRunningUntilExitOfBody() async throws {
        try await withProbing {
            await interactor.callWithDefaultProbes()
        } dispatchedBy: { dispatcher in
            #expect(model.value == 0)
            try await dispatcher.runUntilExitOfBody()
            #expect(model.value == 3)
        }
    }

    @Test
    func testRunningUntilEverythingCompleted() async throws {
        try await withProbing {
            await interactor.callWithDefaultProbes()
        } dispatchedBy: { dispatcher in
            #expect(model.value == 0)
            try await dispatcher.runUntilEverythingCompleted()
            #expect(model.value == 3)
        }
    }

    @Test
    func testGettingMissingEffectValue() async throws {
        try await withKnownIssue {
            try await withProbing {
                await interactor.callWithDefaultProbes()
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
        #expect(model.value == 3)
    }

    @Test
    func testGettingMissingEffectCancelledValue() async throws {
        try await withKnownIssue {
            try await withProbing {
                await interactor.callWithDefaultProbes()
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
        #expect(model.value == 3)
    }

    @Test(arguments: ProbingOptions.all)
    func testRunningUpToMissingProbe(options: ProbingOptions) async throws {
        try await withKnownIssue {
            try await withProbing(options: options) {
                await interactor.callWithNamedProbes()
            } dispatchedBy: { dispatcher in
                do {
                    #expect(model.value == 0)
                    try await dispatcher.runUpToProbe("3")
                } catch {
                    #expect(model.value == 3)
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
                await interactor.callWithNamedProbes()
            } dispatchedBy: { dispatcher in
                do {
                    #expect(model.value == 0)
                    try await dispatcher.runUpToProbe(inEffect: "test")
                } catch {
                    #expect(model.value == 3)
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
                await interactor.callWithNamedProbes()
            } dispatchedBy: { dispatcher in
                do {
                    #expect(model.value == 0)
                    try await dispatcher.runUntilEffectCompleted(
                        "test",
                        includingDescendants: includingDescendants
                    )
                } catch {
                    #expect(model.value == 3)
                    throw error
                }
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.ChildEffectNotCreated.self)
        }
    }
}

extension ProbeTests {

    @Test
    func testThrowingLateInRuntime() async {
        await #expect(throws: ErrorMock.self) {
            try await withProbing {
                await interactor.callWithDefaultProbes()
                throw ErrorMock()
            } dispatchedBy: { dispatcher in
                try await dispatcher.runUntilExitOfBody()
                Issue.record()
            }
        }
    }
}

extension ProbeTests {

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

        func callWithDefaultProbes() async {
            model.tick()
            await #probe()
            model.tick()
            await #probe()
            model.tick()
        }

        func callWithNamedProbes() async {
            model.tick()
            await #probe("1")
            model.tick()
            await #probe("2")
            model.tick()
        }
    }
}
