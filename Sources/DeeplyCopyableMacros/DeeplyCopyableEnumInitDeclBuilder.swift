//
//  DeeplyCopyableEnumInitDeclBuilder.swift
//  Probing
//
//  Created by Kamil Strzelecki on 22/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import PrincipleMacros

internal struct DeeplyCopyableEnumInitDeclBuilder: EnumDeclBuilder {

    let declaration: EnumDeclSyntax
    let cases: EnumCasesList

    var settings: DeclBuilderSettings {
        .init(accessControlLevel: .init(inheritingDeclaration: .member))
    }

    func build() -> [DeclSyntax] {
        [
            """
            \(inheritedAccessControlLevel)init(deeplyCopying other: \(trimmedTypeName)) {
                \(switchExprBuilder().build())
            }
            """
        ]
    }

    private func switchExprBuilder() -> SwitchExprBuilder {
        SwitchExprBuilder(for: cases, over: "other") { enumCase in
            "self = \(deepCopyBuilder(for: enumCase).build())"
        }
    }

    private func deepCopyBuilder(for enumCase: EnumCase) -> EnumCaseCallExprBuilder<ExprSyntax> {
        EnumCaseCallExprBuilder(for: enumCase) { associatedValue in
            "\(associatedValue.standardizedName).deepCopy()"
        }
    }
}
