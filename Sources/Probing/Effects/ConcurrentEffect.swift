//
//  ConcurrentEffect.swift
//  Probing
//
//  Created by Kamil Strzelecki on 16/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@available(*, unavailable, message: "Use #Effect with @concurrent attribute instead")
@discardableResult
@freestanding(expression)
public macro ConcurrentEffect<Success: Sendable>(
    _ name: EffectName,
    preprocessorFlag: StaticString = "DEBUG",
    priority: TaskPriority? = nil,
    operation: sending @escaping () async -> Success
) -> any Effect<Success> = #externalMacro(
    module: "ProbingMacros",
    type: "EffectMacro"
)
