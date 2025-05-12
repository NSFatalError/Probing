//
//  ProbeIdentifier.swift
//  Probing
//
//  Created by Kamil Strzelecki on 21/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

/// A unique identifier of a probe at a specific point in execution.
///
/// A `ProbeIdentifier` consists of the ``effect`` identifier in which the probe was installed during a particular test run,
/// and the probe ``name`` passed to the ``probe(_:preprocessorFlag:)`` macro.
///
/// It is represented as a string formed by concatenating these components with `"."` separators:
/// ```swift
/// "\(effect).\(name)"
/// // "effect1.effect2.(...).effectN.probe"
/// ```
///
/// If the probe is installed directly in the `body` of the `ProbeTesting.withProbing` function, without any intermediate effects,
/// the identifier contains only the ``name``, since the ``effect``.``EffectIdentifier/path`` is empty:
/// ```swift
/// "\(name)"
/// // "probe"
/// ```
///
public struct ProbeIdentifier {

    /// A string formed by concatenating the ``effect`` and ``name`` components with `"."` separators.
    ///
    /// If the probe is installed within an effect, the `rawValue` has the form:
    /// ```swift
    /// "\(effect).\(name)"
    /// // "effect1.effect2.(...).effectN.probe"
    /// ```
    ///
    /// If the probe is installed directly in the `body` of the `ProbeTesting.withProbing` function, without any intermediate effects,
    /// the `rawValue` contains only the ``name``, since the ``effect``.``EffectIdentifier/path`` is empty:
    /// ```swift
    /// "\(name)"
    /// // "probe"
    /// ```
    ///
    public let rawValue: String

    /// The identifier of the effect in which the probe was installed during a particular test run.
    ///
    public let effect: EffectIdentifier

    /// The name of the probe, as passed to the ``probe(_:preprocessorFlag:)`` macro.
    ///
    public let name: ProbeName

    /// Creates a probe identifier for lookup during tests.
    ///
    /// - Parameters:
    ///   - effect: The identifier of the effect in which the probe was installed.
    ///   - name: The name of the probe.
    ///
    /// Probe identifiers are determined dynamically during test execution.
    /// Use this initializer to construct expected probe identifiers, which can be passed to the `ProbeTesting.ProbingDispatcher` to control the execution flow.
    ///
    public init(
        effect: EffectIdentifier,
        name: ProbeName
    ) {
        self.rawValue = ProbingIdentifiers.join([
            effect.rawValue,
            name.rawValue
        ])
        self.effect = effect
        self.name = name
    }
}

extension ProbeIdentifier: ProbingIdentifierProtocol {

    /// Creates a probe identifier for lookup during tests.
    ///
    /// - Parameter rawValue: A non-empty string in the format described by ``rawValue``.
    ///
    /// Probe identifiers are determined dynamically during test execution.
    /// Use this initializer to construct expected probe identifiers, which can be passed to the `ProbeTesting.ProbingDispatcher` to control the execution flow.
    ///
    public init(rawValue: String) {
        let components = ProbingIdentifiers.split(rawValue)
        let path = components.dropLast().map(EffectName.init)
        let effect = EffectIdentifier(path: path)
        let name = ProbeName(rawValue: components.last ?? "")
        self.init(effect: effect, name: name)
    }
}
