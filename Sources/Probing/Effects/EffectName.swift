//
//  EffectName.swift
//  Probing
//
//  Created by Kamil Strzelecki on 21/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

/// The name of an effect, forming the elements of ``EffectIdentifier/path`` of an ``EffectIdentifier``.
///
/// An `EffectName` must be unique within the scope of its parent effect while the effect is still running.
/// Once the effect has completed, the same name may be reused by another effect.
///
/// It’s recommended to assign distinct names to effects with different purposes.
/// If you need to invoke the same function repeatedly and cannot guarantee that the effect created by its previous invocation has completed,
/// use ``enumerated(_:)`` to automatically append an index to the name, making it unique.
///
public struct EffectName: ProbingIdentifierProtocol {

    /// A non-empty string that does not contain any `.` characters.
    ///
    public let rawValue: String

    private(set) var isEnumerated = false

    /// Creates a new effect name.
    ///
    /// - Parameter rawValue: A non-empty string that must not contain any `.` characters.
    ///
    public init(rawValue: String) {
        ProbingNames.preconditionValid(rawValue)
        self.rawValue = rawValue
    }
}

extension EffectName {

    /// Marks the given effect name as eligible for automatic indexing during tests, starting from zero.
    ///
    /// - Parameter name: The effect name to append an index to during tests.
    ///
    /// - Returns: A new effect name that will be automatically indexed during tests.
    ///
    /// The resulting ``rawValue`` during tests will be formatted as `name0`, `name1`, etc.
    ///
    public static func enumerated(_ name: EffectName) -> EffectName {
        var enumerated = name
        enumerated.isEnumerated = true
        return enumerated
    }

    /// Appends the given index to the ``rawValue``.
    ///
    /// - Parameter index: The index to append to the ``rawValue``.
    ///
    /// - Returns: A new effect name with the index appended.
    ///
    /// The resulting ``rawValue`` will be formatted as `name0`, `name1`, etc.
    ///
    public func withIndex(_ index: UInt) -> EffectName {
        .init(rawValue: "\(rawValue)\(index)")
    }
}
