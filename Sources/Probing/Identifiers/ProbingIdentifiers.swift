//
//  ProbingIdentifiers.swift
//  Probing
//
//  Created by Kamil Strzelecki on 23/02/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

internal enum ProbingIdentifiers {

    static func split(_ rawValue: String) -> [String] {
        rawValue
            .split(separator: ".", omittingEmptySubsequences: false)
            .map(String.init)
    }

    static func join(_ components: some Sequence<String>) -> String {
        components.lazy
            .filter { !$0.isEmpty }
            .joined(separator: ".")
    }

    static func join(_ components: some Sequence<some ProbingIdentifierProtocol>) -> String {
        join(components.lazy.map(\.rawValue))
    }
}

extension ProbingIdentifiers {

    static func preconditionNotEmpty(
        _ components: some Collection<some ProbingIdentifierProtocol>,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        precondition(
            !components.isEmpty,
            "Identifier must not be empty.",
            file: file,
            line: line
        )
    }
}
