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
        self.init(rawValue: rawValue)! // swiftlint:disable:this force_unwrapping
    }
}
