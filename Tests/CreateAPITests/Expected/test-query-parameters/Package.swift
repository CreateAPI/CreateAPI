// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "test-query-parameters",
    platforms: [.iOS(.v13), .macCatalyst(.v13), .macOS(.v10_15), .watchOS(.v6), .tvOS(.v13)],
    products: [
        .library(name: "test-query-parameters", targets: ["test-query-parameters"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Get", from: "0.3.1"), 
        .package(url: "https://github.com/CreateAPI/URLQueryEncoder", from: "0.2.0")
    ],
    targets: [
        .target(name: "test-query-parameters", dependencies: [
            .product(name: "Get", package: "Get"), 
            .product(name: "URLQueryEncoder", package: "URLQueryEncoder")
        ], path: "Sources")
    ]
)