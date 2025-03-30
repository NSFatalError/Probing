//
//  ProbingErrors.swift
//  Probing
//
//  Created by Kamil Strzelecki on 11/03/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Algorithms
import Principle

internal enum ProbingErrors {}

// MARK: - Child Effects

extension ProbingErrors {

    struct EffectNotFound: Error, CustomStringConvertible {

        let ancestor: EffectBacktrace
        let expectation: EffectIdentifier

        var description: String {
            """
            Effect with identifier \"\(expectation)\" has not been created in this test run yet.

            It's closest created ancestor is \(ancestor.afterword).

            Recovery suggestions:
            - Verify that the provided identifier is correct.
            - Ensure all necessary dispatches to create the effect have been run before accessing it.
            """
        }
    }

    struct EffectIdentifierAmbiguous: Error, CustomStringConvertible {

        let backtrace: EffectBacktrace
        let preexisting: (location: ProbingLocation, phase: EffectPhase)

        private var violation: String {
            if preexisting.phase.isCompleted {
                "at least one of its children hasn't been completed yet"
            } else {
                "hasn't been completed yet"
            }
        }

        var description: String {
            """
            \(backtrace.foreword), attempted to use an identifier which was already in use.

            Preexisting effect, created at \(preexisting.location), \
            uses the same identifier and \(violation).

            Recovery suggestions:
            - If effects have distinct purposes assign unique identifiers to them.
            - Ensure preexisting effect and its children have completed before a new one is created.
            """
        }
    }
}

// MARK: - Effect Completions

extension ProbingErrors {

    struct FinishedValueNotMatching: Error, CustomStringConvertible {

        let backtrace: EffectBacktrace
        let phase: EffectPhase

        var description: String {
            switch phase {
            case let .finished(value):
                "\(backtrace.foreword) did finish with value of unexpected type \(type(of: value)): \(value)."

            case .cancelled:
                """
                \(backtrace.foreword) was cancelled rather than finished.

                Recovery suggestions:
                - If cancellation is expected use the getCancelledValue method.
                - Ensure test was setup in a way that allows conditional code to finish the effect.
                """

            default:
                """
                \(backtrace.foreword) has not been completed yet.

                Recovery suggestion:
                - Ensure all necessary dispatches to finish the effect have been run before accessing its value.
                """
            }
        }
    }

    struct CancelledValueNotMatching: Error, CustomStringConvertible {

        let backtrace: EffectBacktrace
        let phase: EffectPhase

        var description: String {
            switch phase {
            case let .cancelled(value):
                "\(backtrace.foreword) did finish with value of unexpected type \(type(of: value)): \(value)."

            case .finished:
                """
                \(backtrace.foreword) was finished rather than cancelled.

                Recovery suggestions:
                - If finish is expected use the getValue method.
                - Ensure test was setup in a way that allows conditional code to cancel the effect.
                """

            default:
                """
                \(backtrace.foreword) has not been completed yet.

                Recovery suggestion:
                - Ensure all necessary dispatches to cancel the effect have been run before accessing its value.
                """
            }
        }
    }
}

// MARK: - Effect Dispatches

extension ProbingErrors {

    struct ChildEffectNotCreated: Error, CustomStringConvertible {

        let backtrace: EffectBacktrace
        let expectation: (id: EffectIdentifier, dispatch: EffectDispatch)

        private var descendant: String {
            backtrace.id == .root ? "effect" : "child"
        }

        private var requirement: String {
            switch expectation.dispatch {
            case let .runUntilProbeInstalled(id):
                "reach probe with identifier \"\(id)\""
            case let .runUntilCompleted(includeDescendants):
                "be completed\(includeDescendants ? ", including its descendants" : "")"
            case .runUntilChildCreated, .suspendWhenPossible:
                "[internal framework error]"
            }
        }

        var description: String {
            """
            \(backtrace.foreword), was completed without creating the expected \(descendant) \
            with identifier \"\(expectation.id.suffix(from: backtrace.id))\".

            This child effect was required to \(requirement).

            Recovery suggestions:
            - Verify that the provided identifier is correct.
            - Ensure test was setup in a way that allows conditional code to create the expected child effect.
            """
        }
    }

    struct ProbeNotInstalled: Error, CustomStringConvertible {

        let backtrace: EffectBacktrace
        let expectation: ProbeIdentifier

        var description: String {
            """
            \(backtrace.foreword), was completed without installing the expected probe \
            with identifier \"\(expectation)\".

            Recovery suggestions:
            - Verify that the provided identifier is correct.
            - Ensure test was setup in a way that allows conditional code to install the expected probe.
            """
        }
    }
}

// MARK: - API Misuses

extension ProbingErrors {

    struct ProbeAPIMisuse: Error, CustomStringConvertible {

        let backtrace: ProbeBacktrace
        let preexisting: ProbeBacktrace?

        var description: String {
            apiMisuseDescription(
                subsystem: "probe",
                attempt: "install probe",
                backtraces: [backtrace, preexisting].compacted()
            )
        }
    }

    struct EffectAPIMisuse: Error, CustomStringConvertible {

        let backtrace: EffectBacktrace

        var description: String {
            apiMisuseDescription(
                subsystem: "effect",
                attempt: "create effect",
                backtraces: CollectionOfOne(backtrace)
            )
        }
    }
}

extension ProbingErrors {

    private static func apiMisuseDescription(
        subsystem: String,
        attempt: String,
        backtraces: some Collection<ProbingBacktrace<some ProbingIdentifierProtocol>>
    ) -> String {
        var violation = if backtraces.count == 1 {
            "Following \(subsystem) caused the issue:"
        } else {
            "Either of the following \(subsystem)s caused the issue:"
        }

        violation += backtraces.lazy
            .map { "\n- \"\($0.id)\", created at \($0.location)" }
            .joined()

        return """
        Detected an attempt to \(attempt) from a Task's body \
        while test dispatches were concurrently executing.

        This indicates an API misuse, which compromises the deterministic execution guarantees \
        provided by the framework. As a result, this issue may or may not occur in other test runs. \
        Please refer to the documentation for guidance.

        \(violation)

        Recovery suggestions:
        - Replace all Task instances with #Effect macros to allow the framework to control their execution.
        - Serialize creation of \(subsystem)s by manually controlling the execution flow.
        - If the issue persists, consider removing problematic \(subsystem)s and using an alternative testing approach.
        """
    }
}

// MARK: - Helpers

extension EffectBacktrace {

    fileprivate var foreword: String {
        afterword.capitalizingFirstLetter()
    }

    fileprivate var afterword: String {
        if id == .root {
            "test body created at \(location)"
        } else {
            "effect with identifier \"\(id)\", created at \(location)"
        }
    }
}

extension EffectIdentifier {

    fileprivate func suffix(from parent: Self) -> String {
        let suffix = path.trimmingPrefix(parent.path)
        return ProbingIdentifiers.join(suffix)
    }
}
