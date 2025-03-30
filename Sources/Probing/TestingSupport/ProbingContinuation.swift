//
//  ProbingContinuation.swift
//  Probing
//
//  Created by Kamil Strzelecki on 25/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

internal struct ProbingContinuation<ID: ProbingIdentifierProtocol> {

    typealias Underlying = CheckedContinuation<Void, Never>

    let backtrace: ProbingBacktrace<ID>
    private let underlying: Underlying

    init(
        id: ID,
        location: ProbingLocation,
        underlying: Underlying
    ) {
        self.backtrace = .init(id: id, location: location)
        self.underlying = underlying
    }

    func resume() {
        underlying.resume()
    }
}
