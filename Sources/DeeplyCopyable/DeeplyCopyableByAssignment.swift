//
//  DeeplyCopyable+ValueTypes.swift
//  Probing
//
//  Created by Kamil Strzelecki on 27/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Foundation

public protocol DeeplyCopyableByAssignment: DeeplyCopyable {}

extension DeeplyCopyableByAssignment {

    public init(deeplyCopying other: Self) {
        self = other
    }
}

extension Int: DeeplyCopyableByAssignment {}
extension Int8: DeeplyCopyableByAssignment {}
extension Int16: DeeplyCopyableByAssignment {}
extension Int32: DeeplyCopyableByAssignment {}
extension Int64: DeeplyCopyableByAssignment {}
extension Int128: DeeplyCopyableByAssignment {}

extension UInt: DeeplyCopyableByAssignment {}
extension UInt8: DeeplyCopyableByAssignment {}
extension UInt16: DeeplyCopyableByAssignment {}
extension UInt32: DeeplyCopyableByAssignment {}
extension UInt64: DeeplyCopyableByAssignment {}
extension UInt128: DeeplyCopyableByAssignment {}

extension Double: DeeplyCopyableByAssignment {}
extension Float: DeeplyCopyableByAssignment {}
extension Float16: DeeplyCopyableByAssignment {}
extension Decimal: DeeplyCopyableByAssignment {}

extension Bool: DeeplyCopyableByAssignment {}
extension Character: DeeplyCopyableByAssignment {}
extension Duration: DeeplyCopyableByAssignment {}
extension UUID: DeeplyCopyableByAssignment {}

extension URL: DeeplyCopyableByAssignment {}
extension URLComponents: DeeplyCopyableByAssignment {}
extension URLQueryItem: DeeplyCopyableByAssignment {}

extension Date: DeeplyCopyableByAssignment {}
extension DateComponents: DeeplyCopyableByAssignment {}
extension TimeZone: DeeplyCopyableByAssignment {}
extension Calendar: DeeplyCopyableByAssignment {}

extension Locale: DeeplyCopyableByAssignment {}
extension PersonNameComponents: DeeplyCopyableByAssignment {}

extension Data: DeeplyCopyableByAssignment {

    public init(deeplyCopying other: Self) {
        self = other
    }
}

extension String: DeeplyCopyableByAssignment {

    public init(deeplyCopying other: Self) {
        self = other
    }
}

extension Substring: DeeplyCopyableByAssignment {

    public init(deeplyCopying other: Self) {
        self = other
    }
}
