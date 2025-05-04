//
//  ProbingOptionsTests.swift
//  Probing
//
//  Created by Kamil Strzelecki on 27/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@testable import ProbeTesting
@testable import Probing
import Algorithms
import PrincipleConcurrency
import Testing

internal struct ProbingOptionsTests {

    private let model: IsolatedModel
    private let interactor: IsolatedInteractor

    init() async {
        self.model = .init()
        self.interactor = await .init(model: model)
    }

    @Test
    func testAttemptingProbingInInTask() async throws {
        try await withProbing(options: .attemptProbingInTasks) {
            await interactor.callWithTask()
        } dispatchedBy: { dispatcher in
            await #expect(model.value == 0)
            try await dispatcher.runUpToProbe()
            await #expect(model.value == 1)
            try await dispatcher.runUpToProbe()
            await #expect(model.value == 2)
            try await dispatcher.runUntilExitOfBody()
            await #expect(model.value == 3)

            await #expect(model.effectCompletions.isEmpty)
            try await dispatcher.runUpToProbe(inEffect: "1-1")
            try await dispatcher.runUntilEffectCompleted("1-1")
            let first = try dispatcher.getValue(fromEffect: "1-1", as: EffectIdentifier.self)

            #expect(first == "1-1")
            await #expect(model.effectCompletions == [
                EffectCompletion(declaredID: "1-1", runtimeID: "1-1")
            ])

            try await dispatcher.runUpToProbe(inEffect: "1-2")
            try await dispatcher.runUntilEffectCompleted("1-2")
            let second = try dispatcher.getValue(fromEffect: "1-2", as: EffectIdentifier.self)

            #expect(second == "1-2")
            await #expect(model.effectCompletions == [
                EffectCompletion(declaredID: "1-1", runtimeID: "1-1"),
                EffectCompletion(declaredID: "1-2", runtimeID: "1-2")
            ])
        }
    }
}

extension ProbingOptionsTests {

    private static let ignoringProbesInTasksArguments: [Argument] =
        CollectionOfOne((.root, ProbingErrors.ProbeNotInstalled.self))
        + ignoringEffectsInTasksArguments.map { ($0, ProbingErrors.ChildEffectNotCreated.self) }

    @Test(arguments: ignoringProbesInTasksArguments)
    func testIgnoringProbesInTask(argument: Argument) async throws {
        try await withKnownIssue {
            try await withProbing(options: .ignoreProbingInTasks) {
                await interactor.callWithTask()
            } dispatchedBy: { dispatcher in
                do {
                    await #expect(model.value == 0)
                    try await dispatcher.runUpToProbe(inEffect: argument.effectID)
                } catch {
                    await #expect(model.value == 3)
                    throw error
                }
            }
        } matching: { issue in
            issue.didRecordError(argument.errorType)
        }
        await checkEffectsWillEventuallyComplete(callsCount: 1)
    }

    @Test(arguments: ignoringProbesInTasksArguments)
    func testIgnoringProbesInTaskGroup(argument: Argument) async throws {
        try await withKnownIssue {
            try await withProbing(options: .ignoreProbingInTasks) {
                await interactor.callWithTaskGroup()
            } dispatchedBy: { dispatcher in
                do {
                    await #expect(model.value == 0)
                    try await dispatcher.runUpToProbe(inEffect: argument.effectID)
                } catch {
                    await #expect(model.value == 6)
                    throw error
                }
            }
        } matching: { issue in
            issue.didRecordError(argument.errorType)
        }
        await checkEffectsWillEventuallyComplete(callsCount: 2)
    }

    @Test(arguments: ignoringProbesInTasksArguments)
    func testIgnoringProbesInAsyncLet(argument: Argument) async throws {
        try await withKnownIssue {
            try await withProbing(options: .ignoreProbingInTasks) {
                await interactor.callWithAsyncLet()
            } dispatchedBy: { dispatcher in
                do {
                    await #expect(model.value == 0)
                    try await dispatcher.runUpToProbe(inEffect: argument.effectID)
                } catch {
                    await #expect(model.value == 6)
                    throw error
                }
            }
        } matching: { issue in
            issue.didRecordError(argument.errorType)
        }
        await checkEffectsWillEventuallyComplete(callsCount: 2)
    }
}

extension ProbingOptionsTests {

    private static let ignoringEffectsInTasksArguments: [EffectIdentifier] =
        product(1 ..< 4, 1 ..< 3).map { "\($0)-\($1)" }

