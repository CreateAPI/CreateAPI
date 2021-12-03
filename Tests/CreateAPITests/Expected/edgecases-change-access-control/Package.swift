// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "edgecases-change-access-control",
    platforms: [.iOS(.v15), .macCatalyst(.v15), .macOS(.v12), .watchOS(.v8), .tvOS(.v15)],
    products: [
        .library(name: "edgecases-change-access-control", targets: ["edgecases-change-access-control"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kean/APIClient", branch: "main"),
    ],
    targets: [
        .target(name: "edgecases-change-access-control", dependencies: [.product(name: "APIClient", package: "APIClient")], path: "Sources")
    ]
)