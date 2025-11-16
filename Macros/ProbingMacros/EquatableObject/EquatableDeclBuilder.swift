//
//  EquatableDeclBuilder.swift
//  Probing
//
//  Created by Kamil Strzelecki on 22/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftSyntaxMacros

internal struct EquatableDeclBuilder: ClassDeclBuilder, MemberBuilding {

    let declaration: ClassDeclSyntax
    let properties: PropertiesList

    func build() -> [DeclSyntax] {
        [
            """
            \(inheritedAccessControlLevel)static func == (lhs: \(trimmedType), rhs: \(trimmedType)) -> Bool {
                \(equalityChecks().formatted())
                return true
            }
            """
        ]
    }

    @CodeBlockItemListBuilder
    private func equalityChecks() -> CodeBlockItemListSyntax {
        for property in properties.stored.instance.all {
            let name = property.trimmedName
            "guard lhs.\(name) == rhs.\(name) else { return false }"
        }
    }
}
