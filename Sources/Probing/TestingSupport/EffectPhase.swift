//
//  EffectPhase.swift
//  Probing
//
//  Created by Kamil Strzelecki on 01/03/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

internal enum EffectPhase {

    case created
    case enqueued(EffectContinuation)
    case executing
    case probed(ProbeContinuation)
    case finished(any Sendable)
    case cancelled(any Sendable)

    var isSuspended: Bool {
        switch self {
        case .cancelled, .enqueued, .finished, .probed:
            true
        case .created, .executing:
            false
        }
    }

    var isCompleted: Bool {
        switch self {
        case .cancelled, .finished:
            true
        case .created, .enqueued, .executing, .probed:
            false
        }
    }
}

extension EffectPhase {

    var isCreated: Bool {
        switch self {
        case .created:
            true
        default:
            false
        }
    }

    var isEnqueued: Bool {
        switch self {
        case .enqueued:
            true
        default:
            false
        }
    }

    var isExecuting: Bool {
        switch self {
        case .executing:
            true
        default:
            false
        }
    }

    var isProbed: Bool {
        switch self {
        case .probed:
            true
        default:
            false
        }
    }

    var isFinished: Bool {
        switch self {
        case .finished:
            true
        default:
            false
        }
    }

    var isCancelled: Bool {
        switch self {
        case .cancelled:
            true
        default:
            false
        }
    }
}
