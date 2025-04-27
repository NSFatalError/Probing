//
//  DeeplyCopyable+RangeReplacableCollection.swift
//  Probing
//
//  Created by Kamil Strzelecki on 27/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

extension RangeReplaceableCollection where Self: DeeplyCopyable, Element: DeeplyCopyable {

    public init(deeplyCopying other: Self) {
        self.init(other.lazy.map { $0.deepCopy() })
    }
}

extension Array: DeeplyCopyable where Element: DeeplyCopyable {}
extension ContiguousArray: DeeplyCopyable where Element: DeeplyCopyable {}

extension Slice: DeeplyCopyable where Base: RangeReplaceableCollection, Element: DeeplyCopyable {}
extension ArraySlice: DeeplyCopyable where Element: DeeplyCopyable {}
