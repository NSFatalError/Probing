//
//  EquatableObjectMacro.swift
//  Probing
//
//  Created by Kamil Strzelecki on 22/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import PrincipleMacros

public enum EquatableObjectMacro {

    private static func validate(
        _ declaration: some DeclGroupSyntax,
        in context: MacroExpansionContext
    ) -> ClassDeclSyntax? {
        guard let declaration = declaration as? ClassDeclSyntax,
              declaration.isFinal
        else {
            context.diagnose(
                node: declaration,
                errorMessage: "EquatableObject macro can only be applied to final classes"
            )
            return nil
        }
        return declaration
    }
}

extension EquatableObjectMacro: MemberMacro {

    public static func expansion(
        of _: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let declaration = validate(declaration, in: context) else {
            return []
        }

        let properties = PropertiesParser.parse(
            memberBlock: declaration.memberBlock,
            in: context
        )

        let builder = EquatableDeclBuilder(
            declaration: declaration,
            properties: properties
        )

        return builder.build()
    }
}

extension EquatableObjectMacro: ExtensionMacro {

    public static func expansion(
        of _: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard validate(declaration, in: context) != nil else {
            return []
        }

        return [
            .init(
                extendedType: type,
                inheritanceClause: .init(
                    inheritedTypes: [
                        .init(type: IdentifierTypeSyntax(name: "Equatable"))
                    ]
                ),
                memberBlock: "{}"
            )
        ]
    }
}
