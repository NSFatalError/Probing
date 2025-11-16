//
//  DeeplyCopyableStatefulInitDeclBuilder.swift
//  Probing
//
//  Created by Kamil Strzelecki on 22/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftSyntaxMacros

internal struct DeeplyCopyableStatefulInitDeclBuilder: StatefulDeclBuilder, MemberBuilding {

    let declaration: any StatefulDeclSyntax
    let filteredProperties: PropertiesList

    func build() -> [DeclSyntax] {
        [
            """
            \(inheritedAccessControlLevel)init(deeplyCopying other: \(trimmedType)) {
                \(assignments().formatted())
            }
            """
        ]
    }

    @CodeBlockItemListBuilder
    private func assignments() -> CodeBlockItemListSyntax {
        for property in filteredProperties.all {
            "self.\(property.trimmedName) = other.\(property.trimmedName).deepCopy()"
        }
    }
}
