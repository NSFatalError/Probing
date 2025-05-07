//
//  DeeplyCopyableByAssignment.swift
//  Probing
//
//  Created by Kamil Strzelecki on 27/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Foundation

internal protocol DeeplyCopyableByAssignment: DeeplyCopyable {}

extension DeeplyCopyableByAssignment {

    public init(deeplyCopying other: Self) {
        self = other
    }
}

extension Int: DeeplyCopyable, DeeplyCopyableByAssignment {}
extension Int8: DeeplyCopyable, DeeplyCopyableByAssignment {}
extension Int16: DeeplyCopyable, DeeplyCopyableByAssignment {}
extension Int32: DeeplyCopyable, DeeplyCopyableByAssignment {}
extension Int64: DeeplyCopyable, DeeplyCopyableByAssignment {}
extension Int128: DeeplyCopyable, DeeplyCopyableByAssignment {}

extension UInt: DeeplyCopyable, DeeplyCopyableByAssignment {}
extension UInt8: DeeplyCopyable, DeeplyCopyableByAssignment {}
extension UInt16: DeeplyCopyable, DeeplyCopyableByAssignment {}
extension UInt32: DeeplyCopyable, DeeplyCopyableByAssignment {}
extension UInt64: DeeplyCopyable, DeeplyCopyableByAssignment {}
extension UInt128: DeeplyCopyable, DeeplyCopyableByAssignment {}

extension Double: DeeplyCopyable, DeeplyCopyableByAssignment {}
extension Float: DeeplyCopyable, DeeplyCopyableByAssignment {}
extension Float16: DeeplyCopyable, DeeplyCopyableByAssignment {}
extension Decimal: DeeplyCopyable, DeeplyCopyableByAssignment {}

extension Bool: DeeplyCopyable, DeeplyCopyableByAssignment {}
extension Character: DeeplyCopyable, DeeplyCopyableByAssignment {}
extension Duration: DeeplyCopyable, DeeplyCopyableByAssignment {}
extension UUID: DeeplyCopyable, DeeplyCopyableByAssignment {}

extension URL: DeeplyCopyable, DeeplyCopyableByAssignment {}
extension URLComponents: DeeplyCopyable, DeeplyCopyableByAssignment {}
extension URLQueryItem: DeeplyCopyable, DeeplyCopyableByAssignment {}

extension Date: DeeplyCopyable, DeeplyCopyableByAssignment {}
extension DateComponents: DeeplyCopyable, DeeplyCopyableByAssignment {}
extension TimeZone: DeeplyCopyable, DeeplyCopyableByAssignment {}
extension Calendar: DeeplyCopyable, DeeplyCopyableByAssignment {}

extension Locale: DeeplyCopyable, DeeplyCopyableByAssignment {}
extension PersonNameComponents: DeeplyCopyable, DeeplyCopyableByAssignment {}

extension Data: DeeplyCopyable, DeeplyCopyableByAssignment {

    public init(deeplyCopying other: Self) {
        self = other
    }
}

extension String: DeeplyCopyable, DeeplyCopyableByAssignment {

    public init(deeplyCopying other: Self) {
        self = other
    }
}

extension Substring: DeeplyCopyable, DeeplyCopyableByAssignment {

    public init(deeplyCopying other: Self) {
        self = other
    }
}
