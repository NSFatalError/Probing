//
//  AnyEffect.swift
//  Probing
//
//  Created by Kamil Strzelecki on 07/03/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

/// Type-erased wrapper for ``Effect``, providing conformance to `Equatable` and `Hashable`.
///
public struct AnyEffect<Success: Sendable>: Effect, Hashable {

    public let task: Task<Success, Never>

    public init(_ effect: some Effect<Success>) {
        self.task = effect.task
    }
}

extension Effect {

    /// Wraps this effect with a type eraser, making it `Equatable` and `Hashable`.
    ///
    /// - Returns: An instance of ``AnyEffect`` wrapping this effect.
    ///
    public func eraseToAnyEffect() -> AnyEffect<Success> {
        AnyEffect(self)
    }
}
