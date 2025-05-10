//
//  ProbeName.swift
//  Probing
//
//  Created by Kamil Strzelecki on 05/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

/// The name of a probe, forming the last component of a ``ProbeIdentifier``.
///
/// A `ProbeName` doesn't need to be unique, as it is impossible to install two probes concurrently from the same effect.
///
public struct ProbeName: ProbingIdentifierProtocol {

    public let rawValue: String
    
    /// Creates a new probe name.
    ///
    /// - Parameter rawValue: Non-empty string that must not contain any `.` characters.
    ///
    public init(rawValue: String) {
        ProbingNames.preconditionValid(rawValue)
        self.rawValue = rawValue
    }
}

extension ProbeName {

    /// The default probe name, used by ``probe(_:preprocessorFlag:)`` when no `name` argument  is provided.
    ///
    /// It's ``rawValue`` is `"probe"`.
    ///
    public static let `default`: Self = "probe"
}
