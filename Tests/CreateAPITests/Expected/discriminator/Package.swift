// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "discriminator",
    platforms: [.iOS(.v13), .macCatalyst(.v13), .macOS(.v10_15), .watchOS(.v6), .tvOS(.v13)],
    products: [
        .library(name: "discriminator", targets: ["discriminator"]),
    ],
    dependencies: [
        .package(url: "https://github.com/CreateAPI/Get", from: "0.3.1")
    ],
    targets: [
        .target(name: "discriminator", dependencies: [
            .product(name: "Get", package: "Get")
        ], path: "Sources")
    ]
)