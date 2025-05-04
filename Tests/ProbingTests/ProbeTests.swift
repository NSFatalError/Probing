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
    func testProbe() async {
        await #probe()
    }

    @Test
    func testProbeInTask() async {
        let task = Task {
            await #probe()
        }
        await task.value
    }

    @Test
    func testProbeInEffect() async {
        let effect = #Effect("test") {
            await #probe()
        }
        await effect.value
    }

    @Test
    func testProbeInExplicitlyIsolatedEffect() async {
        let effect = #Effect("test") { @MainActor in
            await #probe()
        }
        await effect.value
    }
}
