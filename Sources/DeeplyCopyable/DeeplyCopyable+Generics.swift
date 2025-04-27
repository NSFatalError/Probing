//
//  DeeplyCopyable+Generics.swift
//  Probing
//
//  Created by Kamil Strzelecki on 27/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

extension Optional: DeeplyCopyable where Wrapped: DeeplyCopyable {

    public init(deeplyCopying other: Self) {
        self = other?.deepCopy()
    }
}

extension Dictionary: DeeplyCopyable where Key: DeeplyCopyable, Value: DeeplyCopyable {

    public init(deeplyCopying other: Self) {
        self.init(
            uniqueKeysWithValues: other.lazy.map { key, value in
                (key.deepCopy(), value.deepCopy())
            }
        )
    }
}

extension RawRepresentable where Self: DeeplyCopyable, RawValue: DeeplyCopyable {

    public init(deeplyCopying other: Self) {
        let rawValue = other.rawValue.deepCopy()
        self.init(rawValue: rawValue)! // swiftlint:disable:this force_unwrapping
    }
}
