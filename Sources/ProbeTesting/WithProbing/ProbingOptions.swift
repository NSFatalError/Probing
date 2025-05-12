//
//  ProbingOptions.swift
//  Probing
//
//  Created by Kamil Strzelecki on 28/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Probing

/// Options that change the testability of probes and effects created from `Task` APIs.
///
/// - SeeAlso: Refer to `Probing` documentation to learn more on interactions with Swift Concurrency.
///
public struct ProbingOptions: OptionSet, Sendable {

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

extension ProbingOptions {

    var underlying: _ProbingOptions {
        .init(rawValue: rawValue)
    }

    init(_ options: _ProbingOptions) {
        self.rawValue = options.rawValue
    }
}

extension ProbingOptions {

    /// Treats probes and effects created from `Task` APIs as if they were invoked
    /// from the top effect on the execution stack.
    ///
    /// - Warning: Using this option may lead to reporting of API misuses.
    ///
    /// When using this option, you must ensure that no part of your code executes concurrently with the `test` closure
    /// of the ``withProbing(options:sourceLocation:isolation:of:dispatchedBy:)`` function.
    ///
    /// In the simplest case, this means you would need to serialize calls to `Task` APIs and `await` each of them sequentially.
    ///
    /// - SeeAlso: Refer to `Probing` documentation to learn more on interactions with Swift Concurrency.
    ///
    public static let attemptProbingInTasks = Self(.attemptProbingInTasks)

    /// Ignores probes and effects created from `Task` APIs.
    ///
    /// - Note: This is the default option and it's recommended in most cases, as it avoids reporting API misuses.
    ///
    /// When this option is enabled, probes created within `Task` APIs resume immediately,
    /// and effects run as standard Swift `Task` instances, without any custom scheduling.
    ///
    /// - SeeAlso: Refer to `Probing` documentation to learn more on interactions with Swift Concurrency.
    ///
    public static let ignoreProbingInTasks = Self(.ignoreProbingInTasks)
}
