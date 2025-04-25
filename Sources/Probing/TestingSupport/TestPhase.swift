//
//  TestPhase.swift
//  Probing
//
//  Created by Kamil Strzelecki on 01/03/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

internal enum TestPhase {

    case scheduled
    case running
    case paused(TestContinuation)
    case passed
    case failed(any Error)
}

extension TestPhase {

    var isScheduled: Bool {
        switch self {
        case .scheduled:
            true
        default:
            false
        }
    }

    var isRunning: Bool {
        switch self {
        case .running:
            true
        default:
            false
        }
    }

    var isPaused: Bool {
        switch self {
        case .paused:
            true
        default:
            false
        }
    }

    var hasPassed: Bool {
        switch self {
        case .passed:
            true
        default:
            false
        }
    }

    var hasFailed: Bool {
        switch self {
        case .failed:
            true
        default:
            false
        }
    }

    var isCompleted: Bool {
        switch self {
        case .failed, .passed:
            true
        default:
            false
        }
    }
}
