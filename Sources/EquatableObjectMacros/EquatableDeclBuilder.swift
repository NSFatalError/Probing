//
//  EquatableDeclBuilder.swift
//  Probing
//
//  Created by Kamil Strzelecki on 22/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import PrincipleMacros

internal struct EquatableDeclBuilder: ClassDeclBuilder {

    let declaration: ClassDeclSyntax
    let properties: PropertiesList

    var settings: DeclBuilderSettings {
        .init(accessControlLevel: .init(inheritingDeclaration: .member))
    }

    func build() -> [DeclSyntax] {
        [
            """
            \(inheritedAccessControlLevel)static func == (lhs: \(trimmedTypeName), rhs: \(trimmedTypeName)) -> Bool {
                \(equalityChecks().formatted())
                return true
            }
            """
        ]
    }

    @CodeBlockItemListBuilder
    private func equalityChecks() -> CodeBlockItemListSyntax {
        for property in properties.stored.instance {
            let name = property.trimmedName
            "guard lhs.\(name) == rhs.\(name) else { return false }"
        }
    }
}
