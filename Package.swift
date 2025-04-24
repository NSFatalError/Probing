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
        ),
        .library(
            name: "DeeplyCopyable",
            targets: ["DeeplyCopyable"]
        ),
        .library(
            name: "EquatableObject",
            targets: ["EquatableObject"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/NSFatalError/Principle",
            from: "1.0.0"
        ),
        .package(
            url: "https://github.com/NSFatalError/PrincipleMacros",
            from: "1.0.0"
        ),
        .package(
            url: "https://github.com/swiftlang/swift-syntax",
            from: "600.0.0-latest"
        ),
        .package(
            url: "https://github.com/apple/swift-algorithms",
            from: "1.2.0"
        )
    ],
    targets: [
        .target(
            name: "ProbeTesting",
            dependencies: [
                "Principle",
                "Probing"
            ]
        ),
        .testTarget(
            name: "ProbeTestingTests",
            dependencies: ["ProbeTesting"]
        )
    ] + macroTargets(
        name: "Probing",
        dependencies: [
            "Principle",
            "DeeplyCopyable",
            "EquatableObject",
            .product(
                name: "Algorithms",
                package: "swift-algorithms"
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
