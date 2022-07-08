// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "strip-parent-name-nested-objects-enabled",
    platforms: [.iOS(.v13), .macCatalyst(.v13), .macOS(.v10_15), .watchOS(.v6), .tvOS(.v13)],
    products: [
        .library(name: "strip-parent-name-nested-objects-enabled", targets: ["strip-parent-name-nested-objects-enabled"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Get", from: "0.3.1")
    ],
    targets: [
        .target(name: "strip-parent-name-nested-objects-enabled", dependencies: [
            .product(name: "Get", package: "Get")
        ], path: "Sources")
    ]
)