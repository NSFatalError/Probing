// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "Probing",
    platforms: [
        .macOS(.v15),
        .macCatalyst(.v18),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "Probing",
            targets: ["Probing"]
        ),
        .library(
            name: "ProbeTesting",
            targets: ["ProbeTesting"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/NSFatalError/Principle",
            from: "2.0.0"
        ),
        .package(
            url: "https://github.com/swiftlang/swift-syntax",
            "602.0.0" ..< "603.0.0"
        )
    ],
    targets: [
        .target(
            name: "Probing",
            dependencies: [
                "ProbingMacros",
                .product(
                    name: "PrincipleConcurrency",
                    package: "Principle"
                ),
                .product(
                    name: "PrincipleCollections",
                    package: "Principle"
                )
            ]
        ),
        .testTarget(
            name: "ProbingTests",
            dependencies: ["Probing"]
        ),

        .macro(
            name: "ProbingMacros",
            dependencies: [
                .product(
                    name: "SwiftSyntaxMacros",
                    package: "swift-syntax"
                ),
                .product(
                    name: "SwiftCompilerPlugin",
                    package: "swift-syntax"
                )
            ],
            path: "Macros",
            sources: [
                "ProbingMacros/",
                "Dependencies/PrincipleMacros/Sources/PrincipleMacros/"
            ]
        ),
        .testTarget(
            name: "ProbingMacrosTests",
            dependencies: [
                "ProbingMacros",
                .product(
                    name: "SwiftSyntaxMacrosTestSupport",
                    package: "swift-syntax"
                )
            ]
        ),

        .target(
            name: "ProbeTesting",
            dependencies: ["Probing"],
            swiftSettings: [
                .enableExperimentalFeature("LifetimeDependence")
            ]
        ),
        .testTarget(
            name: "ProbeTestingTests",
            dependencies: [
                "ProbeTesting",
                .product(
                    name: "PrincipleConcurrency",
                    package: "Principle"
                )
            ]
        ),

        .target(
            name: "DeeplyCopyable",
            dependencies: ["ProbingMacros"]
        ),
        .testTarget(
            name: "DeeplyCopyableTests",
            dependencies: [
                "DeeplyCopyable",
                "EquatableObject"
            ]
        ),

        .target(
            name: "EquatableObject",
            dependencies: ["ProbingMacros"]
        ),
        .testTarget(
            name: "EquatableObjectTests",
            dependencies: ["EquatableObject"]
        )
    ]
)

for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("MemberImportVisibility")
    ]
}
