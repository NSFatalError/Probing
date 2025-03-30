//
//  EffectDispatch.swift
//  Probing
//
//  Created by Kamil Strzelecki on 08/03/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

internal indirect enum EffectDispatch: Sendable {

    case suspendWhenPossible
    case runUntilChildCreated(id: EffectIdentifier, dispatch: Self)
    case runUntilProbeInstalled(id: ProbeIdentifier)
    case runUntilCompleted(includingDescendants: Bool)

    mutating func relayToChild(withID childID: EffectIdentifier) -> Self {
        switch self {
        case .runUntilProbeInstalled, .suspendWhenPossible:
            return .suspendWhenPossible

        case let .runUntilChildCreated(id, dispatch):
            if case .runUntilChildCreated = dispatch {
                preconditionFailure("Child dispatches cannot be nested.")
            }

            precondition(
                childID.path.count <= id.path.count,
                """
                Dispatch for effect with identifier \"\(id)\" was relayed \
                to unrelated descendant with identifier \"\(childID)\".
                """
            )

            if childID == id {
                self = .suspendWhenPossible
                return dispatch
            }

            if id.path.starts(with: childID.path) {
                self = .suspendWhenPossible
                return .runUntilChildCreated(id: id, dispatch: dispatch)
            }

            return .suspendWhenPossible

        case let .runUntilCompleted(includeDescendants):
            if includeDescendants {
                return .runUntilCompleted(includingDescendants: true)
            }
            return .suspendWhenPossible
        }
    }
}
