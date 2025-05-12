//
//  AsyncSequenceTests.swift
//  Probing
//
//  Created by Kamil Strzelecki on 26/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@testable import ProbeTesting
@testable import Probing
import Testing

internal struct AsyncSequenceTests {

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
            let first = await interactor.yield()
            try await dispatcher.runUpToProbe()
            #expect(first == 0)
            await #expect(model.value == 1)

            let second = await interactor.yield()
            try await dispatcher.runUpToProbe()
            #expect(second == 1)
            await #expect(model.value == 2)

            let final = await interactor.finish()
            try await dispatcher.runUpToProbe("1")
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

            let first = await interactor.yield()
            try await dispatcher.runUpToProbe(inEffect: "stream")
            #expect(first == 2)
            await #expect(model.value == 3)

            let second = await interactor.yield()
            try await dispatcher.runUpToProbe(inEffect: "stream")
            #expect(second == 3)
            await #expect(model.value == 4)

            let final = await interactor.finish()
            try await dispatcher.runUpToProbe("stream.1")
            #expect(final == 4)
            await #expect(model.value == 6)

            try await dispatcher.runUntilEffectCompleted("stream")
            await #expect(model.value == 7)

            try await dispatcher.runUntilEverythingCompleted()
            await #expect(model.value == 8)
        }
    }
}

extension AsyncSequenceTests {

    @Test
    func testRunningUpToProbe() async throws {
        try await withProbing {
            await interactor.callWithAsyncStream()
        } dispatchedBy: { dispatcher in
            let result = await interactor.finish()
            try await dispatcher.runUpToProbe()
            #expect(result == 0)
            await #expect(model.value == 1)
        }
    }

    @Test
    func testRunningUpToNamedProbe() async throws {
        try await withProbing {
            await interactor.callWithAsyncStream()
        } dispatchedBy: { dispatcher in
            let result = await interactor.finish()
            try await dispatcher.runUpToProbe("1")
            #expect(result == 0)
            await #expect(model.value == 2)
        }
    }

    @Test
    func testRunningUpToProbeInEffect() async throws {
        try await withProbing {
            await interactor.callWithAsyncStreamInEffect()
        } dispatchedBy: { dispatcher in
            let result = await interactor.finish()
            try await dispatcher.runUpToProbe(inEffect: "stream")
            #expect(result == 0)
            await #expect(model.value == 2)
        }
    }
}

extension AsyncSequenceTests {

    @Test
    func testRunningUntilExitOfBody() async throws {
        try await withProbing {
            await interactor.callWithAsyncStream()
        } dispatchedBy: { dispatcher in
            let result = await interactor.finish()
            try await dispatcher.runUntilExitOfBody()
            #expect(result == 0)
            await #expect(model.value == 3)
        }
    }

    @Test
    func testRunningUntilEverythingCompleted() async throws {
        try await withProbing {
            await interactor.callWithAsyncStreamInEffect()
        } dispatchedBy: { dispatcher in
            let result = await interactor.finish()
            try await dispatcher.runUntilEverythingCompleted()
            #expect(result == 0)
            await #expect(model.value == 6)
        }
    }

    @Test
    func testRunningUntilEffectCompleted() async throws {
        try await withProbing {
            await interactor.callWithAsyncStreamInEffect()
        } dispatchedBy: { dispatcher in
            let result = await interactor.finish()
            try await dispatcher.runUntilEffectCompleted("stream")
            #expect(result == 0)
            await #expect(model.value == 4)
        }
    }
}

extension AsyncSequenceTests {

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
