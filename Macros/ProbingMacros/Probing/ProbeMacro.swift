//
//  ProbeMacro.swift
//  Probing
//
//  Created by Kamil Strzelecki on 10/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftSyntaxMacros

public enum ProbeMacro: ExpressionMacro {

    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in _: some MacroExpansionContext
    ) throws -> ExprSyntax {
        let parameters = try Parameters(from: node)
        return """
        { () async -> Void in
            #if \(raw: parameters.preprocessorFlag)
            await _probe(
                \(parameters.name),
                isolation: #isolation
            )
            #endif 
        }()
        """
    }
}

extension ProbeMacro {

    private struct Parameters {

        let name: ExprSyntax
        let preprocessorFlag: String

        init(from node: some FreestandingMacroExpansionSyntax) throws {
            let extractor = ParameterExtractor(from: node)
            self.name = extractor.expression(withLabel: nil) ?? ".default"
            self.preprocessorFlag = try extractor.rawString(withLabel: "preprocessorFlag") ?? "DEBUG"
        }
    }
}
