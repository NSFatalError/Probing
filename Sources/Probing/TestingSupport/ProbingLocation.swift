//
//  ProbingLocation.swift
//  Probing
//
//  Created by Kamil Strzelecki on 25/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

internal struct ProbingLocation: CustomStringConvertible {

    let fileID: String
    let line: Int
    let column: Int

    var description: String {
        "\(fileID):\(line):\(column)"
    }
}
