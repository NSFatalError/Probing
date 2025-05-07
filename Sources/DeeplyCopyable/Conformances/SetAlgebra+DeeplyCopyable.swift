//
//  SetAlgebra+DeeplyCopyable.swift
//  Probing
//
//  Created by Kamil Strzelecki on 27/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

extension SetAlgebra where Self: Sequence, Self: DeeplyCopyable, Element: DeeplyCopyable {

    public init(deeplyCopying other: Self) {
        self.init(other.lazy.map { $0.deepCopy() })
    }
}

extension Set: DeeplyCopyable where Element: DeeplyCopyable {}
