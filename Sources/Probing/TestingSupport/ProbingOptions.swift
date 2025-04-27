//
//  ProbingOptions.swift
//  Probing
//
//  Created by Kamil Strzelecki on 26/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

public struct ProbingOptions: OptionSet, Sendable {

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

extension ProbingOptions {

    public static let attemptProbingInTasks = Self([])
    public static let ignoreProbingInTasks = Self(rawValue: 1 << 0)

    static var current: Self {
        ProbingCoordinator.current?.options ?? .attemptProbingInTasks
    }
}
