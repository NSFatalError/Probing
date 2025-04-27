//
//  DeeplyCopyable.swift
//  Probing
//
//  Created by Kamil Strzelecki on 22/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@attached(
    member,
    names: named(init(deeplyCopying:))
)
@attached(
    extension,
    conformances: DeeplyCopyable,
    names: named(init(deeplyCopying:))
)
public macro DeeplyCopyable() = #externalMacro(
    module: "DeeplyCopyableMacros",
    type: "DeeplyCopyableMacro"
)

public protocol DeeplyCopyable {

    init(deeplyCopying other: Self)
}

extension DeeplyCopyable {

    public func deepCopy() -> Self {
        .init(deeplyCopying: self)
    }
}
