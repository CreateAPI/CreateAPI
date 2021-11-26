// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NanoGen",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.0.1"),
        .package(url: "https://github.com/yonaskolb/SwagGen", from: "4.0.0")
    ],
    targets: [
        .executableTarget(
            name: "NanoGen",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Swagger", package: "SwagGen")
            ]),
        .testTarget(
            name: "NanoGenTests",
            dependencies: ["NanoGen"],
            resources: [.process("Resources")]
        )
    ]
)
