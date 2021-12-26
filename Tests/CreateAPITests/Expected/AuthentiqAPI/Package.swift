// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AuthentiqAPI",
    platforms: [.iOS(.v15), .macCatalyst(.v15), .macOS(.v12), .watchOS(.v8), .tvOS(.v15)],
    products: [
        .library(name: "AuthentiqAPI", targets: ["AuthentiqAPI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Get", branch: "main")
    ],
    targets: [
        .target(name: "AuthentiqAPI", dependencies: [
            .product(name: "Get", package: "Get")
        ], path: "Sources")
    ]
)