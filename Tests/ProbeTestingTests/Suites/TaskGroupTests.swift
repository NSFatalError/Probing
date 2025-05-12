//
//  TaskGroupTests.swift
//  Probing
//
//  Created by Kamil Strzelecki on 12/05/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@testable import ProbeTesting
@testable import Probing
import Testing

internal struct TaskGroupTests {

    private let childrenCount = 100

    @Test
    func testCollectingChildResults() async throws {
        try await withProbing {
            await withTaskGroup(of: Void.self) { group in
                for _ in 0 ..< childrenCount {
                    group.addTask {
                        await #probe()
                    }
                }
                for await _ in group {
                    await #probe()
                }
            }
        } dispatchedBy: { dispatcher in
            for _ in 0 ..< childrenCount {
                try await dispatcher.runUpToProbe()
            }
            try await dispatcher.runUntilExitOfBody()
        }
    }
}
