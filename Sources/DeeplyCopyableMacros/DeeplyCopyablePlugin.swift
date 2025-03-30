//
//  DeeplyCopyablePlugin.swift
//  Probing
//
//  Created by Kamil Strzelecki on 22/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import PrincipleMacros
import SwiftCompilerPlugin

@main
internal struct DeeplyCopyablePlugin: CompilerPlugin {

    let providingMacros: [Macro.Type] = [
        DeeplyCopyableMacro.self
    ]
}