    @Test(arguments: ignoringEffectsInTasksArguments)
    func testIgnoringEffectsInTask(withID id: EffectIdentifier) async throws {
        try await withKnownIssue {
            try await withProbing(options: .ignoreProbingInTasks) {
                await interactor.callWithTask()
            } dispatchedBy: { dispatcher in
                do {
                    await #expect(model.value == 0)
                    try await dispatcher.runUntilEffectCompleted(id)
                } catch {
                    await #expect(model.value == 3)
                    throw error
                }
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.ChildEffectNotCreated.self)
        }
        await checkEffectsWillEventuallyComplete(callsCount: 1)
    }

    @Test(arguments: ignoringEffectsInTasksArguments)
    func testIgnoringEffectsInTaskGroup(withID id: EffectIdentifier) async throws {
        try await withKnownIssue {
            try await withProbing(options: .ignoreProbingInTasks) {
                await interactor.callWithTaskGroup()
            } dispatchedBy: { dispatcher in
                do {
                    await #expect(model.value == 0)
                    try await dispatcher.runUntilEffectCompleted(id)
                } catch {
                    await #expect(model.value == 6)
                    throw error
                }
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.ChildEffectNotCreated.self)
        }
        await checkEffectsWillEventuallyComplete(callsCount: 2)
    }

    @Test(arguments: ignoringEffectsInTasksArguments)
    func testIgnoringEffectsInAsyncLet(withID id: EffectIdentifier) async throws {
        try await withKnownIssue {
            try await withProbing(options: .ignoreProbingInTasks) {
                await interactor.callWithAsyncLet()
            } dispatchedBy: { dispatcher in
                do {
                    await #expect(model.value == 0)
                    try await dispatcher.runUntilEffectCompleted(id)
                } catch {
                    await #expect(model.value == 6)
                    throw error
                }
            }
        } matching: { issue in
            issue.didRecordError(ProbingErrors.ChildEffectNotCreated.self)
        }
        await checkEffectsWillEventuallyComplete(callsCount: 2)
    }
}

extension ProbingOptionsTests {

    private func checkEffectsWillEventuallyComplete(callsCount: Int) async {
        let expectation = (1 ... callsCount).reduce(into: Set<EffectCompletion>()) { result, call in
            result.formUnion([
                EffectCompletion(declaredID: "\(call)-1", runtimeID: .root),
                EffectCompletion(declaredID: "\(call)-2", runtimeID: .root)
            ])
        }

        try? await withTimeout(.seconds(1)) {
            func keepSampling() async -> Bool {
                await model.effectCompletions != expectation
            }
            while await keepSampling() {
                try await Task.sleep(for: .milliseconds(10))
            }
        }

        await #expect(model.effectCompletions == expectation)
    }
}

extension ProbingOptionsTests {

    typealias Argument = (effectID: EffectIdentifier, errorType: any Error.Type)

    private struct EffectCompletion: Hashable {

        let declaredID: EffectIdentifier
        let runtimeID: EffectIdentifier
    }

    @MainActor
    private final class IsolatedModel {

        private(set) var value = 0
        private(set) var effectCompletions = Set<EffectCompletion>()

        func tick() {
            value += 1
        }

        func completeEffect(declaredID: EffectIdentifier) {
            let completion = EffectCompletion(declaredID: declaredID, runtimeID: .current)
            effectCompletions.insert(completion)
        }
    }

    @MainActor
    private final class IsolatedInteractor {

        private let model: IsolatedModel

        init(model: IsolatedModel) {
            self.model = model
        }

        private func call(_ id: Int) async {
            model.tick()
            #Effect("\(id)-1") {
                await #probe()
                self.model.completeEffect(declaredID: "\(id)-1")
                return EffectIdentifier.current
            }

            await #probe()
            model.tick()
            #ConcurrentEffect("\(id)-2") {
                await #probe()
                await self.model.completeEffect(declaredID: "\(id)-2")
                return EffectIdentifier.current
            }

            await #probe()
            model.tick()
        }

        func callWithTask() async {
            let task = Task {
                await call(1)
            }
            await task.value
        }

        func callWithTaskGroup() async {
            await withTaskGroup { group in
                group.addTask {
                    await self.call(1)
                }
                group.addTask {
                    await self.call(2)
                }
                await group.waitForAll()
            }
        }

        func callWithAsyncLet() async {
            async let first: Void = call(1)
            async let second: Void = call(2)
            _ = await (first, second)
        }
    }
}
