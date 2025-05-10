//
//  Probe.swift
//  Probing
//
//  Created by Kamil Strzelecki on 05/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

/// Defines a possible suspension point accessible from your tests.
///
/// - Parameters:
///   - name: The name of the probe. Does not need to be unique. Defaults to ``ProbeName/default``.
///   - preprocessorFlag: A preprocessor flag that determines whether the generated code is included in the compiled binary.
///   Defaults to `DEBUG`.
///
/// Think of a probe as a conditional “breakpoint” for tests, with two key differences:
/// - It suspends only the current effect/task, not the entire program.
/// - It enables you to run test assertions at that point in execution, rather than debugging.
///
/// When a probe is installed, it is uniquely identified at that point in execution by a ``ProbeIdentifier``.
/// Subsequent probes with the same `name` in the same effect will be assigned the same identifier.
///
/// If your code is compiled with the given `preprocessorFlag`, the probe becomes accessible and controllable from your tests
/// only when run within the `body` of `ProbeTesting.withProbing` function. Outside of that scope, this call does nothing
/// and resumes execution immediately.
///
@freestanding(expression)
public macro probe(
    _ name: @autoclosure () -> ProbeName = .default,
    preprocessorFlag: StaticString = "DEBUG"
) = #externalMacro(
    module: "ProbingMacros",
    type: "ProbeMacro"
)

@_documentation(visibility: private)
public func _probe( // swiftlint:disable:this identifier_name
    _ name: @autoclosure () -> ProbeName,
    isolation: isolated (any Actor)?,
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column
) async {
    guard let coordinator = ProbingCoordinator.current else {
        return
    }

    let location = ProbingLocation(
        fileID: fileID,
        line: line,
        column: column
    )

    await coordinator.installProbe(
        withName: name(),
        at: location,
        isolation: isolation
    )
}
