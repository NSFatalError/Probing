//
//  ProbingTerminatedError.swift
//  Probing
//
//  Created by Kamil Strzelecki on 11/05/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

internal struct ProbingTerminatedError: Error, CustomStringConvertible {

    var description: String {
        """
        Probing was terminated because one of the dispatches couldn't be fulfilled. \
        See the issue reported in the `test` closure for more details.
        """
    }
}
