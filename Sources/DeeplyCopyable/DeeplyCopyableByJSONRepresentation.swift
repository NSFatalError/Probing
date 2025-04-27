//
//  DeeplyCopyableByJSONRepresentation.swift
//  Probing
//
//  Created by Kamil Strzelecki on 26/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Foundation

public protocol DeeplyCopyableByJSONRepresentation: Codable, DeeplyCopyable {}

extension DeeplyCopyableByJSONRepresentation {

    public init(deeplyCopying other: Self) {
        let encoder = JSONEncoder()
        encoder.nonConformingFloatEncodingStrategy = .convertToString(
            positiveInfinity: .positiveInfinity,
            negativeInfinity: .negativeInfinity,
            nan: .nan
        )

        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(
            positiveInfinity: .positiveInfinity,
            negativeInfinity: .negativeInfinity,
            nan: .nan
        )

        do {
            let data = try encoder.encode(other)
            self = try JSONDecoder().decode(Self.self, from: data)
        } catch {
            preconditionFailure(
                "Cannot reconstruct \(Self.self) from JSON representation: \(error)."
            )
        }
    }
}

extension String {

    fileprivate static let positiveInfinity = "positiveInfinity"
    fileprivate static let negativeInfinity = "negativeInfinity"
    fileprivate static let nan = "nan"
}

extension AttributedString: DeeplyCopyableByJSONRepresentation {}
