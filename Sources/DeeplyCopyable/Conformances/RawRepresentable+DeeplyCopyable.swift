//
//  RawRepresentable+DeeplyCopyable.swift
//  Probing
//
//  Created by Kamil Strzelecki on 27/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

extension RawRepresentable where Self: DeeplyCopyable, RawValue: DeeplyCopyable {

    public init(deeplyCopying other: Self) {
        let rawValue = other.rawValue.deepCopy()
        guard let deepCopy = Self(rawValue: rawValue) else {
            preconditionFailure("\(Self.self) cannot be initialized with raw value: \(rawValue).")
        }
        self = deepCopy
    }
}
