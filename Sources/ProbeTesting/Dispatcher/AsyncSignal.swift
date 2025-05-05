//
//  AsyncSignal.swift
//  Probing
//
//  Created by Kamil Strzelecki on 05/05/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

internal struct AsyncSignal {

    private typealias Underlying = AsyncStream<Void>

    private let stream: Underlying
    private let continuation: Underlying.Continuation

    init() {
        let (stream, continuation) = Underlying.makeStream()
        self.stream = stream
        self.continuation = continuation
    }

    func wait() async {
        // swiftlint:disable:next no_empty_block
        for await _ in stream {}
    }

    func finish() {
        continuation.finish()
    }
}
