//
//  WithProbingTests.swift
//  Probing
//
//  Created by Kamil Strzelecki on 04/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@testable import ProbeTesting
@testable import Probing
import Combine
import Foundation
import Synchronization
import Testing

internal class WithProbingTests {

    private let model: Model
    private let shell: Shell

    init() {
        self.model = .init()
        self.shell = .init(model: model)
    }
}

extension WithProbingTests {

    final class FunctionsWithoutProbes: WithProbingTests {

        @Test
        func testRunningWithoutDispatches() async throws {
            try await withProbing {
                shell.functionWithoutProbes()
            } dispatchedBy: { dispatcher in
                // Discarding reference solves issue in #expect macro with `self` capture
                _ = dispatcher
                #expect(model.value == 0)
            }
        }

        @Test
        func testRunningUntilExitOfBody() async throws {
            try await withProbing {
                shell.functionWithoutProbes()
            } dispatchedBy: { dispatcher in
                try await dispatcher.runUntilExitOfBody()
                #expect(model.value == 1)
            }
        }

        @Test
        func testRunningUntilEverythingCompleted() async throws {
            try await withProbing {
                shell.functionWithoutProbes()
            } dispatchedBy: { dispatcher in
                try await dispatcher.runUntilEverythingCompleted()
                #expect(model.value == 1)
            }
        }

        @Test
        func testRunningUpToMissingProbe() async throws {
            try await withKnownIssue {
                try await withProbing {
                    shell.functionWithoutProbes()
                } dispatchedBy: { dispatcher in
                    try await dispatcher.run(upTo: .probe)
                }
            } matching: { issue in
                issue.probingError is ProbingErrors.ProbeNotInstalled
            }
        }

        @Test
        func testRunningUntilCompletionOfMissingEffect() async throws {
            try await withKnownIssue {
                try await withProbing {
                    shell.functionWithoutProbes()
                } dispatchedBy: { dispatcher in
                    try await dispatcher.runUntilCompletion(of: "test")
                }
            } matching: { issue in
                issue.probingError is ProbingErrors.ChildEffectNotCreated
            }
        }

        @Test
        func testGettingMissingFinishedEffectValue() async throws {
            try await withKnownIssue {
                try await withProbing {
                    shell.functionWithoutProbes()
                } dispatchedBy: { dispatcher in
                    try dispatcher.getValue(ofEffect: "test", as: Void.self)
                }
            } matching: { issue in
                issue.probingError is ProbingErrors.EffectNotFound
            }
        }

        @Test
        func testGettingMissingCancelledEffectValue() async throws {
            try await withKnownIssue {
                try await withProbing {
                    shell.functionWithoutProbes()
                } dispatchedBy: { dispatcher in
                    try dispatcher.getCancelledValue(ofEffect: "test", as: Void.self)
                }
            } matching: { issue in
                issue.probingError is ProbingErrors.EffectNotFound
            }
        }
    }

    final class FunctionsWithProbes: WithProbingTests {

        @Test
        func testRunningUntilExitOfBody() async throws {
            try await withProbing {
                await shell.functionWithDefaultProbes()
            } dispatchedBy: { dispatcher in
                try await dispatcher.runUntilExitOfBody()
                #expect(model.value == 3)
            }
        }

        @Test
        func testRunningUntilEverythingCompleted() async throws {
            try await withProbing {
                await shell.functionWithDefaultProbes()
            } dispatchedBy: { dispatcher in
                try await dispatcher.runUntilEverythingCompleted()
                #expect(model.value == 3)
            }
        }

        @Test
        func testRunningUpToEveryProbe() async throws {
            try await withProbing {
                await shell.functionWithDefaultProbes()
            } dispatchedBy: { dispatcher in
                try await dispatcher.run(upTo: .probe)
                #expect(model.value == 1)

                try await dispatcher.run(upTo: .probe)
                #expect(model.value == 2)
            }
        }

        @Test(arguments: 1 ..< 3)
        func testRunningUpToProbe(withNumber number: Int) async throws {
            try await withProbing {
                await shell.functionWithNumberedProbes()
            } dispatchedBy: { dispatcher in
                try await dispatcher.run(upTo: "\(number)")
                #expect(model.value == number)
            }
        }
    }

    final class FunctionsWithEffects: WithProbingTests {}

    struct Errors {

        private let buggyShell = BuggyShell()

        @Test
        func attemptInstallingSecondProbeSimultaneously() async throws {
            try await withKnownIssue {
                try await withProbing {
                    await buggyShell.functionWithUnstructuredTaskAndTwoProbes()
                } dispatchedBy: { dispatcher in
                    try await dispatcher.run(upTo: .probe)
                    try await Task.sleep(for: .milliseconds(10))
                    try await dispatcher.runUntilEverythingCompleted()
                }
            } matching: { issue in
                issue.probingError is ProbingErrors.ProbeAPIMisuse
            }
        }

