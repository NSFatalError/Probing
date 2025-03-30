//
//  DeeplyCopyableMacro.swift
//  Probing
//
//  Created by Kamil Strzelecki on 22/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import PrincipleMacros

public enum DeeplyCopyableMacro {

    private enum ValidationResult {

        case enumDecl(EnumDeclSyntax, cases: EnumCasesList)
        case statefulDecl(StatefulDeclSyntax, filteredProperties: PropertiesList)
    }

    private static func validate(
        _ declaration: some DeclGroupSyntax,
        in context: MacroExpansionContext
    ) -> ValidationResult? {
        if let declaration = declaration as? EnumDeclSyntax {
            let cases = EnumCasesParser.parse(
                memberBlock: declaration.memberBlock,
                in: context
            )
            return .enumDecl(declaration, cases: cases)
        }

        if let declaration = declaration as? StatefulDeclSyntax, declaration.isFinal {
            let filteredProperties = PropertiesParser
                .parse(memberBlock: declaration.memberBlock, in: context)
                .stored.instance

            for property in filteredProperties {
                guard property.mutability == .mutable || property.binding.initializer == nil else {
                    context.diagnose(
                        node: property.declaration,
                        errorMessage: "DeeplyCopyable properties must be settable from initializer"
                    )
                    return nil
                }
            }

            return .statefulDecl(
                declaration,
                filteredProperties: filteredProperties
            )
        }

        context.diagnose(
            node: declaration,
            errorMessage: "DeeplyCopyable macro can only be applied to final classes, structs or enums"
        )

        return nil
    }
}

extension DeeplyCopyableMacro: MemberMacro {

    public static func expansion(
        of _: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let result = validate(declaration, in: context) else {
            return []
        }

        let builder: TypeDeclBuilder? = switch result {
        case let .enumDecl(declaration, cases):
            DeeplyCopyableEnumInitDeclBuilder(
                declaration: declaration,
                cases: cases
            )
        case let .statefulDecl(declaration as ClassDeclSyntax, filteredProperties):
            DeeplyCopyableStatefulInitDeclBuilder(
                declaration: declaration,
                filteredProperties: filteredProperties
            )
        default:
            nil
        }

        return try builder?.build() ?? []
    }
}

extension DeeplyCopyableMacro: ExtensionMacro {

    public static func expansion(
        of _: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let result = validate(declaration, in: context) else {
            return []
        }

        let builder: TypeDeclBuilder? = switch result {
        case let .statefulDecl(declaration as StructDeclSyntax, filteredProperties):
            DeeplyCopyableStatefulInitDeclBuilder(
                declaration: declaration,
                filteredProperties: filteredProperties
            )
        default:
            nil
        }

        return try [
            .init(
                extendedType: type,
                inheritanceClause: .init(
                    inheritedTypes: [
                        .init(type: IdentifierTypeSyntax(name: "DeeplyCopyable"))
                    ]
                ),
                memberBlock: builder?.buildExtension(of: type) ?? "{}"
            )
        ]
    }
}
