//
//  ProbeTests.swift
//  Probing
//
//  Created by Kamil Strzelecki on 27/04/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@testable import Probing
import Testing

internal struct ProbeTests {

    @Test
    func inAsyncFunction() async {
        await #probe()
    }

    @Test
    func inTask() async {
        let task = Task {
            await #probe()
        }
        await task.value
    }

    @Test
    func inExplicitlyIsolatedTask() async {
        let task = Task { @CustomActor in
            await #probe()
        }
        await task.value
    }

    @Test
    func inEffect() async {
        let effect = #Effect("test") {
            await #probe()
        }
        await effect.value
    }

    @Test
    func inExplicitlyIsolatedEffect() async {
        let effect = #Effect("test") { @CustomActor in
            await #probe()
        }
        await effect.value
    }
}
