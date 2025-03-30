//
//  Probe.swift
//  Probing
//
//  Created by Kamil Strzelecki on 05/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@freestanding(expression)
public macro probe(
    _ name: @autoclosure () -> ProbeName = .default,
    preprocessorFlag: StaticString = "DEBUG",
    when precondition: @autoclosure () -> Bool = true
) = #externalMacro(
    module: "ProbingMacros",
    type: "ProbeMacro"
)

public func _probe( // swiftlint:disable:this identifier_name
    _ name: @autoclosure () -> ProbeName,
    when precondition: @autoclosure () -> Bool,
    isolation: isolated (any Actor)?,
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column
) async {
    guard let coordinator = ProbingCoordinator.current,
          precondition()
    else {
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
