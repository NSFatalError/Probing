//
//  ProbeMacro.swift
//  Probing
//
//  Created by Kamil Strzelecki on 10/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import PrincipleMacros

public enum ProbeMacro: ExpressionMacro {

    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in _: some MacroExpansionContext
    ) throws -> ExprSyntax {
        // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0461-async-function-isolation.md
        // https://forums.swift.org/t/closure-isolation-control/70378
        let parameters = Parameters(from: node)

        return """
        { () async -> Void in
            #if \(raw: parameters.preprocessorFlag)
            await _probe(
                \(parameters.name),
                when: \(parameters.precondition),
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
        let precondition: ExprSyntax

        init(from node: some FreestandingMacroExpansionSyntax) {
            let extractor = ParameterExtractor(from: node)
            self.name = (try? extractor.expression(withLabel: nil)) ?? ".default"
            self.preprocessorFlag = (try? extractor.rawString(withLabel: "preprocessorFlag")) ?? "DEBUG"
            self.precondition = (try? extractor.expression(withLabel: "when")) ?? "true"
        }
    }
}
