//
//  ProbingOptions.swift
//  Probing
//
//  Created by Kamil Strzelecki on 28/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Probing

public struct ProbingOptions: OptionSet, Sendable {

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

extension ProbingOptions {

    var underlying: _ProbingOptions {
        .init(rawValue: rawValue)
    }

    init(_ options: _ProbingOptions) {
        self.rawValue = options.rawValue
    }
}

extension ProbingOptions {

    public static let attemptProbingInTasks = Self(.attemptProbingInTasks)
    public static let ignoreProbingInTasks = Self(.ignoreProbingInTasks)
}
