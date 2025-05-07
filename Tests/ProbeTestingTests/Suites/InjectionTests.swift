//
//  InjectionTests.swift
//  Probing
//
//  Created by Kamil Strzelecki on 26/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@testable import ProbeTesting
@testable import Probing
import Testing

internal struct InjectionTests {

    private let model: IsolatedModel
    private let interactor: IsolatedInteractor

    init() async {
        self.model = .init()
        self.interactor = await .init(model: model)
    }

    @Test
    func testRunningThroughAsyncStream() async throws {
        try await withProbing {
            await interactor.callWithAsyncStream()
        } dispatchedBy: { dispatcher in
            let first = try await dispatcher.runUpToProbe {
                await interactor.yield()
            }
            #expect(first == 0)
            await #expect(model.value == 1)

            let second = try await dispatcher.runUpToProbe {
                await interactor.yield()
            }
            #expect(second == 1)
            await #expect(model.value == 2)

            let final = try await dispatcher.runUpToProbe("1") {
                await interactor.finish()
            }
            #expect(final == 2)
            await #expect(model.value == 4)

            try await dispatcher.runUntilExitOfBody()
            await #expect(model.value == 5)
        }
    }

    @Test
    func testRunningThroughAsyncStreamInEffect() async throws {
        try await withProbing {
            await interactor.callWithAsyncStreamInEffect()
        } dispatchedBy: { dispatcher in
            try await dispatcher.runUpToProbe("2")
            await #expect(model.value == 2)

            let first = try await dispatcher.runUpToProbe(inEffect: "stream") {
                await interactor.yield()
            }
            #expect(first == 2)
            await #expect(model.value == 3)

            let second = try await dispatcher.runUpToProbe(inEffect: "stream") {
                await interactor.yield()
            }
            #expect(second == 3)
            await #expect(model.value == 4)

            let final = try await dispatcher.runUpToProbe("stream.1") {
                await interactor.finish()
            }
            #expect(final == 4)
            await #expect(model.value == 6)

            try await dispatcher.runUntilEffectCompleted("stream")
            await #expect(model.value == 7)

            try await dispatcher.runUntilEverythingCompleted()
            await #expect(model.value == 8)
        }
    }
}

extension InjectionTests {

    @Test
    func testRunningUpToProbe() async throws {
        try await withProbing {
            await interactor.callWithAsyncStream()
        } dispatchedBy: { dispatcher in
            let result = try await dispatcher.runUpToProbe {
                await interactor.finish()
            }
            #expect(result == 0)
            await #expect(model.value == 1)
        }
    }

    @Test
    func testRunningUpToNamedProbe() async throws {
        try await withProbing {
            await interactor.callWithAsyncStream()
        } dispatchedBy: { dispatcher in
            let result = try await dispatcher.runUpToProbe("1") {
                await interactor.finish()
            }
            #expect(result == 0)
            await #expect(model.value == 2)
        }
    }

    @Test
    func testRunningUpToProbeInEffect() async throws {
        try await withProbing {
            await interactor.callWithAsyncStreamInEffect()
        } dispatchedBy: { dispatcher in
            let result = try await dispatcher.runUpToProbe(inEffect: "stream") {
                await interactor.finish()
            }
            #expect(result <= 1)
            await #expect(model.value == 2)
        }
    }
}

extension InjectionTests {

    @Test
    func testRunningUntilExitOfBody() async throws {
        try await withProbing {
            await interactor.callWithAsyncStream()
        } dispatchedBy: { dispatcher in
            let result = try await dispatcher.runUntilExitOfBody {
                await interactor.finish()
            }
            #expect(result == 0)
            await #expect(model.value == 3)
        }
    }

    @Test
    func testRunningUntilEverythingCompleted() async throws {
        try await withProbing {
            await interactor.callWithAsyncStreamInEffect()
        } dispatchedBy: { dispatcher in
            let result = try await dispatcher.runUntilEverythingCompleted {
                await interactor.finish()
            }
            #expect(result <= 3)
            await #expect(model.value == 6)
        }
    }

    @Test
    func testRunningUntilEffectCompleted() async throws {
        try await withProbing {
            await interactor.callWithAsyncStreamInEffect()
        } dispatchedBy: { dispatcher in
            let result = try await dispatcher.runUntilEffectCompleted("stream") {
                await interactor.finish()
            }
            #expect(result <= 1)
            await #expect(model.value == 4)
        }
    }
}

extension InjectionTests {

    @Test
    func testThrowing() async {
        await #expect(throws: ErrorMock.self) {
            try await withProbing {
                await interactor.callWithAsyncStream()
            } dispatchedBy: { dispatcher in
                try await dispatcher.runUpToProbe("unknown") {
                    throw ErrorMock()
                }
                Issue.record()
            }
        }
    }

    @CustomActor
    @Test
    func testIsolation() async throws {
        try await withProbing {
            await interactor.callWithAsyncStream()
        } dispatchedBy: { dispatcher in
            try await dispatcher.runUpToProbe {
                #expect(#isolation === CustomActor.shared)
                CustomActor.shared.assertIsolated()
                _ = await interactor.finish()
            }
        }
    }
}

extension InjectionTests {

    private struct ErrorMock: Error {}

    @MainActor
    private final class IsolatedModel {

        private(set) var value = 0

        func tick() {
            value += 1
        }
    }

    @MainActor
    private final class IsolatedInteractor {

        private typealias Stream = AsyncStream<Void>

        private let stream: Stream
        private let continuation: Stream.Continuation
        private let model: IsolatedModel

        init(model: IsolatedModel) {
            let (stream, continuation) = Stream.makeStream(bufferingPolicy: .unbounded)
            self.stream = stream
            self.continuation = continuation
            self.model = model
        }

        func callWithAsyncStream() async {
            for await _ in stream {
                model.tick()
                await #probe()
            }
            model.tick()
            await #probe()
            model.tick()
            await #probe("1")
            model.tick()
        }

        func callWithAsyncStreamInEffect() async {
            #Effect("stream") {
                await self.callWithAsyncStream()
            }
            model.tick()
            await #probe()
            model.tick()
            await #probe("2")
            model.tick()
        }

        func yield() -> Int {
            continuation.yield()
            return model.value
        }

        func finish() -> Int {
            continuation.finish()
            return model.value
        }
    }
}
