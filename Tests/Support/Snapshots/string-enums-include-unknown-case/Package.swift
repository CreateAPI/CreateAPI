// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "string-enums-include-unknown-case",
    platforms: [.iOS(.v13), .macCatalyst(.v13), .macOS(.v10_15), .watchOS(.v6), .tvOS(.v13)],
    products: [
        .library(name: "string-enums-include-unknown-case", targets: ["string-enums-include-unknown-case"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Get", from: "2.1.0"),
        .package(url: "https://github.com/CreateAPI/URLQueryEncoder", from: "0.2.0")
    ],
    targets: [
        .target(name: "string-enums-include-unknown-case", dependencies: [
            .product(name: "Get", package: "Get"),
            .product(name: "URLQueryEncoder", package: "URLQueryEncoder")
        ], path: "Sources")
    ]
)