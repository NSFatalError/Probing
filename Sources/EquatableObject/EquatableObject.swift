//
//  EquatableObject.swift
//  Probing
//
//  Created by Kamil Strzelecki on 22/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@attached(
    member,
    names: named(==)
)
@attached(
    extension,
    conformances: Equatable
)
public macro EquatableObject() = #externalMacro(
    module: "EquatableObjectMacros",
    type: "EquatableObjectMacro"
)
