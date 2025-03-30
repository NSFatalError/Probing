//
//  DeeplyCopyableStatefulInitDeclBuilder.swift
//  Probing
//
//  Created by Kamil Strzelecki on 22/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import PrincipleMacros

internal struct DeeplyCopyableStatefulInitDeclBuilder: StatefulDeclBuilder {

    let declaration: StatefulDeclSyntax
    let filteredProperties: PropertiesList

    var settings: DeclBuilderSettings {
        .init(accessControlLevel: .init(inheritingDeclaration: .member))
    }

    func build() -> [DeclSyntax] {
        [
            """
            \(inheritedAccessControlLevel)init(deeplyCopying other: \(trimmedTypeName)) {
                \(assignments().formatted())
            }
            """
        ]
    }

    @CodeBlockItemListBuilder
    private func assignments() -> CodeBlockItemListSyntax {
        for property in filteredProperties {
            "self.\(property.trimmedName) = other.\(property.trimmedName).deepCopy()"
        }
    }
}
