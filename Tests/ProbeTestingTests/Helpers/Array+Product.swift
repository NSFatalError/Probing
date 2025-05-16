//
//  Array+Product.swift
//  Probing
//
//  Created by Kamil Strzelecki on 16/05/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

internal func product<A, B>(
    _ first: some Sequence<A>,
    _ second: some Sequence<B>
) -> [(A, B)] {
    first.flatMap { first in
        second.lazy.map { second in
            (first, second)
        }
    }
}
