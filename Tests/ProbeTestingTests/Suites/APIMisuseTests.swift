//
//  APIMisuseTests.swift
//  Probing
//
//  Created by Kamil Strzelecki on 26/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@testable import ProbeTesting
@testable import Probing
import Testing

internal struct APIMisuseTests {

    private let shell = NonSendableShell()

    @Test
    func testInstallingProbeInTask() async throws {
        try await withKnownIssue(isIntermittent: true) {
            try await withProbing(options: .attemptProbingInTasks) {
                shell.callWithProbeInTask()
            } dispatchedBy: { dispatcher in
                try await dispatcher.runUntilEverythingCompleted()
                try await Task.sleep(for: .milliseconds(10))
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.ProbeAPIMisuse.self)
        }
    }

    @Test
    func testInstallingProbesInTaskGroup() async throws {
        try await withKnownIssue(isIntermittent: true) {
            try await withProbing(options: .attemptProbingInTasks) {
                await shell.callWithProbesInTaskGroup()
            } dispatchedBy: { dispatcher in
                try await dispatcher.runUpToProbe()
                try await Task.sleep(for: .milliseconds(10))
                try await dispatcher.runUntilEverythingCompleted()
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.ProbeAPIMisuse.self)
        }
    }

    @Test
    func testInstallingProbesInAsyncLet() async throws {
        try await withKnownIssue(isIntermittent: true) {
            try await withProbing(options: .attemptProbingInTasks) {
                await shell.callWithProbesInAsyncLet()
            } dispatchedBy: { dispatcher in
                try await dispatcher.runUpToProbe()
                try await Task.sleep(for: .milliseconds(10))
                try await dispatcher.runUntilEverythingCompleted()
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.ProbeAPIMisuse.self)
        }
    }
}

extension APIMisuseTests {

    @Test
    func testCreatingEffectInTask() async throws {
        try await withKnownIssue(isIntermittent: true) {
            try await withProbing(options: .attemptProbingInTasks) {
                shell.callWithEffectInTask()
            } dispatchedBy: { dispatcher in
                try await dispatcher.runUntilEverythingCompleted()
                try await Task.sleep(for: .milliseconds(10))
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.EffectAPIMisuse.self)
        }
    }

    @Test
    func testCreatingEffectAfterInstallingProbeInTaskGroup() async throws {
        try await withKnownIssue(isIntermittent: true) {
            try await withProbing(options: .attemptProbingInTasks) {
                await shell.callWithProbeAndEffectInTaskGroup()
            } dispatchedBy: { dispatcher in
                try await dispatcher.runUpToProbe()
                try await Task.sleep(for: .milliseconds(10))
                try await dispatcher.runUntilEverythingCompleted()
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.EffectAPIMisuse.self)
        }
    }
}

extension APIMisuseTests {

    private struct NonSendableShell {

        // swiftlint:disable no_empty_block

        func callWithProbeInTask() {
            Task {
                await #probe("misuse")
            }
        }

        func callWithEffectInTask() {
            Task {
                #Effect("misuse") {}
            }
        }

        func callWithProbesInAsyncLet() async {
            async let first: Void = #probe()
            async let second: Void = #probe("misuse")
            _ = await (first, second)
        }

        func callWithProbesInTaskGroup() async {
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await #probe()
                }
                group.addTask {
                    try? await Task.sleep(for: .microseconds(10))
                    await #probe("misuse")
                }
                await group.waitForAll()
            }
        }

        func callWithProbeAndEffectInTaskGroup() async {
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await #probe()
                }
                group.addTask {
                    try? await Task.sleep(for: .microseconds(10))
                    #Effect("misuse") {}
                }
                await group.waitForAll()
            }
        }

        // swiftlint:enable no_empty_block
    }
}
