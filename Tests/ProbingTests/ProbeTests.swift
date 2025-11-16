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
    func asyncFunction() async {
        await #probe()
    }

    @Test
    func task() async {
        let task = Task {
            await #probe()
        }
        await task.value
    }

    @Test
    func explicitlyIsolatedTask() async {
        let task = Task { @CustomActor in
            await #probe()
        }
        await task.value
    }

    @Test
    func effect() async {
        let effect = #Effect("test") {
            await #probe()
        }
        await effect.value
    }

    @Test
    func explicitlyIsolatedEffect() async {
        let effect = #Effect("test") { @CustomActor in
            await #probe()
        }
        await effect.value
    }
}
