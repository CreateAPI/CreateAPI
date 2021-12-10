// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "petstore-some-entities-as-classes",
    platforms: [.iOS(.v15), .macCatalyst(.v15), .macOS(.v12), .watchOS(.v8), .tvOS(.v15)],
    products: [
        .library(name: "petstore-some-entities-as-classes", targets: ["petstore-some-entities-as-classes"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kean/APIClient", branch: "main"), 
        .package(url: "https://github.com/kean/HTTPHeaders", branch: "main")
    ],
    targets: [
        .target(name: "petstore-some-entities-as-classes", dependencies: [
            .product(name: "APIClient", package: "APIClient"), 
            .product(name: "HTTPHeaders", package: "HTTPHeaders")
        ], path: "Sources")
    ]
)