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

    var isCompleted: Bool {
        switch self {
        case .failed, .passed:
            true
        default:
            false
        }
    }
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

    var isPassed: Bool {
        switch self {
        case .passed:
            true
        default:
            false
        }
    }

    var isFailed: Bool {
        switch self {
        case .failed:
            true
        default:
            false
        }
    }
}

extension TestPhase {

    struct Precondition {

        let condition: @Sendable (TestPhase) -> Bool
        let file: StaticString
        let line: UInt

        init(
            _ condition: @Sendable @escaping (TestPhase) -> Bool,
            file: StaticString = #file,
            line: UInt = #line
        ) {
            self.condition = condition
            self.file = file
            self.line = line
        }
    }
}
