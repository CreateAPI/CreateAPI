// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OneAPI",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.0.1"),
        .package(url: "https://github.com/mattpolzin/OpenAPIKit", branch: "release/3_0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "4.0.0")
    ],
    targets: [
        .executableTarget(
            name: "OneAPI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "OpenAPIKit30", package: "OpenAPIKit"),
                .product(name: "Yams", package: "Yams")
            ]),
        .testTarget(
            name: "OneAPITests",
            dependencies: ["OneAPI"],
            resources: [.process("Resources")]
        )
    ]
)
