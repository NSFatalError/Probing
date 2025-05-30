//
//  RecordedError.swift
//  Probing
//
//  Created by Kamil Strzelecki on 22/03/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Probing
import Testing

internal struct RecordedError: Error {

    let underlying: any RecordableProbingError
    let sourceLocation: SourceLocation

    init(
        underlying: some RecordableProbingError,
        sourceLocation: SourceLocation
    ) {
        self.underlying = underlying
        self.sourceLocation = sourceLocation
        Issue.record(self, sourceLocation: sourceLocation)
    }
}

extension RecordedError: CustomStringConvertible {

    var description: String {
        "\(type(of: underlying))\n\n\(underlying)"
    }
}
