//
//  ProbingPlugin.swift
//  Probing
//
//  Created by Kamil Strzelecki on 10/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftSyntaxMacros
import SwiftCompilerPlugin

@main
internal struct ProbingPlugin: CompilerPlugin {

    let providingMacros: [any Macro.Type] = [
        ProbeMacro.self,
        EffectMacro.self,
        EquatableObjectMacro.self,
        DeeplyCopyableMacro.self
    ]
}
