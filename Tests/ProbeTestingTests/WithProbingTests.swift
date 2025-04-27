//
//  WithProbingTests.swift
//  Probing
//
//  Created by Kamil Strzelecki on 26/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@testable import ProbeTesting
@testable import Probing
import Testing

internal struct WithProbingTests {

    private let model: NonSendableModel
    private let shell: NonSendableShell

    init() {
        self.model = .init()
        self.shell = .init(model: model)
    }

    @Test
    func testRunningWithoutDispatches() async throws {
        try await withProbing {
            shell.call()
        } dispatchedBy: { _ in
            #expect(model.value == 0)
        }
        #expect(model.value == 1)
    }

    @Test
    func testRunningUntilExitOfBody() async throws {
        try await withProbing {
            shell.call()
        } dispatchedBy: { dispatcher in
            #expect(model.value == 0)
            try await dispatcher.runUntilExitOfBody()
            #expect(model.value == 1)
        }
    }

    @Test
    func testRunningUntilEverythingCompleted() async throws {
        try await withProbing {
            shell.call()
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
                shell.call()
            } dispatchedBy: { dispatcher in
                #expect(model.value == 0)
                try dispatcher.getValue(fromEffect: "test", as: Void.self)
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
                shell.call()
            } dispatchedBy: { dispatcher in
                #expect(model.value == 0)
                try dispatcher.getCancelledValue(fromEffect: "test", as: Void.self)
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
                shell.call()
            } dispatchedBy: { dispatcher in
                #expect(model.value == 0)
                try await dispatcher.runUpToProbe()
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.ProbeNotInstalled.self)
        }
        #expect(model.value == 1)
    }

    @Test(arguments: ProbingOptions.all)
    func testRunningUpToMissingProbeInEffect(options: ProbingOptions) async throws {
        try await withKnownIssue {
            try await withProbing(options: options) {
                shell.call()
            } dispatchedBy: { dispatcher in
                #expect(model.value == 0)
                try await dispatcher.runUpToProbe(inEffect: "test")
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.ChildEffectNotCreated.self)
        }
        #expect(model.value == 1)
    }

    @Test(
        arguments: ProbingOptions.all,
        [true, false]
    )
    func testRunningUntilMissingEffectCompleted(
        options: ProbingOptions,
        includingDescendants: Bool
    ) async throws {
        try await withKnownIssue {
            try await withProbing(options: options) {
                shell.call()
            } dispatchedBy: { dispatcher in
                #expect(model.value == 0)
                try await dispatcher.runUntilEffectCompleted(
                    "test",
                    includingDescendants: includingDescendants
                )
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.ChildEffectNotCreated.self)
        }
        #expect(model.value == 1)
    }
}

extension WithProbingTests {

    private final class NonSendableModel {

        var value = 0

        func tick() {
            value += 1
        }
    }

    private final class NonSendableShell {

        private let model: NonSendableModel

        init(model: NonSendableModel) {
            self.model = model
        }

        func call() {
            model.tick()
        }
    }
}
