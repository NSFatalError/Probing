//
//  Error+RecordedError.swift
//  Probing
//
//  Created by Kamil Strzelecki on 27/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@testable import ProbeTesting
import Testing

extension Issue {

    func didRecordError<Underlying: Error>(
        _: Underlying.Type
    ) -> Bool {
        let recordedError = error as? RecordedError
        return recordedError?.underlying is Underlying
    }
}
