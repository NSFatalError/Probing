//
//  AnyEffect.swift
//  Probing
//
//  Created by Kamil Strzelecki on 07/03/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

public struct AnyEffect<Success: Sendable>: Effect, Hashable {

    public let task: Task<Success, Never>

    public init(_ effect: some Effect<Success>) {
        self.task = effect.task
    }
}

extension Effect {

    public func erasedToAnyEffect() -> AnyEffect<Success> {
        AnyEffect(self)
    }
}
