//
//  DeeplyCopyable+RangeExpression.swift
//  Probing
//
//  Created by Kamil Strzelecki on 27/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

extension Range: DeeplyCopyable where Bound: DeeplyCopyable {

    public init(deeplyCopying other: Self) {
        self = other.lowerBound.deepCopy() ..< other.upperBound.deepCopy()
    }
}

extension ClosedRange: DeeplyCopyable where Bound: DeeplyCopyable {

    public init(deeplyCopying other: Self) {
        self = other.lowerBound.deepCopy() ... other.upperBound.deepCopy()
    }
}

extension PartialRangeFrom: DeeplyCopyable where Bound: DeeplyCopyable {

    public init(deeplyCopying other: Self) {
        self = other.lowerBound.deepCopy()...
    }
}

extension PartialRangeThrough: DeeplyCopyable where Bound: DeeplyCopyable {

    public init(deeplyCopying other: Self) {
        self = ...other.upperBound.deepCopy()
    }
}

extension PartialRangeUpTo: DeeplyCopyable where Bound: DeeplyCopyable {

    public init(deeplyCopying other: Self) {
        self = ..<other.upperBound.deepCopy()
    }
}

extension RangeSet where Bound: DeeplyCopyable {

    public init(deeplyCopying other: Self) {
        self.init(other.ranges.lazy.map { $0.deepCopy() })
    }
}
