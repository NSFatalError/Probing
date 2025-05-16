// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

func macroTargets(
    name: String,
    dependencies: [Target.Dependency] = [],
    testDependencies: [Target.Dependency] = []
) -> [Target] {
    [
        .target(
            name: name,
            dependencies: dependencies + [
                .target(name: "\(name)Macros")
            ]
        ),
        .macro(
            name: "\(name)Macros",
            dependencies: [
                .product(
                    name: "PrincipleMacros",
                    package: "PrincipleMacros"
                ),
                .product(
                    name: "SwiftCompilerPlugin",
                    package: "swift-syntax"
                )
            ]
        ),
        .testTarget(
            name: "\(name)MacrosTests",
            dependencies: [
                .target(
                    name: "\(name)Macros"
                ),
                .product(
                    name: "SwiftSyntaxMacrosTestSupport",
                    package: "swift-syntax"
                )
            ]
        ),
        .testTarget(
            name: "\(name)Tests",
            dependencies: testDependencies + [
                .target(name: name)
            ]
        )
    ]
}

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
            from: "1.0.3"
        ),
        .package(
            url: "https://github.com/NSFatalError/PrincipleMacros",
            from: "1.0.4"
        ),
        .package(
            url: "https://github.com/swiftlang/swift-syntax",
            "600.0.0" ..< "602.0.0"
        )
    ],
    targets: [
        .target(
            name: "ProbeTesting",
            dependencies: [
                "Probing"
            ],
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
        )
    ] + macroTargets(
        name: "Probing",
        dependencies: [
            .product(
                name: "PrincipleConcurrency",
                package: "Principle"
            ),
            .product(
                name: "PrincipleCollections",
                package: "Principle"
            )
        ]
    ) + macroTargets(
        name: "DeeplyCopyable",
        testDependencies: [
            "EquatableObject"
        ]
    ) + macroTargets(
        name: "EquatableObject"
    )
)

for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("ExistentialAny")
    ]
}
