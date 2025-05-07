//
//  Dictionary+DeeplyCopyable.swift
//  Probing
//
//  Created by Kamil Strzelecki on 27/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

extension Dictionary: DeeplyCopyable where Key: DeeplyCopyable, Value: DeeplyCopyable {

    public init(deeplyCopying other: Self) {
        self.init(
            uniqueKeysWithValues: other.lazy.map { key, value in
                (key.deepCopy(), value.deepCopy())
            }
        )
    }
}
