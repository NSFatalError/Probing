//
//  ProbingOptions.swift
//  Probing
//
//  Created by Kamil Strzelecki on 27/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@testable import Probing
import Testing

extension ProbingOptions {

    static let all: [ProbingOptions] = [
        .init(),
        .ignoreProbingInTasks
    ]
}

extension ProbingOptions: CustomTestStringConvertible {

    public var testDescription: String {
        switch self {
        case .attemptProbingInTasks:
            "attemptProbingInTasks"
        case .ignoreProbingInTasks:
            "ignoreProbingInTasks"
        default:
            String(describing: self)
        }
    }
}
