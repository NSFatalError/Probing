//
//  DeeplyCopyable.swift
//  Probing
//
//  Created by Kamil Strzelecki on 22/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Foundation

@attached(
    member,
    names: named(init(deeplyCopying:))
)
@attached(
    extension,
    conformances: DeeplyCopyable,
    names: named(init(deeplyCopying:))
)
public macro DeeplyCopyable() = #externalMacro(
    module: "DeeplyCopyableMacros",
    type: "DeeplyCopyableMacro"
)

public protocol DeeplyCopyable {

    init(deeplyCopying other: Self)
}

extension DeeplyCopyable {

    public func deepCopy() -> Self {
        .init(deeplyCopying: self)
    }
}

// MARK: - Foundation

extension UUID: DeeplyCopyable {

    public init(deeplyCopying other: Self) {
        self = other
    }
}

extension Decimal: DeeplyCopyable {

    public init(deeplyCopying other: Self) {
        self = other
    }
}

// MARK: - Swift

extension Bool: DeeplyCopyable {

    public init(deeplyCopying other: Self) {
        self = other
    }
}

extension Character: DeeplyCopyable {

    public init(deeplyCopying other: Self) {
        self = other
    }
}

extension Optional: DeeplyCopyable where Wrapped: DeeplyCopyable {

    public init(deeplyCopying other: Self) {
        self = other?.deepCopy()
    }
}

extension RawRepresentable where Self: DeeplyCopyable, RawValue: DeeplyCopyable {

    public init(deeplyCopying other: Self) {
        let rawValue = other.rawValue.deepCopy()
        self.init(rawValue: rawValue)! // swiftlint:disable:this force_unwrapping
    }
}

// MARK: - BinaryInteger

extension BinaryInteger where Self: DeeplyCopyable {

    public init(deeplyCopying other: Self) {
        self.init(other)
    }
}

extension Int: DeeplyCopyable {}
extension Int8: DeeplyCopyable {}
extension Int16: DeeplyCopyable {}
extension Int32: DeeplyCopyable {}
extension Int64: DeeplyCopyable {}
extension Int128: DeeplyCopyable {}

extension UInt: DeeplyCopyable {}
extension UInt8: DeeplyCopyable {}
extension UInt16: DeeplyCopyable {}
extension UInt32: DeeplyCopyable {}
extension UInt64: DeeplyCopyable {}
extension UInt128: DeeplyCopyable {}

// MARK: - BinaryFloatingPoint

extension BinaryFloatingPoint where Self: DeeplyCopyable {

    public init(deeplyCopying other: Self) {
        self.init(other)
    }
}

extension Double: DeeplyCopyable {}
extension Float: DeeplyCopyable {}
extension Float16: DeeplyCopyable {}

// MARK: - RangeReplaceableCollection

extension RangeReplaceableCollection where Self: DeeplyCopyable, Element: DeeplyCopyable {

    public init(deeplyCopying other: Self) {
        self.init(other.lazy.map { $0.deepCopy() })
    }
}

extension Data: DeeplyCopyable {}
extension String: DeeplyCopyable {}
extension Substring: DeeplyCopyable {}

extension Array: DeeplyCopyable where Element: DeeplyCopyable {}
extension ContiguousArray: DeeplyCopyable where Element: DeeplyCopyable {}

extension Slice: DeeplyCopyable where Base: RangeReplaceableCollection, Element: DeeplyCopyable {}
extension ArraySlice: DeeplyCopyable where Element: DeeplyCopyable {}

// MARK: - SetAlgebra

extension SetAlgebra where Self: Sequence, Self: DeeplyCopyable, Element: DeeplyCopyable {

    public init(deeplyCopying other: Self) {
        self.init(other.lazy.map { $0.deepCopy() })
    }
}

extension Set: DeeplyCopyable where Element: DeeplyCopyable {}

// MARK: - Dictionary

extension Dictionary: DeeplyCopyable where Key: DeeplyCopyable, Value: DeeplyCopyable {

    public init(deeplyCopying other: Self) {
        self.init(
            uniqueKeysWithValues: other.lazy.map { key, value in
                (key.deepCopy(), value.deepCopy())
            }
        )
    }
}