        @Test
        func attemptInstallingProbeWhileTestIsRunning() async throws {
            try await withKnownIssue {
                try await withProbing {
                    await buggyShell.functionWithUnstructuredTaskAndProbe()
                } dispatchedBy: { dispatcher in
                    try await dispatcher.runUntilExitOfBody()
                    try await Task.sleep(for: .milliseconds(10))
                    try await dispatcher.runUntilEverythingCompleted()
                }
            } matching: { issue in
                issue.probingError is ProbingErrors.ProbeAPIMisuse
            }
        }

        @Test
        func attemptInstallingProbeInTaskGroup() async throws {
            try await withKnownIssue {
                try await withProbing {
                    await buggyShell.functionWithTaskGroupAndProbes()
                } dispatchedBy: { dispatcher in
                    try await dispatcher.run(upTo: .probe)
                    try await Task.sleep(for: .milliseconds(10))
                    try await dispatcher.runUntilEverythingCompleted()
                }
            } matching: { issue in
                issue.probingError is ProbingErrors.ProbeAPIMisuse
            }
        }

        @Test
        func attemptCreatingEffectFromUnstructuredTask() async throws {
            try await withKnownIssue {
                try await withProbing {
                    await buggyShell.functionWithUnstructuredTaskAndEffect()
                } dispatchedBy: { dispatcher in
                    try await dispatcher.runUntilExitOfBody()
                    try await Task.sleep(for: .milliseconds(10))
                    try await dispatcher.runUntilEverythingCompleted()
                }
            } matching: { issue in
                issue.probingError is ProbingErrors.EffectAPIMisuse
            }
        }

        @Test
        func attemptCreatingTwoSameNamedEffects() async throws {
            try await withKnownIssue {
                try await withProbing {
                    await buggyShell.functionWithTwoSameNamedEffects()
                } dispatchedBy: { dispatcher in
                    try await dispatcher.runUntilEverythingCompleted()
                }
            } matching: { issue in
                issue.probingError is ProbingErrors.EffectIdentifierAmbiguous
            }
        }
    }
}

extension WithProbingTests {

    private final class Model: Sendable {

        private let _value = Mutex(0)

        var value: Int {
            _value.withLock { $0 }
        }

        func tick() {
            _value.withLock { $0 += 1 }
        }

        func setValue(to newValue: Int) {
            _value.withLock { $0 = newValue }
        }
    }
}

extension WithProbingTests {

    private final class Shell: Sendable {

        private let model: Model

        init(model: Model) {
            self.model = model
        }

        func functionWithoutProbes() {
            model.tick()
        }

        func functionWithDefaultProbes() async {
            model.tick()
            await #probe()
            model.tick()
            await #probe()
            model.tick()
        }

        func functionWithNumberedProbes() async {
            model.tick()
            await #probe("1")
            model.tick()
            await #probe("2")
            model.tick()
        }

        func functionWithEffect() {
            #Effect("test") {
                await #probe()
                model.tick()
            }
        }

        func functionWithCancelledEffect() {
            let effect = #Effect("test") {
                if Task.isCancelled {
                    model.setValue(to: 1)
                } else {
                    model.setValue(to: -1)
                }
            }
            effect.cancel()
        }

        func functionWithTwoEffects() {
            #Effect("1") {
                model.setValue(to: 1)
            }
            #Effect("2") {
                model.setValue(to: 2)
            }
        }

        func functionWithIndependentNestedEffects() {
            #Effect("first") {
                #Effect("second") {
                    model.setValue(to: 2)
                }
                model.setValue(to: 1)
            }
            #Effect("second") {
                model.setValue(to: -2)
            }
        }

        func functionWithDependentNestedEffects() {
            #Effect("first") {
                #Effect("second") {
                    model.tick()
                }
                model.tick()
            }
            #Effect("second") {
                model.tick()
            }
        }
    }
}

extension WithProbingTests {

    private struct BuggyShell {

        func functionWithUnstructuredTaskAndProbe() async {
            Task {
                try? await Task.sleep(for: .milliseconds(1))
                await #probe("misuse")
            }
        }

        func functionWithUnstructuredTaskAndTwoProbes() async {
            Task {
                try? await Task.sleep(for: .milliseconds(1))
                await #probe("misuse")
            }
            await #probe()
        }

        func functionWithUnstructuredTaskAndEffect() async {
            Task {
                try? await Task.sleep(for: .milliseconds(1))
                #Effect("misuse") {
                    await #probe()
                }
            }
        }

        func functionWithTaskGroupAndProbes() async {
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await #probe()
                }
                group.addTask {
                    try? await Task.sleep(for: .milliseconds(1))
                    await #probe("misuse")
                }
                await group.waitForAll()
            }
        }

        func functionWithTwoSameNamedEffects() async {
            #Effect("misuse") {
                await #probe()
            }
            #Effect("misuse") {
                await #probe()
            }
        }

        func functionWithTwoSameNamedEffectsAnd() async {
            #Effect("misuse") {
                try? await Task.sleep(for: .milliseconds(1))
                await #probe()
            }
            #Effect("misuse") {
                try? await Task.sleep(for: .milliseconds(1))
                await #probe()
            }
        }
    }
}

extension Issue {

    fileprivate var probingError: Error? {
        (error as? RecordedError)?.underlying
    }
}
