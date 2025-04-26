//
//  UncheckedSendableOperation.swift
//  Probing
//
//  Created by Kamil Strzelecki on 03/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

internal func uncheckedSendable<Success, Failure: Error>(
    _ operation: @escaping () async throws(Failure) -> sending Success
) -> UncheckedSendableOperation.WithoutArguments<Success, Failure> {
    .init(operation)
}

internal func uncheckedSendable<Arg1, Success, Failure: Error>(
    _ operation: @escaping (Arg1) async throws(Failure) -> sending Success
) -> UncheckedSendableOperation.WithOneArgument<Arg1, Success, Failure> {
    .init(operation)
}

internal enum UncheckedSendableOperation {

    struct WithoutArguments<Success, Failure: Error>: @unchecked Sendable {

        let perform: () async throws(Failure) -> sending Success

        fileprivate init(
            _ perform: @escaping () async throws(Failure) -> sending Success
        ) {
            self.perform = perform
        }
    }

    struct WithOneArgument<Arg1, Success, Failure: Error>: @unchecked Sendable {

        let perform: (Arg1) async throws(Failure) -> sending Success

        fileprivate init(
            _ perform: @escaping (Arg1) async throws(Failure) -> sending Success
        ) {
            self.perform = perform
        }
    }
}
