// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "petstore-custom-imports",
    platforms: [.iOS(.v15), .macCatalyst(.v15), .macOS(.v12), .watchOS(.v8), .tvOS(.v15)],
    products: [
        .library(name: "petstore-custom-imports", targets: ["petstore-custom-imports"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Get", branch: "main"), 
        .package(url: "https://github.com/kean/HTTPHeaders", branch: "main")
    ],
    targets: [
        .target(name: "petstore-custom-imports", dependencies: [
            .product(name: "Get", package: "Get"), 
            .product(name: "HTTPHeaders", package: "HTTPHeaders")
        ], path: "Sources")
    ]
)