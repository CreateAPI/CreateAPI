// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "edgecases-int32-int64",
    platforms: [.iOS(.v13), .macCatalyst(.v13), .macOS(.v10_15), .watchOS(.v6), .tvOS(.v13)],
    products: [
        .library(name: "edgecases-int32-int64", targets: ["edgecases-int32-int64"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Get", branch: "main"), 
        .package(url: "https://github.com/kean/HTTPHeaders", branch: "main"), 
        .package(url: "https://github.com/kean/NaiveDate", branch: "master"), 
        .package(url: "https://github.com/kean/URLQueryEncoder", branch: "main")
    ],
    targets: [
        .target(name: "edgecases-int32-int64", dependencies: [
            .product(name: "Get", package: "Get"), 
            .product(name: "HTTPHeaders", package: "HTTPHeaders"), 
            .product(name: "NaiveDate", package: "NaiveDate"), 
            .product(name: "URLQueryEncoder", package: "URLQueryEncoder")
        ], path: "Sources")
    ]
)