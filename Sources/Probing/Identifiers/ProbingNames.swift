//
//  ProbingNames.swift
//  Probing
//
//  Created by Kamil Strzelecki on 24/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

internal enum ProbingNames {

    static func preconditionValid(
        _ rawValue: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        precondition(
            !rawValue.isEmpty,
            "Name must not be empty.",
            file: file,
            line: line
        )
        precondition(
            !rawValue.contains("."),
            "Name must not contain any '.' characters.",
            file: file,
            line: line
        )
    }
}
