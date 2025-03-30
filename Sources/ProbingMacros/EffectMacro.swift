//
//  EffectMacro.swift
//  Probing
//
//  Created by Kamil Strzelecki on 23/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import PrincipleMacros
import SwiftSyntax

public enum EffectMacro {

    static let name = "Effect"
    static let concurrentName = "ConcurrentEffect"
    static let allNames = [name, concurrentName]

    private static func isNested(lexicalContext: [Syntax]) -> Bool {
        lexicalContext.contains { syntax in
            MacroExpansionExprSyntax(syntax)?.isEffectMacro ?? false
        }
    }

    private static func nestedExpansion() -> ExprSyntax {
        #"""
        fatalError("""
        Nested #Effect macro expansions will never be embedded in the actual source code. \
        To see the functional expansion refer to the parent of this effect.
        """)
        """#
    }
}

extension EffectMacro: ExpressionMacro {

    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard !isNested(lexicalContext: context.lexicalContext) else {
            return nestedExpansion()
        }

        let parameters = try Parameters(from: node)
        let rewriter = Rewriter()

        switch parameters {
        case let .withExecutorPreference(parameters):
            return """
            {
                #if \(raw: parameters.preprocessorFlag)
                return TestableEffect._make(
                    \(parameters.name),
                    executorPreference: \(parameters.executorPreference),
                    priority: \(parameters.priority),
                    operation: \(rewriter.rewrite(parameters.operation, as: .testableEffect))
                )
                #else
                return Task(
                    executorPreference: \(parameters.executorPreference),
                    priority: \(parameters.priority),
                    operation: \(rewriter.rewrite(parameters.operation, as: .task))
                )
                #endif 
            }()
            """

        case let .withIsolatedOperation(parameters):
            return """
            {
                #if \(raw: parameters.preprocessorFlag)
                return TestableEffect._make(
                    \(parameters.name),
                    priority: \(parameters.priority),
                    operation: \(rewriter.rewrite(parameters.operation, as: .testableEffect))
                )
                #else
                return Task(
                    priority: \(parameters.priority),
                    operation: \(rewriter.rewrite(parameters.operation, as: .task))
                )
                #endif 
            }()
            """
        }
    }
}

extension EffectMacro {

    private enum Parameters {

        case withExecutorPreference(ParametersWithExecutorPreference)
        case withIsolatedOperation(ParametersWithIsolatedOperation)

        var operation: ExprSyntax {
            switch self {
            case let .withExecutorPreference(parameters):
                parameters.operation
            case let .withIsolatedOperation(parameters):
                parameters.operation
            }
        }

        init(from node: some FreestandingMacroExpansionSyntax) throws {
            let extractor = ParameterExtractor(from: node)
            let name = try extractor.expression(withLabel: nil)
            let operation = try extractor.trailingClosure(withLabel: "operation")
            let preprocessorFlag = (try? extractor.rawString(withLabel: "preprocessorFlag")) ?? "DEBUG"
            let priority = (try? extractor.expression(withLabel: "priority")) ?? "nil"

            let executorPreference: ExprSyntax? = node.isConcurrentEffectMacro
                ? "globalConcurrentExecutor"
                : (try? extractor.expression(withLabel: "executorPreference"))

            self = if let executorPreference {
                .withExecutorPreference(
                    ParametersWithExecutorPreference(
                        name: name,
                        preprocessorFlag: preprocessorFlag,
                        executorPreference: executorPreference,
                        priority: priority,
                        operation: operation
                    )
                )
            } else {
                .withIsolatedOperation(
                    ParametersWithIsolatedOperation(
                        name: name,
                        preprocessorFlag: preprocessorFlag,
                        priority: priority,
                        operation: operation
                    )
                )
            }
        }
    }

    private struct ParametersWithExecutorPreference {

        let name: ExprSyntax
        let preprocessorFlag: String
        let executorPreference: ExprSyntax
        let priority: ExprSyntax
        let operation: ExprSyntax
    }

    private struct ParametersWithIsolatedOperation {

        let name: ExprSyntax
        let preprocessorFlag: String
        let priority: ExprSyntax
        let operation: ExprSyntax
    }
}

extension EffectMacro {

    private final class Rewriter: SyntaxRewriter {

        private var product = Product.task

        func rewrite(_ node: some SyntaxProtocol, as product: Product) -> Syntax {
            self.product = product
            let rewritten = rewrite(node)

            guard let expr = ExprSyntax(rewritten) else {
                return rewritten
            }

            let outerNestingLevel = 2
            let expanded = expr.expanded(nestingLevel: outerNestingLevel)
            return Syntax(expanded)
        }

        override func visit(_ node: MacroExpansionExprSyntax) -> ExprSyntax {
            guard node.isEffectMacro,
                  let parameters = try? Parameters(from: node)
            else {
                return super.visit(node)
            }

            var rewrittenOperation = ExprSyntax(rewrite(parameters.operation)) ?? parameters.operation
            rewrittenOperation = rewrittenOperation.expanded(nestingLevel: 0)

            var rewritten: ExprSyntax = switch (product, parameters) {
            case let (.testableEffect, .withIsolatedOperation(parameters)):
                """
                TestableEffect._make(
                \(parameters.name),
                priority: \(parameters.priority),
                operation: \(rewrittenOperation)
                )
                """

            case let (.task, .withIsolatedOperation(parameters)):
                """
                Task(
                priority: \(parameters.priority),
                operation: \(rewrittenOperation)
                )
                """

            case let (.testableEffect, .withExecutorPreference(parameters)):
                """
                TestableEffect._make(
                \(parameters.name),
                executorPreference: \(parameters.executorPreference),
                priority: \(parameters.priority),
                operation: \(rewrittenOperation)
                )
                """

            case let (.task, .withExecutorPreference(parameters)):
                """
                Task(
                executorPreference: \(parameters.executorPreference),
                priority: \(parameters.priority),
                operation: \(rewrittenOperation)
                )
                """
            }

            rewritten.leadingTrivia = node.leadingTrivia
            rewritten.trailingTrivia = node.trailingTrivia
            return rewritten
        }
    }
}

extension EffectMacro {

    private enum Product {

        case task
        case testableEffect
    }
}

extension FreestandingMacroExpansionSyntax {

    fileprivate var isEffectMacro: Bool {
        EffectMacro.allNames.contains(macroName.trimmedDescription)
    }

    fileprivate var isConcurrentEffectMacro: Bool {
        EffectMacro.concurrentName == macroName.trimmedDescription
    }
}
