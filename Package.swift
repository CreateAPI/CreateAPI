// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CreateAPI",
    platforms: [.macOS(.v10_13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.0.1"),
        .package(url: "https://github.com/kean/OpenAPIKit", branch: "release/3_0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "4.0.0"),
        .package(url: "https://github.com/Cosmo/GrammaticalNumber", from: "0.0.3"),
    ],
    targets: [
        .executableTarget(
            name: "CreateAPI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "OpenAPIKit30", package: "OpenAPIKit"),
                .product(name: "Yams", package: "Yams"),
                .product(name: "GrammaticalNumber", package: "GrammaticalNumber"),
            ]
        ),
        .testTarget(name: "CreateAPITests", dependencies: ["CreateAPI"], resources: [.copy("Expected"), .copy("Specs")])
    ]
)
