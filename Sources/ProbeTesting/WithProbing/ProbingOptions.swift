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

    typealias Underlying = Probing.ProbingOptions

    var underlying: Underlying {
        .init(rawValue: rawValue)
    }

    init(_ options: Underlying) {
        self.rawValue = options.rawValue
    }
}

extension ProbingOptions {

    public static let attemptProbingInTasks = Self(.attemptProbingInTasks)
    public static let ignoreProbingInTasks = Self(.ignoreProbingInTasks)
}
