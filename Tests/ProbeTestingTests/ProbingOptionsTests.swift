//
//  ProbingOptionsTests.swift
//  Probing
//
//  Created by Kamil Strzelecki on 27/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@testable import ProbeTesting
@testable import Probing
import Testing

internal struct ProbingOptionsTests {

    private let model: IsolatedModel
    private let shell: IsolatedShell

    init() async {
        self.model = .init()
        self.shell = await .init(model: model)
    }

    @Test
    func testProbingInInTask() async throws {
        try await withProbing(options: .attemptProbingInTasks) {
            await shell.callWithTask()
        } dispatchedBy: { dispatcher in
            await #expect(model.value == 0)
            try await dispatcher.runUpToProbe()
            await #expect(model.value == 1)
            try await dispatcher.runUpToProbe()
            await #expect(model.value == 2)
            try await dispatcher.runUntilExitOfBody()
            await #expect(model.value == 3)
        }
    }

    @Test
    func testIgnoringProbingInTask() async throws {
        try await withKnownIssue {
            try await withProbing(options: .ignoreProbingInTasks) {
                await shell.callWithTask()
            } dispatchedBy: { dispatcher in
                do {
                    await #expect(model.value == 0)
                    try await dispatcher.runUpToProbe()
                } catch {
                    await #expect(model.value == 3)
                    throw error
                }
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.ProbeNotInstalled.self)
        }
    }

    @Test
    func testIgnoringProbingInTaskGroup() async throws {
        try await withKnownIssue {
            try await withProbing(options: .ignoreProbingInTasks) {
                await shell.callWithTaskGroup()
            } dispatchedBy: { dispatcher in
                do {
                    await #expect(model.value == 0)
                    try await dispatcher.runUpToProbe()
                } catch {
                    await #expect(model.value == 6)
                    throw error
                }
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.ProbeNotInstalled.self)
        }
    }

    @Test
    func testIgnoringProbingInAsyncLet() async throws {
        try await withKnownIssue {
            try await withProbing(options: .ignoreProbingInTasks) {
                await shell.callWithAsyncLet()
            } dispatchedBy: { dispatcher in
                do {
                    await #expect(model.value == 0)
                    try await dispatcher.runUpToProbe()
                } catch {
                    await #expect(model.value == 6)
                    throw error
                }
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.ProbeNotInstalled.self)
        }
    }
}

extension ProbingOptionsTests {

    @MainActor
    private final class IsolatedModel {

        var value = 0

        func tick() {
            value += 1
        }
    }

    @MainActor
    private final class IsolatedShell {

        private let model: IsolatedModel

        init(model: IsolatedModel) {
            self.model = model
        }

        private func call() async {
            model.tick()
            await #probe()
            model.tick()
            await #probe()
            model.tick()
        }

        func callWithTask() async {
            let task = Task {
                await call()
            }
            await task.value
        }

        func callWithTaskGroup() async {
            await withTaskGroup { group in
                group.addTask {
                    await self.call()
                }
                group.addTask {
                    await self.call()
                }
                await group.waitForAll()
            }
        }

        func callWithAsyncLet() async {
            async let first: Void = call()
            async let second: Void = call()
            _ = await (first, second)
        }
    }
}
