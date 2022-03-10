// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "petstore-change-namespace-when-operations-style",
    platforms: [.iOS(.v13), .macCatalyst(.v13), .macOS(.v10_15), .watchOS(.v6), .tvOS(.v13)],
    products: [
        .library(name: "petstore-change-namespace-when-operations-style", targets: ["petstore-change-namespace-when-operations-style"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Get", from: "0.3.1"), 
        .package(url: "https://github.com/kean/HTTPHeaders", from: "0.1.0"), 
        .package(url: "https://github.com/kean/URLQueryEncoder", from: "0.2.0")
    ],
    targets: [
        .target(name: "petstore-change-namespace-when-operations-style", dependencies: [
            .product(name: "Get", package: "Get"), 
            .product(name: "HTTPHeaders", package: "HTTPHeaders"), 
            .product(name: "URLQueryEncoder", package: "URLQueryEncoder")
        ], path: "Sources")
    ]
)
