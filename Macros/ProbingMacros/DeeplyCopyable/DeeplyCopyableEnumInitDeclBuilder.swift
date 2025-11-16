//
//  DeeplyCopyableEnumInitDeclBuilder.swift
//  Probing
//
//  Created by Kamil Strzelecki on 22/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftSyntaxMacros

internal struct DeeplyCopyableEnumInitDeclBuilder: EnumDeclBuilder, MemberBuilding {

    let declaration: EnumDeclSyntax
    let cases: EnumCasesList

    func build() -> [DeclSyntax] {
        [
            """
            \(inheritedAccessControlLevel)init(deeplyCopying other: \(trimmedType)) {
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
