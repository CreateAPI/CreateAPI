// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "edgecases-tabs",
    platforms: [.iOS(.v15), .macCatalyst(.v15), .macOS(.v12), .watchOS(.v8), .tvOS(.v15)],
    products: [
        .library(name: "edgecases-tabs", targets: ["edgecases-tabs"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kean/APIClient", branch: "main")
    ],
    targets: [
        .target(name: "edgecases-tabs", dependencies: [
            .product(name: "APIClient", package: "APIClient")
        ], path: "Sources")
    ]
)