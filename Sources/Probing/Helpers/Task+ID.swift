//
//  Task+ID.swift
//  Probing
//
//  Created by Kamil Strzelecki on 26/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

extension Task<Void, Never> {

    static var id: Int? {
        withUnsafeCurrentTask { task in
            task?.hashValue
        }
    }
}
