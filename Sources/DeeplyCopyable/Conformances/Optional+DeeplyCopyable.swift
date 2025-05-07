//
//  Optional+DeeplyCopyable.swift
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
