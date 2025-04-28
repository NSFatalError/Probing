//
//  ProbingOptions.swift
//  Probing
//
//  Created by Kamil Strzelecki on 26/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

package struct ProbingOptions: OptionSet, Sendable {

    package let rawValue: Int

    package init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

extension ProbingOptions {

    package static let attemptProbingInTasks = Self([])
    package static let ignoreProbingInTasks = Self(rawValue: 1 << 0)
}

extension ProbingOptions {

    static var current: Self {
        ProbingCoordinator.current?.options ?? .attemptProbingInTasks
    }
}
